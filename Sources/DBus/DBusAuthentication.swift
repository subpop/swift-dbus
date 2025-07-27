//
// Copyright 2025 Link Dupont
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import NIO

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

/// Protocol for D-Bus authentication mechanisms
protocol DBusAuthenticator: Sendable {
    /// The name of the authentication mechanism (e.g., "EXTERNAL", "ANONYMOUS")
    var mechanismName: String { get }

    /// Perform the authentication handshake
    /// - Parameters:
    ///   - channel: The NIO channel to communicate over
    ///   - dataHandler: Handler for sending and receiving auth data
    /// - Throws: DBusConnectionError if authentication fails
    func authenticate(channel: Channel, dataHandler: DBusAuthDataHandler) async throws
}

/// Data Handler for authentication data exchange.
///
/// This handler is used to build an authentication flow. Data is set to the
/// server using the `sendAuthBytes` method. The response is received using the
/// `receiveAuthResponse` method. See `ExternalAuthenticator` for an example of
/// usage.
actor DBusAuthDataHandler {
    private var incomingBuffer: ByteBuffer

    init() {
        self.incomingBuffer = ByteBuffer()
    }

    /// Send authentication bytes over the channel
    /// - Parameters:
    ///   - data: The bytes to send
    ///   - channel: The channel to send over
    func sendAuthBytes(_ data: [UInt8], on channel: Channel) async throws {
        let buffer = channel.allocator.buffer(bytes: data)

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            channel.writeAndFlush(buffer).whenComplete { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(
                        throwing: ConnectionError.socketError(error.localizedDescription))
                }
            }
        }
    }

    /// Receive an authentication response
    func receiveAuthResponse() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                var attempts = 0
                while attempts < 100 {  // 10 second timeout
                    if let response = extractAuthResponse() {
                        continuation.resume(returning: response)
                        return
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
                    attempts += 1
                }
                continuation.resume(throwing: ConnectionError.timeout)
            }
        }
    }

    private func extractAuthResponse() -> String? {
        guard let string = incomingBuffer.readString(length: incomingBuffer.readableBytes),
            string.contains("\r\n")
        else {
            return nil
        }

        let lines = string.components(separatedBy: "\r\n")
        if !lines.isEmpty && !lines[0].isEmpty {
            return lines[0]
        }

        return nil
    }

    func updateBuffer(_ buffer: ByteBuffer) {
        var mutableBuffer = buffer
        incomingBuffer.writeBuffer(&mutableBuffer)
    }
}

// MARK: - EXTERNAL Authentication

/// SASL EXTERNAL authentication implementation for Unix domain sockets
///
/// This mechanism is used when the transport itself provides authentication credentials,
/// such as Unix domain sockets which provide user ID information.
struct ExternalAuthenticator: DBusAuthenticator {
    public let mechanismName = "EXTERNAL"

    init() {}

    func authenticate(channel: Channel, dataHandler: DBusAuthDataHandler) async throws {
        // Step 1: Send a single NUL byte as required in the specification
        try await dataHandler.sendAuthBytes([0x00], on: channel)

        // Step 2: Send AUTH EXTERNAL and wait for a response
        try await dataHandler.sendAuthBytes(Array("AUTH EXTERNAL\r\n".utf8), on: channel)
        let authResponse = try await dataHandler.receiveAuthResponse()

        if !authResponse.hasPrefix("DATA") {
            throw ConnectionError.authenticationFailed("EXTERNAL auth failed: \(authResponse)")
        }

        // Step 3: Send DATA with UID encoded as ASCII hex and wait for a response
        let uid = getuid()
        let uidString = String(uid)  // UID as decimal string (e.g., "1000")

        // Encode each ASCII character as hexadecimal
        // e.g., "1000" -> "31303030" (31='1', 30='0', 30='0', 30='0')
        let uidHex = uidString.utf8.map { String(format: "%02X", $0) }.joined()

        try await dataHandler.sendAuthBytes(Array("DATA \(uidHex)\r\n".utf8), on: channel)
        let response = try await dataHandler.receiveAuthResponse()

        if !response.hasPrefix("OK ") {
            throw ConnectionError.authenticationFailed("EXTERNAL auth failed: \(response)")
        }

        // Step 4: Send BEGIN
        try await dataHandler.sendAuthBytes(Array("BEGIN\r\n".utf8), on: channel)
    }
}

// MARK: - ANONYMOUS Authentication

/// SASL ANONYMOUS authentication implementation
///
/// This mechanism allows connections without providing authentication credentials.
/// It's primarily used for testing or in environments where access control is not required.
struct AnonymousAuthenticator: DBusAuthenticator {
    let mechanismName = "ANONYMOUS"

    init() {}

    func authenticate(channel: Channel, dataHandler: DBusAuthDataHandler) async throws {
        // Step 1: Send a single NUL byte as required in the specification
        try await dataHandler.sendAuthBytes([0x00], on: channel)

        // Step 2: Send AUTH ANONYMOUS and wait for a response
        try await dataHandler.sendAuthBytes(Array("AUTH ANONYMOUS\r\n".utf8), on: channel)
        let authResponse = try await dataHandler.receiveAuthResponse()

        if authResponse.hasPrefix("DATA") {
            // Some servers request additional data for anonymous auth
            // Send empty data response
            try await dataHandler.sendAuthBytes(Array("DATA\r\n".utf8), on: channel)
            let response = try await dataHandler.receiveAuthResponse()

            if !response.hasPrefix("OK ") {
                throw ConnectionError.authenticationFailed("ANONYMOUS auth failed: \(response)")
            }
        } else if !authResponse.hasPrefix("OK ") {
            throw ConnectionError.authenticationFailed("ANONYMOUS auth failed: \(authResponse)")
        }

        // Step 3: Send BEGIN
        try await dataHandler.sendAuthBytes(Array("BEGIN\r\n".utf8), on: channel)
    }
}

// MARK: - Authentication Types

/// Available authentication mechanisms
public enum DBusAuthenticationType: Sendable {
    case external
    case anonymous

    /// Create the appropriate authenticator for this type
    func createAuthenticator() -> DBusAuthenticator {
        switch self {
        case .external:
            return ExternalAuthenticator()
        case .anonymous:
            return AnonymousAuthenticator()
        }
    }
}

// MARK: - Authentication Manager

/// Manages authentication for D-Bus connections
struct DBusAuthenticationManager: Sendable {
    private let authenticationType: DBusAuthenticationType
    private let dataHandler: DBusAuthDataHandler

    init(authenticationType: DBusAuthenticationType = .external, dataHandler: DBusAuthDataHandler) {
        self.authenticationType = authenticationType
        self.dataHandler = dataHandler
    }

    /// Perform authentication using the configured mechanism
    /// - Parameters:
    ///   - channel: The NIO channel to authenticate over
    /// - Returns: The data handler used for authentication (for buffer updates)
    /// - Throws: DBusConnectionError if authentication fails
    func performAuthentication(on channel: Channel) async throws {
        let authenticator = authenticationType.createAuthenticator()

        try await authenticator.authenticate(channel: channel, dataHandler: self.dataHandler)
    }

    func updateBuffer(_ buffer: ByteBuffer) async {
        await dataHandler.updateBuffer(buffer)
    }
}
