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

@Suite("Property Tests") struct DBusPropertyTests {
    @Test("Property call serialization works correctly")
    func testPropertyCallSerialization() async throws {
        // Test that property calls serialize correctly without the "invalid body" error
        let connection = Connection()

        // We don't need to actually connect for this test, just verify the serialization works
        // Create a proxy object
        let _ = connection.proxyObject(
            serviceName: "org.freedesktop.systemd1",
            objectPath: try ObjectPath("/org/freedesktop/systemd1"),
            interfaceName: "org.freedesktop.systemd1.Manager"
        )

        // Test that the property call serialization doesn't throw encoding errors
        do {
            // This should create valid D-Bus message body without connection errors
            let signature = Signature(elements: [.string, .string])
            let encoder = DBusEncoder()
            let body = try encoder.encode(
                ["org.freedesktop.systemd1.Manager", "Environment"], signature: signature)

            // Verify that the body is not empty and has reasonable content
            #expect(!body.isEmpty, "Property call body should not be empty")

            // The body should contain the serialized strings
            // For two strings, we expect a reasonable body size
            #expect(
                body.count > 40,
                "Property call body should contain serialized interface name and property name")
        } catch {
            Issue.record("Property call serialization failed: \(error)")
            throw error
        }
    }

    @Test("Property call message creation works correctly")
    func testPropertyCallMessageCreation() async throws {
        // Test that we can create a valid property call message
        let connection = Connection()

        do {
            // Create a method call for Properties.Get
            let signature = Signature(elements: [.string, .string])
            let encoder = DBusEncoder()
            let body = try encoder.encode(
                ["org.freedesktop.systemd1.Manager", "Environment"], signature: signature)

            let message = try await connection.createMethodCall(
                path: try ObjectPath("/org/freedesktop/systemd1"),
                interface: "org.freedesktop.DBus.Properties",
                member: "Get",
                destination: "org.freedesktop.systemd1",
                body: body,
                bodySignature: signature
            )

            // Verify the message is valid
            #expect(message.messageType == .methodCall)
            #expect(message.path?.fullPath == "/org/freedesktop/systemd1")
            #expect(message.interface == "org.freedesktop.DBus.Properties")
            #expect(message.member == "Get")
            #expect(message.destination == "org.freedesktop.systemd1")
            #expect(message.bodySignature?.rawValue == "ss")
            #expect(!message.body.isEmpty)

            // Try to serialize the message (this is where the "invalid body" error would occur)
            let serializedMessage = try message.serialize()
            #expect(!serializedMessage.isEmpty, "Serialized message should not be empty")
        } catch {
            Issue.record("Property call message creation failed: \(error)")
            throw error
        }
    }
}
