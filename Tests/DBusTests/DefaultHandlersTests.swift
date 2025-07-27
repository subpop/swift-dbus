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

import Testing

@testable import DBus

@Suite("Default D-Bus Interface Handlers Tests") struct DefaultHandlersTests {

    // MARK: - Test Objects

    /// Minimal test object implementing Exportable
    final class BasicTestObject: Exportable, @unchecked Sendable {
        var interfaces: [String: Interface] = [:]

        func call(interface: String, method: String, signature: Signature, arguments: [UInt8])
            async throws -> (Signature, [UInt8])
        {
            // Only handle custom interfaces - standard interfaces are handled by ExportableObject
            throw ExportableError.invalidInterface(interface)
        }

        func getProperty(interface: String, name: String) async throws -> (Signature, [UInt8]) {
            let encoder = DBusEncoder()
            let data = try encoder.encode("test_value", signature: "s")
            return (Signature("s"), data)
        }

        func setProperty(interface: String, name: String, variant: Variant) async throws {
            // No-op for testing
        }
    }

    /// Enhanced test object with custom interface
    final class EnhancedTestObject: Exportable, @unchecked Sendable {
        var interfaces: [String: Interface]
        private var properties: [String: [String: (Signature, [UInt8])]] = [:]

        init() {
            // Create a test interface with methods and properties
            let testInterface = Interface(
                name: "com.example.Test",
                methods: [
                    "Echo": Method(
                        name: "Echo",
                        arguments: [
                            Argument(name: "input", signature: Signature("s"), direction: .in),
                            Argument(name: "output", signature: Signature("s"), direction: .out),
                        ]
                    )
                ],
                properties: [
                    "TestProperty": Property(
                        name: "TestProperty",
                        signature: Signature("s"),
                        access: .readwrite
                    ),
                    "ReadOnlyProperty": Property(
                        name: "ReadOnlyProperty",
                        signature: Signature("i"),
                        access: .read
                    ),
                ]
            )

            self.interfaces = ["com.example.Test": testInterface]

            // Initialize test properties
            let encoder = DBusEncoder()
            self.properties["com.example.Test"] = [
                "TestProperty": (
                    Signature("s"), try! encoder.encode("initial_value", signature: "s")
                ),
                "ReadOnlyProperty": (
                    Signature("i"), try! encoder.encode(Int32(42), signature: "i")
                ),
            ]
        }

        func call(interface: String, method: String, signature: Signature, arguments: [UInt8])
            async throws -> (Signature, [UInt8])
        {
            // Handle custom interface methods
            if interface == "com.example.Test" && method == "Echo" {
                var deserializer = Deserializer(
                    data: arguments, signature: signature, endianness: .littleEndian)
                let input: String = try deserializer.unserialize()
                let output = "Echo: \(input)"

                let encoder = DBusEncoder()
                let outputData = try encoder.encode(output, signature: "s")
                return (Signature("s"), outputData)
            }

            // Standard interfaces are handled by ExportableObject, not here
            throw ExportableError.invalidInterface(interface)
        }

        func getProperty(interface: String, name: String) async throws -> (Signature, [UInt8]) {
            guard let interfaceProps = properties[interface],
                let (signature, data) = interfaceProps[name]
            else {
                throw ExportableError.propertyNotFound(name)
            }
            return (signature, data)
        }

        func setProperty(interface: String, name: String, variant: Variant) async throws {
            if properties[interface] == nil {
                properties[interface] = [:]
            }

            // Extract the value from the variant based on its type
            let (signature, data): (Signature, [UInt8])
            switch variant.value {
            case .string(let str):
                let encoder = DBusEncoder()
                signature = Signature("s")
                data = try encoder.encode(str, signature: "s")
            case .int32(let int):
                let encoder = DBusEncoder()
                signature = Signature("i")
                data = try encoder.encode(int, signature: "i")
            case .bool(let bool):
                let encoder = DBusEncoder()
                signature = Signature("b")
                data = try encoder.encode(bool, signature: "b")
            default:
                // Default to string representation for other types
                let encoder = DBusEncoder()
                signature = Signature("s")
                data = try encoder.encode("\(variant.value.anyValue)", signature: "s")
            }

            properties[interface]?[name] = (signature, data)
        }
    }

