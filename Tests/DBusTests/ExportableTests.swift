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

@Suite("Exportable tests") struct ExportableTests {

    // MARK: - Argument Tests

    @Suite("Argument tests") struct ArgumentTests {

        @Test("Creates argument with correct properties")
        func createArgument() throws {
            let arg = Argument(name: "testArg", signature: "i", direction: .in)

            #expect(arg.name == "testArg")
            #expect(arg.signature == "i")
            #expect(arg.direction == .in)
        }

        @Test(
            "Creates arguments with different directions",
            arguments: [
                ArgumentDirection.in,
                ArgumentDirection.out,
            ])
        func createArgumentsWithDirections(direction: ArgumentDirection) throws {
            let arg = Argument(name: "arg", signature: "s", direction: direction)
            #expect(arg.direction == direction)
        }

        @Test(
            "Creates arguments with different signatures",
            arguments: [
                "i", "s", "b", "d", "ay", "a{ss}", "(ii)", "v",
            ])
        func createArgumentsWithSignatures(signatureString: String) throws {
            let signature: Signature = Signature(rawValue: signatureString)!
            let arg = Argument(name: "test", signature: signature, direction: .in)
            #expect(arg.signature == signature)
        }
    }

    // MARK: - Method Tests

    @Suite("Method tests") struct MethodTests {

        @Test("Creates method with no arguments")
        func createMethodWithNoArguments() throws {
            let method = Method(name: "TestMethod", arguments: [])

            #expect(method.name == "TestMethod")
            #expect(method.arguments.isEmpty)
            #expect(method.inputArguments.isEmpty)
            #expect(method.outputArguments.isEmpty)
        }

        @Test("Creates method with input arguments only")
        func createMethodWithInputArguments() throws {
            let args = [
                Argument(name: "param1", signature: "i", direction: .in),
                Argument(name: "param2", signature: "s", direction: .in),
            ]
            let method = Method(name: "TestMethod", arguments: args)

            #expect(method.inputArguments.count == 2)
            #expect(method.outputArguments.count == 0)
            #expect(method.inputArguments[0].name == "param1")
            #expect(method.inputArguments[1].name == "param2")
        }

        @Test("Generates correct input signature for multiple arguments")
        func inputSignatureMultiple() throws {
            let args = [
                Argument(name: "param1", signature: "i", direction: .in),
                Argument(name: "param2", signature: "s", direction: .in),
                Argument(name: "param3", signature: "b", direction: .in),
            ]
            let method = Method(name: "TestMethod", arguments: args)
            #expect(method.inputSignature.rawValue == "isb")
        }

        @Test("Generates correct output signature for multiple arguments")
        func outputSignatureMultiple() throws {
            let args = [
                Argument(name: "result1", signature: "i", direction: .out),
                Argument(name: "result2", signature: "s", direction: .out),
                Argument(name: "result3", signature: "b", direction: .out),
            ]
            let method = Method(name: "TestMethod", arguments: args)
            #expect(method.outputSignature.rawValue == "isb")
        }

        @Test("Ignores output arguments in input signature")
        func inputSignatureIgnoresOutput() throws {
            let args = [
                Argument(name: "input", signature: "i", direction: .in),
                Argument(name: "output", signature: "s", direction: .out),
            ]
            let method = Method(name: "TestMethod", arguments: args)
            #expect(method.inputSignature.rawValue == "i")
        }

        @Test("Handles complex signatures correctly")
        func complexSignatures() throws {
            let args = [
                Argument(name: "arrayParam", signature: "ai", direction: .in),
                Argument(name: "dictParam", signature: "a{ss}", direction: .in),
                Argument(name: "structResult", signature: "(is)", direction: .out),
                Argument(name: "variantResult", signature: "v", direction: .out),
            ]
            let method = Method(name: "ComplexMethod", arguments: args)

            #expect(method.inputSignature.rawValue == "aia{ss}")
            #expect(method.outputSignature.rawValue == "(is)v")
        }
    }

    // MARK: - Property Tests

    @Suite("Property tests") struct PropertyTests {

        @Test("Creates property with read access")
        func createReadProperty() throws {
            let property = Property(name: "ReadOnly", signature: "s", access: .read)

            #expect(property.name == "ReadOnly")
            #expect(property.signature.rawValue == "s")
            #expect(property.access == .read)
        }

