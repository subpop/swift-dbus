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

struct CallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "call",
        abstract: "Call a method"
    )

    @OptionGroup()
    var globalOptions: DBusUtil.GlobalOptions

    @ArgumentParser.Argument(help: "Service name of the method")
    var serviceName: String

    @ArgumentParser.Argument(help: "Object path of the method")
    var objectPath: String

    @ArgumentParser.Argument(help: "Interface of the method")
    var interface: String

    @ArgumentParser.Argument(help: "Method name")
    var method: String

    @ArgumentParser.Argument(help: "Signature of the method")
    var signature: String

    @ArgumentParser.Argument(parsing: .remaining, help: "Arguments to the method")
    var arguments: [String]

    func run() async throws {
        let connection = Connection()
        try await connection.connect(to: BusType(from: globalOptions.bus))

        // Get a proxy object instance.
        let proxyObject = connection.proxyObject(
            serviceName: serviceName,
            objectPath: try ObjectPath(objectPath),
            interfaceName: interface
        )

        // Serialize the arguments.
        guard let callSignature = Signature(rawValue: signature) else {
            throw CallCommandError.invalidSignature(signature)
        }

        let body: [UInt8]
        if callSignature.rawValue.isEmpty {
            // Empty signature means no arguments expected - use empty body
            body = []
        } else {
            // For non-empty signatures, we need to validate argument count
            let signatureElements = Array(callSignature)

            // Remove trailing empty arguments that are likely placeholders
            let trimmedArguments = arguments.reversed().drop(while: { $0.isEmpty }).reversed()
            let actualArguments = Array(trimmedArguments)

            if actualArguments.isEmpty && !signatureElements.isEmpty {
                // No arguments provided but signature expects some
                throw CallCommandError.argumentCountMismatch(
                    expected: signatureElements.count,
                    actual: 0
                )
            }

            let encoder = DBusEncoder()
            body = try encoder.encode(actualArguments, signature: callSignature)
        }

        // Call the method.
        guard
            let (resultSignature, resultBody) = try await proxyObject.call(
                method, interface: interface, signature: callSignature,
                body: body)
        else {
            throw CallCommandError.methodCallFailed
        }

        // Decode each result element as a variant for dynamic handling
        if resultSignature.rawValue.isEmpty {
            // No results to decode for empty signature
            return
        }

        // For most D-Bus methods, there's typically one return value
        // Handle the most common cases directly
        let signatureString = resultSignature.rawValue
        let decoder = DBusDecoder()

        switch signatureString {
        case "s":
            let result = try decoder.decode(
                String.self, from: resultBody, signature: resultSignature)
            print(result)
        case "i":
            let result = try decoder.decode(
                Int32.self, from: resultBody, signature: resultSignature)
            print(result)
        case "u":
            let result = try decoder.decode(
                UInt32.self, from: resultBody, signature: resultSignature)
            print(result)
        case "b":
            let result = try decoder.decode(Bool.self, from: resultBody, signature: resultSignature)
            print(result)
        case "d":
            let result = try decoder.decode(
                Double.self, from: resultBody, signature: resultSignature)
            print(result)
        case "as":
            let result = try decoder.decode(
                [String].self, from: resultBody, signature: resultSignature)
            print(result)
        default:
            // For complex signatures, print the raw signature for now
            print("Complex result with signature: \(signatureString)")
            print(
                "Raw bytes: \(resultBody.map { String(format: "%02x", $0) }.joined(separator: " "))"
            )
        }
    }
}

enum CallCommandError: Error {
    case invalidSignature(String)
    case methodCallFailed
    case argumentCountMismatch(expected: Int, actual: Int)
}