    // MARK: - Peer Interface Tests

    @Suite("org.freedesktop.DBus.Peer Interface") struct PeerInterfaceTests {

        @Test("Ping method returns empty response")
        func pingMethodReturnsEmpty() async throws {
            let testObject = BasicTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Create a D-Bus method call message for Ping
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Peer",
                member: "Ping",
                destination: "com.example.Test",
                serial: 1
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "")
            #expect(responseMessage?.body.isEmpty == true)
        }

        @Test("GetMachineId method returns valid machine ID")
        func getMachineIdReturnsValidId() async throws {
            let testObject = BasicTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Create a D-Bus method call message for GetMachineId
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Peer",
                member: "GetMachineId",
                destination: "com.example.Test",
                serial: 1
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "s")
            #expect(!responseMessage!.body.isEmpty)

            // Decode and verify the machine ID
            let decoder = DBusDecoder()
            let machineId = try decoder.decode(
                String.self, from: responseMessage!.body, signature: responseMessage!.bodySignature!
            )
            #expect(machineId.count == 32)  // Should be 32 hex characters
            #expect(machineId.allSatisfy { $0.isHexDigit })
        }

        @Test("Machine ID is consistent across calls")
        func machineIdIsConsistent() async throws {
            let testObject1 = BasicTestObject()
            let exportableObject1 = ExportableObject(object: testObject1)
            let testObject2 = BasicTestObject()
            let exportableObject2 = ExportableObject(object: testObject2)

            // Mock connections for testing
            let connection1 = Connection()
            let connection2 = Connection()
            await exportableObject1.setExportContext(
                connection: connection1, path: try ObjectPath("/test/object1"))
            await exportableObject2.setExportContext(
                connection: connection2, path: try ObjectPath("/test/object2"))

            // Create D-Bus method call messages for GetMachineId
            let message1 = try Message.methodCall(
                path: try ObjectPath("/test/object1"),
                interface: "org.freedesktop.DBus.Peer",
                member: "GetMachineId",
                destination: "com.example.Test",
                serial: 1
            )

            let message2 = try Message.methodCall(
                path: try ObjectPath("/test/object2"),
                interface: "org.freedesktop.DBus.Peer",
                member: "GetMachineId",
                destination: "com.example.Test",
                serial: 1
            )

            let responseMessage1 = try await exportableObject1.handleMethodCall(message: message1)
            let responseMessage2 = try await exportableObject2.handleMethodCall(message: message2)

            let decoder = DBusDecoder()
            let machineId1 = try decoder.decode(
                String.self, from: responseMessage1!.body,
                signature: responseMessage1!.bodySignature!)
            let machineId2 = try decoder.decode(
                String.self, from: responseMessage2!.body,
                signature: responseMessage2!.bodySignature!)

            #expect(machineId1 == machineId2)
        }

        @Test("Invalid Peer method throws error")
        func invalidPeerMethodThrowsError() async throws {
            let testObject = BasicTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Create a D-Bus method call message for invalid method
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Peer",
                member: "InvalidMethod",
                destination: "com.example.Test",
                serial: 1
            )

            await #expect(throws: ExportableError.invalidMethod("InvalidMethod")) {
                _ = try await exportableObject.handleMethodCall(message: message)
            }
        }
    }

    // MARK: - Properties Interface Tests

    @Suite("org.freedesktop.DBus.Properties Interface") struct PropertiesInterfaceTests {

        @Test("Get method retrieves property value as variant")
        func getMethodRetrievesProperty() async throws {
            let testObject = EnhancedTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Manually create D-Bus arguments for Get(interface: "s", property: "s")
            var serializer = Serializer(
                signature: Signature("ss"), alignmentContext: .message, endianness: .littleEndian)
            try serializer.serialize("com.example.Test")
            try serializer.serialize("TestProperty")
            guard let argumentData = serializer.data else {
                throw ExportableError.methodCallFailed("Failed to serialize arguments")
            }

            // Create a D-Bus method call message for Properties.Get
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Properties",
                member: "Get",
                destination: "com.example.Test",
                serial: 1,
                body: argumentData,
                bodySignature: Signature("ss")
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "v")  // Should return a variant
            #expect(!responseMessage!.body.isEmpty)

            // Verify we can decode the variant
            let decoder = DBusDecoder()
            let variant = try decoder.decode(
                Variant.self, from: responseMessage!.body,
                signature: responseMessage!.bodySignature!)
            #expect(variant.signature.rawValue == "s")
        }

        @Test("Set method updates property value")
        func setMethodUpdatesProperty() async throws {
            let testObject = EnhancedTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Create a variant with new value
            let newValue = "updated_value"
            let variant = Variant(value: .string(newValue), signature: Signature("s"))

            // Manually create D-Bus arguments for Set(interface: "s", property: "s", value: "v")
            var serializer = Serializer(
                signature: Signature("ssv"), alignmentContext: .message, endianness: .littleEndian)
            try serializer.serialize("com.example.Test")
            try serializer.serialize("TestProperty")
            try serializer.serialize(variant)
            guard let argumentData = serializer.data else {
                throw ExportableError.methodCallFailed("Failed to serialize arguments")
            }

            // Create a D-Bus method call message for Properties.Set
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Properties",
                member: "Set",
                destination: "com.example.Test",
                serial: 1,
                body: argumentData,
                bodySignature: Signature("ssv")
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "")  // Set returns void
            #expect(responseMessage?.body.isEmpty == true)
        }

        @Test("GetAll method returns property dictionary")
        func getAllMethodReturnsPropertyDictionary() async throws {
            let testObject = EnhancedTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Manually create D-Bus arguments for GetAll(interface: "s")
            var serializer = Serializer(
                signature: Signature("s"), alignmentContext: .message, endianness: .littleEndian)
            try serializer.serialize("com.example.Test")
            guard let argumentData = serializer.data else {
                throw ExportableError.methodCallFailed("Failed to serialize arguments")
            }

            // Create a D-Bus method call message for Properties.GetAll
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Properties",
                member: "GetAll",
                destination: "com.example.Test",
                serial: 1,
                body: argumentData,
                bodySignature: Signature("s")
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "a{sv}")  // Should return dictionary of string->variant
            #expect(!responseMessage!.body.isEmpty)

            // Verify we can decode the dictionary
            let decoder = DBusDecoder()
            let properties = try decoder.decode(
                [String: Variant].self, from: responseMessage!.body,
                signature: responseMessage!.bodySignature!)
            #expect(properties.count == 2)
        }

        @Test("Invalid Properties method throws error")
        func invalidPropertiesMethodThrowsError() async throws {
            let testObject = BasicTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Create a D-Bus method call message for invalid method
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Properties",
                member: "InvalidMethod",
                destination: "com.example.Test",
                serial: 1
            )

            await #expect(throws: ExportableError.invalidMethod("InvalidMethod")) {
                _ = try await exportableObject.handleMethodCall(message: message)
            }
        }
    }

    // MARK: - Introspectable Interface Tests

    @Suite("org.freedesktop.DBus.Introspectable Interface") struct IntrospectableInterfaceTests {

        @Test("Introspect method works through ExportableObject")
        func introspectMethodWorksViaExportableObject() async throws {
            let testObject = BasicTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Create a D-Bus method call message for Introspect
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Introspectable",
                member: "Introspect",
                destination: "com.example.Test",
                serial: 1
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "s")
            #expect(!responseMessage!.body.isEmpty)

            // Verify we can decode the XML response
            let decoder = DBusDecoder()
            let xmlData = try decoder.decode(
                String.self, from: responseMessage!.body, signature: responseMessage!.bodySignature!
            )
            #expect(xmlData.contains("<!DOCTYPE node"))
            #expect(xmlData.contains("org.freedesktop.DBus.Introspectable"))
        }

        @Test("Invalid Introspectable method throws error")
        func invalidIntrospectableMethodThrowsError() async throws {
            let testObject = BasicTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Create a D-Bus method call message for invalid method
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Introspectable",
                member: "InvalidMethod",
                destination: "com.example.Test",
                serial: 1
            )

            await #expect(throws: ExportableError.invalidMethod("InvalidMethod")) {
                _ = try await exportableObject.handleMethodCall(message: message)
            }
        }
    }

    // MARK: - ExportableObject Integration Tests

    @Suite("ExportableObject Integration") struct ExportableObjectIntegrationTests {

        @Test("ExportableObject automatically adds standard interfaces")
        func exportableObjectAddsStandardInterfaces() async throws {
            let obj = EnhancedTestObject()
            let _ = ExportableObject(object: obj)

            // Verify standard interfaces are added
            #expect(obj.interfaces.keys.contains("org.freedesktop.DBus.Introspectable"))
            #expect(obj.interfaces.keys.contains("org.freedesktop.DBus.Peer"))
            #expect(obj.interfaces.keys.contains("org.freedesktop.DBus.Properties"))

            // Verify custom interface is preserved
            #expect(obj.interfaces.keys.contains("com.example.Test"))
        }

        @Test("Standard interfaces have correct method definitions")
        func standardInterfacesHaveCorrectMethods() async throws {
            let obj = BasicTestObject()
            let _ = ExportableObject(object: obj)

            // Test Introspectable interface
            let introspectable = obj.interfaces["org.freedesktop.DBus.Introspectable"]!
            #expect(introspectable.hasMethod("Introspect"))
            let introspectMethod = introspectable.methods["Introspect"]!
            #expect(introspectMethod.inputSignature.rawValue == "")
            #expect(introspectMethod.outputSignature.rawValue == "s")

            // Test Peer interface
            let peer = obj.interfaces["org.freedesktop.DBus.Peer"]!
            #expect(peer.hasMethod("Ping"))
            #expect(peer.hasMethod("GetMachineId"))

            let pingMethod = peer.methods["Ping"]!
            #expect(pingMethod.inputSignature.rawValue == "")
            #expect(pingMethod.outputSignature.rawValue == "")

            let getMachineIdMethod = peer.methods["GetMachineId"]!
            #expect(getMachineIdMethod.inputSignature.rawValue == "")
            #expect(getMachineIdMethod.outputSignature.rawValue == "s")

            // Test Properties interface
            let properties = obj.interfaces["org.freedesktop.DBus.Properties"]!
            #expect(properties.hasMethod("Get"))
            #expect(properties.hasMethod("Set"))
            #expect(properties.hasMethod("GetAll"))
            #expect(properties.hasSignal("PropertiesChanged"))

            let getMethod = properties.methods["Get"]!
            #expect(getMethod.inputSignature.rawValue == "ss")
            #expect(getMethod.outputSignature.rawValue == "v")

            let setMethod = properties.methods["Set"]!
            #expect(setMethod.inputSignature.rawValue == "ssv")
            #expect(setMethod.outputSignature.rawValue == "")

            let getAllMethod = properties.methods["GetAll"]!
            #expect(getAllMethod.inputSignature.rawValue == "s")
            #expect(getAllMethod.outputSignature.rawValue == "a{sv}")
        }

        @Test("Introspection generates proper XML")
        func introspectionGeneratesProperXML() async throws {
            let obj = EnhancedTestObject()
            let exportableObject = ExportableObject(object: obj)

            let xml = try await exportableObject.getIntrospectionData()

            // Verify XML structure
            #expect(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
            #expect(xml.contains("<!DOCTYPE node PUBLIC"))
            #expect(xml.hasSuffix("</node>"))

            // Verify all interfaces are present
            #expect(xml.contains("org.freedesktop.DBus.Introspectable"))
            #expect(xml.contains("org.freedesktop.DBus.Peer"))
            #expect(xml.contains("org.freedesktop.DBus.Properties"))
            #expect(xml.contains("com.example.Test"))

            // Verify method signatures are correct
            #expect(xml.contains("name=\"Ping\""))
            #expect(xml.contains("name=\"GetMachineId\""))
            #expect(xml.contains("name=\"Get\""))
            #expect(xml.contains("name=\"Set\""))
            #expect(xml.contains("name=\"GetAll\""))
        }

        @Test("ExportableObject handles method calls correctly")
        func exportableObjectHandlesMethodCallsCorrectly() async throws {
            let obj = EnhancedTestObject()
            let exportableObject = ExportableObject(object: obj)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Test Ping method via D-Bus message
            let pingMessage = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Peer",
                member: "Ping",
                destination: "test.service",
                serial: 1
            )

            let pingResponse = try await exportableObject.handleMethodCall(message: pingMessage)
            #expect(pingResponse != nil)
            #expect(pingResponse?.messageType == .methodReturn)
            #expect(pingResponse?.bodySignature?.rawValue == "")

            // Test Introspect method via D-Bus message
            let introspectMessage = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Introspectable",
                member: "Introspect",
                destination: "test.service",
                serial: 2
            )

            let introspectResponse = try await exportableObject.handleMethodCall(
                message: introspectMessage)
            #expect(introspectResponse != nil)
            #expect(introspectResponse?.messageType == .methodReturn)
            #expect(introspectResponse?.bodySignature?.rawValue == "s")
        }
    }

    // MARK: - Error Handling Tests

    @Suite("Error Handling") struct ErrorHandlingTests {

        @Test("Invalid interface throws correct error")
        func invalidInterfaceThrowsCorrectError() async throws {
            let obj = BasicTestObject()

            await #expect(throws: ExportableError.invalidInterface("invalid.interface")) {
                try await obj.call(
                    interface: "invalid.interface",
                    method: "SomeMethod",
                    signature: Signature(""),
                    arguments: []
                )
            }
        }

        @Test("Property not found throws correct error")
        func propertyNotFoundThrowsCorrectError() async throws {
            let obj = EnhancedTestObject()

            await #expect(throws: ExportableError.propertyNotFound("NonexistentProperty")) {
                try await obj.getProperty(
                    interface: "com.example.Test", name: "NonexistentProperty")
            }
        }

        @Test("ExportableError conforms to Equatable")
        func exportableErrorConformsToEquatable() {
            let error1 = ExportableError.invalidInterface("test")
            let error2 = ExportableError.invalidInterface("test")
            let error3 = ExportableError.invalidMethod("test")

            #expect(error1 == error2)
            #expect(error1 != error3)
        }
    }

    // MARK: - Integration with Custom Interfaces

    @Suite("Custom Interface Integration") struct CustomInterfaceIntegrationTests {

        @Test("Custom methods work alongside standard interfaces")
        func customMethodsWorkAlongsideStandard() async throws {
            let testObject = EnhancedTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Test custom method
            var serializer = Serializer(
                signature: Signature("s"), alignmentContext: .message, endianness: .littleEndian)
            try serializer.serialize("Hello, World!")
            guard let argumentData = serializer.data else {
                throw ExportableError.methodCallFailed("Failed to serialize arguments")
            }

            // Create a D-Bus method call message for custom method
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "com.example.Test",
                member: "Echo",
                destination: "com.example.Test",
                serial: 1,
                body: argumentData,
                bodySignature: Signature("s")
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "s")

            let decoder = DBusDecoder()
            let output = try decoder.decode(
                String.self, from: responseMessage!.body, signature: responseMessage!.bodySignature!
            )
            #expect(output == "Echo: Hello, World!")
        }

        @Test("Standard interface methods still work with custom interfaces present")
        func standardMethodsWorkWithCustomInterfaces() async throws {
            let testObject = EnhancedTestObject()
            let exportableObject = ExportableObject(object: testObject)

            // Mock connection for testing
            let connection = Connection()
            await exportableObject.setExportContext(
                connection: connection, path: try ObjectPath("/test/object"))

            // Test standard Ping method
            let message = try Message.methodCall(
                path: try ObjectPath("/test/object"),
                interface: "org.freedesktop.DBus.Peer",
                member: "Ping",
                destination: "com.example.Test",
                serial: 1
            )

            let responseMessage = try await exportableObject.handleMethodCall(message: message)

            #expect(responseMessage != nil)
            #expect(responseMessage?.messageType == .methodReturn)
            #expect(responseMessage?.bodySignature?.rawValue == "")
            #expect(responseMessage?.body.isEmpty == true)
        }
    }
}