        @Test("Creates property with write access")
        func createWriteProperty() throws {
            let property = Property(name: "WriteOnly", signature: "i", access: .write)

            #expect(property.name == "WriteOnly")
            #expect(property.signature.rawValue == "i")
            #expect(property.access == .write)
        }

        @Test("Creates property with readwrite access")
        func createReadWriteProperty() throws {
            let property = Property(name: "ReadWrite", signature: "b", access: .readwrite)

            #expect(property.name == "ReadWrite")
            #expect(property.signature.rawValue == "b")
            #expect(property.access == .readwrite)
        }
    }

    // MARK: - Signal Tests

    @Suite("Signal tests") struct SignalTests {

        @Test("Creates signal with signature")
        func createSignal() throws {
            let signal = Signal(name: "TestSignal", signature: "is")

            #expect(signal.name == "TestSignal")
            #expect(signal.signature.rawValue == "is")
        }

        @Test(
            "Creates signals with different signatures",
            arguments: [
                "", "i", "s", "is", "a{ss}", "(ii)s", "v",
            ])
        func createSignalsWithSignatures(signatureString: String) throws {
            let signature: Signature = Signature(rawValue: signatureString)!
            let signal = Signal(name: "TestSignal", signature: signature)
            #expect(signal.signature == signature)
        }
    }

    // MARK: - Interface Tests

    @Suite("Interface tests") struct InterfaceTests {

        @Test("Creates empty interface")
        func createEmptyInterface() throws {
            let interface = Interface(name: "com.example.Test")

            #expect(interface.name == "com.example.Test")
            #expect(interface.methods.isEmpty)
            #expect(interface.properties.isEmpty)
            #expect(interface.signals.isEmpty)
        }

        @Test("Creates interface with methods")
        func createInterfaceWithMethods() throws {
            let method1 = Method(name: "Method1", arguments: [])
            let method2 = Method(name: "Method2", arguments: [])
            let methods = ["Method1": method1, "Method2": method2]

            let interface = Interface(name: "com.example.Test", methods: methods)

            #expect(interface.methods.count == 2)
            #expect(interface.methods["Method1"] != nil)
            #expect(interface.methods["Method2"] != nil)
        }

        @Test("Creates interface with properties")
        func createInterfaceWithProperties() throws {
            let prop1 = Property(name: "Prop1", signature: "s", access: .read)
            let prop2 = Property(name: "Prop2", signature: "i", access: .readwrite)
            let properties = ["Prop1": prop1, "Prop2": prop2]

            let interface = Interface(name: "com.example.Test", properties: properties)

            #expect(interface.properties.count == 2)
            #expect(interface.properties["Prop1"] != nil)
            #expect(interface.properties["Prop2"] != nil)
        }

        @Test("hasMethod returns correct values")
        func hasMethodCheck() throws {
            let method = Method(name: "ExistingMethod", arguments: [])
            let interface = Interface(
                name: "com.example.Test",
                methods: ["ExistingMethod": method]
            )

            #expect(interface.hasMethod("ExistingMethod") == true)
            #expect(interface.hasMethod("NonExistentMethod") == false)
        }

        @Test("hasProperty returns correct values")
        func hasPropertyCheck() throws {
            let property = Property(name: "ExistingProp", signature: "s", access: .read)
            let interface = Interface(
                name: "com.example.Test",
                properties: ["ExistingProp": property]
            )

            #expect(interface.hasProperty("ExistingProp") == true)
            #expect(interface.hasProperty("NonExistentProp") == false)
        }

        @Test("hasSignal returns correct values")
        func hasSignalCheck() throws {
            let signal = Signal(name: "ExistingSignal", signature: "i")
            let interface = Interface(
                name: "com.example.Test",
                signals: ["ExistingSignal": signal]
            )

            #expect(interface.hasSignal("ExistingSignal") == true)
            #expect(interface.hasSignal("NonExistentSignal") == false)
        }
    }

    // MARK: - Introspection Tests

    @Suite("Introspection tests") struct IntrospectionTests {

        // Test object that implements Exportable
        final class TestExportableObject: Exportable, @unchecked Sendable {
            var interfaces: [String: Interface]

            init(interfaces: [String: Interface]) {
                self.interfaces = interfaces
            }

