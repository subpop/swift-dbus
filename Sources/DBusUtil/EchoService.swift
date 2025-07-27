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
import Logging

class Echo: Exportable, @unchecked Sendable {
    let logger = Logger(label: "Echo")

    func getProperty(interface: String, name: String) async throws -> (Signature, [UInt8]) {
        return (Signature(""), [])
    }

    func setProperty(interface: String, name: String, variant: Variant) async throws {
        return
    }

    var interfaces: [String: DBus.Interface] = [
        "org.swiftdbus.Echo": DBus.Interface(
            name: "org.swiftdbus.Echo",
            methods: [
                "Echo": DBus.Method(
                    name: "Echo",
                    arguments: [
                        DBus.Argument(
                            name: "input", signature: Signature("s"), direction: .in),
                        DBus.Argument(
                            name: "output", signature: Signature("s"), direction: .out),
                    ]
                )
            ],
            properties: [:],
            signals: [:]
        )
    ]

    private func echo(message: String) async throws -> String {
        return message
    }

    func call(interface: String, method: String, signature: Signature, arguments: [UInt8])
        async throws -> (Signature, [UInt8])
    {
        switch interface {
        case "org.swiftdbus.Echo":
            switch method {
            case "Echo":
                let decoder = DBusDecoder()
                let message = try decoder.decode(String.self, from: arguments, signature: signature)
                logger.info("echoing message", metadata: ["message": .string(message)])
                let result = try await echo(message: message)
                let encoder = DBusEncoder()
                return (Signature("s"), try encoder.encode(result))
            default:
                throw ExportableError.invalidMethod(method)
            }
        default:
            throw ExportableError.invalidInterface(interface)
        }
    }
}

struct EchoService: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "echo-service",
        abstract: "Export a simple 'echo' service"
    )

    @OptionGroup()
    var globalOptions: DBusUtil.GlobalOptions

    func run() async throws {
        let logger = Logger(label: "EchoService")

        let connection = Connection()
        try await connection.connect(to: BusType(from: globalOptions.bus))
        logger.info("connected")

        let echo = Echo()
        try await connection.export(echo, at: ObjectPath("/org/swiftdbus/Echo"))
        logger.info("exported echo")

        guard
            let reply = try await connection.requestName(
                name: "org.swiftdbus.Echo", flags: .replaceExisting
            ), reply == .primaryOwner
        else {
            logger.error("request name failed")
            return
        }
        logger.info("requested name", metadata: ["name": "org.swiftdbus.Echo"])

        // Wait for the user to interrupt the program with Ctrl+C
        logger.info("waiting for Ctrl+C to exit")
        try await Task.sleep(for: Duration.seconds(3600 * 24 * 365))  // 1 year
    }
}
