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

struct SetPropertyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-property",
        abstract: "Set a property on a remote object"
    )

    @OptionGroup()
    var globalOptions: DBusUtil.GlobalOptions

    @ArgumentParser.Argument(help: "Service name of the object")
    var serviceName: String

    @ArgumentParser.Argument(help: "Object path of the object")
    var objectPath: String

    @ArgumentParser.Argument(help: "Interface of the object")
    var interface: String

    @ArgumentParser.Argument(help: "Property name")
    var propertyName: String

    @ArgumentParser.Argument(
        help: "Type signature of the property value (e.g., 's' for string, 'i' for int32)")
    var signature: String

    @ArgumentParser.Argument(help: "Property value")
    var value: String

    func run() async throws {
        let connection = Connection()
        try await connection.connect(to: BusType(from: globalOptions.bus))

        let proxyObject = connection.proxyObject(
            serviceName: serviceName,
            objectPath: try ObjectPath(objectPath),
            interfaceName: interface
        )

        // Parse the signature
        guard let valueSignature = Signature(rawValue: signature) else {
            throw SetPropertyCommandError.invalidSignature(signature)
        }

        // Create a variant from the value string based on the signature
        let variant = try createVariant(from: value, signature: valueSignature)

        // Set the property
        try await proxyObject.setProperty(propertyName, value: variant)

        print("Property '\(propertyName)' set successfully")
    }

    private func createVariant(from valueString: String, signature: Signature) throws -> Variant {
        let signatureString = signature.rawValue

        switch signatureString {
        case "s":
            return Variant(value: .string(valueString), signature: signature)
        case "i":
            guard let intValue = Int32(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "int32"
                )
            }
            return Variant(value: .int32(intValue), signature: signature)
        case "u":
            guard let uintValue = UInt32(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "uint32"
                )
            }
            return Variant(value: .uint32(uintValue), signature: signature)
        case "b":
            let boolValue: Bool
            switch valueString.lowercased() {
            case "true", "1", "yes":
                boolValue = true
            case "false", "0", "no":
                boolValue = false
            default:
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "boolean"
                )
            }
            return Variant(value: .bool(boolValue), signature: signature)
        case "d":
            guard let doubleValue = Double(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "double"
                )
            }
            return Variant(value: .double(doubleValue), signature: signature)
        case "x":
            guard let int64Value = Int64(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "int64"
                )
            }
            return Variant(value: .int64(int64Value), signature: signature)
        case "t":
            guard let uint64Value = UInt64(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "uint64"
                )
            }
            return Variant(value: .uint64(uint64Value), signature: signature)
        case "n":
            guard let int16Value = Int16(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "int16"
                )
            }
            return Variant(value: .int16(int16Value), signature: signature)
        case "q":
            guard let uint16Value = UInt16(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "uint16"
                )
            }
            return Variant(value: .uint16(uint16Value), signature: signature)
        case "y":
            guard let uint8Value = UInt8(valueString) else {
                throw SetPropertyCommandError.invalidValue(
                    valueString, expectedType: "uint8/byte"
                )
            }
            return Variant(value: .byte(uint8Value), signature: signature)
        default:
            throw SetPropertyCommandError.unsupportedSignature(signatureString)
        }
    }
}

enum SetPropertyCommandError: Error {
    case invalidSignature(String)
    case invalidValue(String, expectedType: String)
    case unsupportedSignature(String)
}