            func call(interface: String, method: String, signature: Signature, arguments: [UInt8])
                async throws -> (Signature, [UInt8])
            {
                return (Signature(elements: []), [])
            }

            func getProperty(interface: String, name: String) async throws -> (Signature, [UInt8]) {
                return (Signature(elements: []), [])
            }

            func setProperty(interface: String, name: String, variant: Variant) async throws {
                // No-op for testing
            }
        }

        @Test("Generates basic introspection XML")
        func generateBasicIntrospectionXML() async throws {
            let testObject = TestExportableObject(interfaces: [:])
            let exportableObject = ExportableObject(object: testObject)

            let xml = try await exportableObject.getIntrospectionData()

            #expect(xml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
            #expect(
                xml.contains(
                    "<!DOCTYPE node PUBLIC \"-//freedesktop//DTD D-BUS Object Introspection 1.0//EN\""
                ))
            #expect(
                xml.contains("\"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd\">"))
            #expect(xml.contains("<node>"))
            #expect(xml.contains("</node>"))
        }

        @Test("Generates introspection XML with single interface")
        func generateIntrospectionXMLWithInterface() async throws {
            let interface = Interface(name: "com.example.Test")
            let testObject = TestExportableObject(interfaces: ["com.example.Test": interface])
            let exportableObject = ExportableObject(object: testObject)

            let xml = try await exportableObject.getIntrospectionData()

            #expect(xml.contains("<interface name=\"com.example.Test\""))
        }

        @Test("Generates introspection XML with multiple interfaces")
        func generateIntrospectionXMLWithMultipleInterfaces() async throws {
            let interface1 = Interface(name: "com.example.First")
            let interface2 = Interface(name: "com.example.Second")
            let interfaces = [
                "com.example.First": interface1,
                "com.example.Second": interface2,
            ]
            let testObject = TestExportableObject(interfaces: interfaces)
            let exportableObject = ExportableObject(object: testObject)

            let xml = try await exportableObject.getIntrospectionData()

            // Should contain both interfaces
            #expect(xml.contains("<interface name=\"com.example.First\""))
            #expect(xml.contains("<interface name=\"com.example.Second\""))
        }

        @Test("Introspection XML is well-formed")
        func introspectionXMLWellFormed() async throws {
            let method = Method(
                name: "TestMethod",
                arguments: [
                    Argument(name: "input", signature: "s", direction: .in),
                    Argument(name: "output", signature: "i", direction: .out),
                ])
            let property = Property(name: "TestProp", signature: "b", access: .readwrite)
            let signal = Signal(name: "TestSignal", signature: "d")

            let interface = Interface(
                name: "com.example.Complete",
                methods: ["TestMethod": method],
                properties: ["TestProp": property],
                signals: ["TestSignal": signal]
            )

            let testObject = TestExportableObject(interfaces: ["com.example.Complete": interface])
            let exportableObject = ExportableObject(object: testObject)

            let xml = try await exportableObject.getIntrospectionData()

            // Verify structure
            #expect(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
            #expect(xml.hasSuffix("</node>"))

            // Count opening and closing tags
            let nodeOpenCount = xml.components(separatedBy: "<node>").count - 1
            let nodeCloseCount = xml.components(separatedBy: "</node>").count - 1
            #expect(nodeOpenCount == nodeCloseCount)

            let interfaceOpenCount = xml.components(separatedBy: "<interface").count - 1
            let interfaceCloseCount = xml.components(separatedBy: "</interface>").count - 1
            #expect(interfaceOpenCount == interfaceCloseCount)
        }

        @Test("Introspection preserves interface names")
        func introspectionPreservesInterfaceNames() async throws {
            // Create multiple interfaces
            let interfaces = [
                "org.freedesktop.DBus.Properties": Interface(
                    name: "org.freedesktop.DBus.Properties"),
                "com.example.Alpha": Interface(name: "com.example.Alpha"),
                "com.example.Beta": Interface(name: "com.example.Beta"),
            ]

            let testObject = TestExportableObject(interfaces: interfaces)
            let exportableObject = ExportableObject(object: testObject)

            let xml = try await exportableObject.getIntrospectionData()

            // All interfaces should be present
            for interfaceName in interfaces.keys {
                #expect(xml.contains("<interface name=\"\(interfaceName)\""))
            }
        }
    }
}
