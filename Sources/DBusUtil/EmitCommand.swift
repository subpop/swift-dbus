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

struct EmitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "emit",
        abstract: "Emit a D-Bus signal"
    )

    @OptionGroup()
    var globalOptions: DBusUtil.GlobalOptions

    @ArgumentParser.Argument(help: "Object path from which to emit the signal")
    var objectPath: String

    @ArgumentParser.Argument(help: "Interface name of the signal")
    var interface: String

    @ArgumentParser.Argument(help: "Signal name")
    var signal: String

    @ArgumentParser.Argument(help: "Signature of the signal arguments")
    var signature: String

    @ArgumentParser.Argument(parsing: .remaining, help: "Arguments for the signal")
    var arguments: [String]

    func run() async throws {
        let connection = Connection()
        try await connection.connect(to: BusType(from: globalOptions.bus))

        // Validate and create signature
        guard let signalSignature = Signature(rawValue: signature) else {
            throw EmitCommandError.invalidSignature(signature)
        }

        // Serialize the arguments
        let body: [UInt8]
        if signalSignature.rawValue.isEmpty {
            // Empty signature means no arguments expected - use empty body
            body = []
        } else {
            // Remove trailing empty arguments that are likely placeholders
            let trimmedArguments = arguments.reversed().drop(while: { $0.isEmpty }).reversed()
            let actualArguments = Array(trimmedArguments)

            // For now, use a simplified approach that handles common signature patterns
            body = try encodeArgumentsForSignature(actualArguments, signature: signalSignature)
        }

        // Create and send the signal message directly
        let signalMessage = try Message.signal(
            path: try ObjectPath(objectPath),
            interface: interface,
            member: signal,
            serial: await connection.nextSerial(),
            body: body,
            bodySignature: signalSignature.rawValue.isEmpty ? nil : signalSignature
        )

        _ = try await connection.send(message: signalMessage)

        print("Signal '\(signal)' broadcast on interface '\(interface)' at path '\(objectPath)'")
    }

    /// Encode arguments for a given signature - handles both single and multi-argument patterns
    private func encodeArgumentsForSignature(_ args: [String], signature: Signature) throws
        -> [UInt8]
    {
        let signatureElements = Array(signature)

        guard args.count == signatureElements.count else {
            throw EmitCommandError.argumentCountMismatch(
                expected: signatureElements.count,
                actual: args.count
            )
        }

        // Use the lower-level Serializer directly to handle multiple arguments
        var serializer = Serializer(signature: signature, alignmentContext: .message)

        // Serialize each argument individually according to its signature element
        for (index, element) in signatureElements.enumerated() {
            let stringValue = args[index]
            let convertedValue = try convertStringToType(stringValue, element: element)
            try serializeArgument(convertedValue, element: element, to: &serializer)
        }

        guard let data = serializer.data else {
            throw EmitCommandError.serializationFailed
        }

        return data
    }

    /// Convert a string argument to the appropriate Swift type based on the signature element
    private func convertStringToType(_ stringValue: String, element: SignatureElement) throws -> Any
    {
        switch element {
        case .bool:
            let lowercased = stringValue.lowercased()
            if lowercased == "true" || lowercased == "1" || lowercased == "yes" {
                return true
            } else if lowercased == "false" || lowercased == "0" || lowercased == "no" {
                return false
            } else {
                throw EmitCommandError.invalidArgument(stringValue, for: "boolean")
            }
        case .byte:
            guard let value = UInt8(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "byte")
            }
            return value
        case .int16:
            guard let value = Int16(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "int16")
            }
            return value
        case .uint16:
            guard let value = UInt16(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "uint16")
            }
            return value
        case .int32:
            guard let value = Int32(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "int32")
            }
            return value
        case .uint32:
            guard let value = UInt32(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "uint32")
            }
            return value
        case .int64:
            guard let value = Int64(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "int64")
            }
            return value
        case .uint64:
            guard let value = UInt64(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "uint64")
            }
            return value
        case .double:
            guard let value = Double(stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "double")
            }
            return value
        case .string:
            return stringValue
        case .objectPath:
            return try ObjectPath(stringValue)
        case .signature:
            guard let sig = Signature(rawValue: stringValue) else {
                throw EmitCommandError.invalidArgument(stringValue, for: "signature")
            }
            return sig
        case .array(_), .dictionary(_, _), .struct(_), .variant, .unixFD:
            throw EmitCommandError.unsupportedSignature("Complex type: \(element)")
        }
    }

    /// Serialize a converted argument using the serializer
    private func serializeArgument(
        _ value: Any, element: SignatureElement, to serializer: inout Serializer
    ) throws {
        switch element {
        case .bool:
            try serializer.serialize(value as! Bool)
        case .byte:
            try serializer.serialize(value as! UInt8)
        case .int16:
            try serializer.serialize(value as! Int16)
        case .uint16:
            try serializer.serialize(value as! UInt16)
        case .int32:
            try serializer.serialize(value as! Int32)
        case .uint32:
            try serializer.serialize(value as! UInt32)
        case .int64:
            try serializer.serialize(value as! Int64)
        case .uint64:
            try serializer.serialize(value as! UInt64)
        case .double:
            try serializer.serialize(value as! Double)
        case .string:
            try serializer.serialize(value as! String)
        case .objectPath:
            try serializer.serialize(value as! ObjectPath)
        case .signature:
            try serializer.serialize(value as! Signature)
        default:
            throw EmitCommandError.unsupportedSignature("Cannot serialize: \(element)")
        }
    }
}

enum EmitCommandError: Error {
    case invalidSignature(String)
    case argumentCountMismatch(expected: Int, actual: Int)
    case invalidArgument(String, for: String)
    case unsupportedSignature(String)
    case serializationFailed
}
