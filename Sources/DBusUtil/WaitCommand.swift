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

import ArgumentParser
import DBus
import Foundation

struct WaitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wait",
        abstract: "Wait for a D-Bus signal"
    )

    @OptionGroup()
    var globalOptions: DBusUtil.GlobalOptions

    @ArgumentParser.Argument(help: "Object path to listen for signals from")
    var objectPath: String

    @ArgumentParser.Argument(help: "Interface name of the signal")
    var interface: String

    @ArgumentParser.Argument(help: "Signal name")
    var signal: String

    @Option(name: .shortAndLong, help: "Timeout in seconds (default: wait indefinitely)")
    var timeout: Int?

    func run() async throws {
        let connection = Connection()
        try await connection.connect(to: BusType(from: globalOptions.bus))

        // Validate object path
        let path = try ObjectPath(objectPath)

        // Create a proxy object for signal listening
        let proxyObject = connection.proxyObject(
            serviceName: "*",  // Listen to signals from any service
            objectPath: path,
            interfaceName: interface
        )

        print(
            "Waiting for signal '\(signal)' on interface '\(interface)' at path '\(objectPath)'...")

        do {
            // Convert timeout from seconds to TimeInterval if provided
            let timeoutInterval: TimeInterval? = timeout.map { TimeInterval($0) }

            if let timeoutSeconds = timeout {
                print("Waiting for up to \(timeoutSeconds) seconds...")
            } else {
                print("Waiting indefinitely (use Ctrl+C to stop)...")
            }

            // Wait for the signal using ProxyObject's waitForSignal method
            let receivedMessage = try await proxyObject.waitForSignal(
                signal, timeout: timeoutInterval)

            // Signal received - print the information
            printSignalInfo(receivedMessage)

        } catch DBusProxyError.signalTimeout {
            if let timeoutSeconds = timeout {
                print("Timeout waiting for signal after \(timeoutSeconds) seconds")
            }
            throw WaitCommandError.timeout
        } catch {
            print("Failed to wait for signal: \(error)")
            throw WaitCommandError.signalHandlerFailed
        }
    }

    private func printSignalInfo(_ message: Message) {
        print("Signal received!")
        print("  Path: \(message.path?.rawValue ?? "unknown")")
        print("  Interface: \(message.interface ?? "unknown")")
        print("  Signal: \(message.member ?? "unknown")")
        print("  Sender: \(message.sender ?? "unknown")")

        if !message.body.isEmpty {
            if let signature = message.bodySignature {
                print("  Signature: \(signature.rawValue)")
            }
            print("  Body: \(message.body.count) bytes")

            // Try to decode simple types for display
            if let signature = message.bodySignature {
                printDecodedArguments(message.body, signature: signature)
            }
        } else {
            print("  No arguments")
        }
    }

    private func printDecodedArguments(_ body: [UInt8], signature: Signature) {
        // Simple decoding for common types - this could be expanded
        let elements = Array(signature)

        if elements.count == 1 {
            do {
                var deserializer = Deserializer(
                    data: body, signature: signature, endianness: .littleEndian)

                switch elements[0] {
                case .string:
                    let value: String = try deserializer.unserialize()
                    print("  Arguments: \"\(value)\"")
                case .int32:
                    let value: Int32 = try deserializer.unserialize()
                    print("  Arguments: \(value)")
                case .uint32:
                    let value: UInt32 = try deserializer.unserialize()
                    print("  Arguments: \(value)")
                case .bool:
                    let value: Bool = try deserializer.unserialize()
                    print("  Arguments: \(value)")
                case .double:
                    let value: Double = try deserializer.unserialize()
                    print("  Arguments: \(value)")
                default:
                    print("  Arguments: [complex type - raw bytes shown above]")
                }
            } catch {
                print("  Arguments: [decode error - raw bytes shown above]")
            }
        } else if elements.isEmpty {
            print("  Arguments: none")
        } else {
            print("  Arguments: [multiple arguments - raw bytes shown above]")
        }
    }
}

enum WaitCommandError: Error {
    case timeout
    case signalHandlerFailed
}

extension WaitCommandError: CustomStringConvertible {
    var description: String {
        switch self {
        case .timeout:
            return "Timeout waiting for signal"
        case .signalHandlerFailed:
            return "Failed to set up signal handler"
        }
    }
}
