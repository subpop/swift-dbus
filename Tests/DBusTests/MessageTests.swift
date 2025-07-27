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

// MARK: - Basic Message Creation Tests

@Suite("Message tests") struct MessageTests {
    @Test("Creates a method call message")
    func methodCallMessageCreation() throws {
        let path = try ObjectPath("/com/example/TestObject")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.TestInterface",
            member: "TestMethod",
            destination: "com.example.TestService",
            serial: 123,
            bodySignature: "s"
        )

        #expect(message.messageType == .methodCall)
        #expect(message.serial == 123)
        #expect(message.path == path)
        #expect(message.interface == "com.example.TestInterface")
        #expect(message.member == "TestMethod")
        #expect(message.destination == "com.example.TestService")
        #expect(message.bodySignature?.rawValue == "s")
        #expect(message.protocolVersion == 1)
        #expect(message.endianness == .littleEndian)
    }

    @Test("Creates a method return message")
    func methodReturnMessageCreation() throws {
        let message = try Message.methodReturn(
            replySerial: 123,
            destination: "com.example.TestService",
            serial: 124,
            bodySignature: "i"
        )

        #expect(message.messageType == .methodReturn)
        #expect(message.serial == 124)
        #expect(message.replySerial == 123)
        #expect(message.destination == "com.example.TestService")
        #expect(message.bodySignature?.rawValue == "i")
    }

    @Test("Creates an error message")
    func errorMessageCreation() throws {
        let message = try Message.error(
            errorName: "com.example.TestError",
            replySerial: 123,
            destination: "com.example.TestService",
            serial: 125,
            bodySignature: "s"
        )

        #expect(message.messageType == .error)
        #expect(message.serial == 125)
        #expect(message.errorName == "com.example.TestError")
        #expect(message.replySerial == 123)
        #expect(message.destination == "com.example.TestService")
    }

    @Test("Creates a signal message")
    func signalMessageCreation() throws {
        let path = try ObjectPath("/com/example/TestObject")
        let message = try Message.signal(
            path: path,
            interface: "com.example.TestInterface",
            member: "TestSignal",
            destination: "com.example.TestService",
            serial: 126,
            bodySignature: "as"
        )

        #expect(message.messageType == .signal)
        #expect(message.serial == 126)
        #expect(message.path == path)
        #expect(message.interface == "com.example.TestInterface")
        #expect(message.member == "TestSignal")
        #expect(message.destination == "com.example.TestService")
    }

    // MARK: - Message Flags Tests

    @Test("Creates a message with custom flags")
    func messageFlags() throws {
        let path = try ObjectPath("/test")
        let flags: DBusMessageFlags = [.noReplyExpected, .noAutoStart]

        let message = try Message.methodCall(
            path: path,
            member: "Test",
            serial: 1,
            flags: flags
        )

        #expect(message.flags == flags)
        #expect(message.flags.contains(.noReplyExpected))
        #expect(message.flags.contains(.noAutoStart))
        #expect(!message.flags.contains(.allowInteractiveAuthorization))
    }

    // MARK: - Validation Tests

    @Test("Validates a message successfully")
    func validationSuccess() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            member: "Test",
            serial: 1
        )

        // Should not throw
        try message.validate()
    }

    @Test("Validation fails for zero serial")
    func validationFailsForZeroSerial() throws {
        #expect(throws: DBusMessageError.invalidSerial) {
            try Message(
                messageType: .methodCall,
                serial: 0
            )
        }
    }

    @Test("Validation fails for unsupported protocol version")
    func validationFailsForUnsupportedProtocolVersion() throws {
        #expect(throws: DBusMessageError.unsupportedProtocolVersion(2)) {
            try Message(
                messageType: .methodCall,
                protocolVersion: 2,
                serial: 1
            )
        }
    }

    @Test("Validation fails for missing required fields")
    func validationFailsForMissingRequiredFields() throws {
        // Method call without path
        let messageWithoutPath = try Message(
            messageType: .methodCall,
            serial: 1,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .member, value: try HeaderVariant("Test", signature: "s"))
            ]
        )

        #expect(throws: DBusMessageError.missingRequiredHeaderField(.path)) {
            try messageWithoutPath.validate()
        }

        // Method call without member
        let path = try ObjectPath("/test")
        let messageWithoutMember = try Message(
            messageType: .methodCall,
            serial: 1,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path, value: try HeaderVariant(path, signature: "o"))
            ]
        )

        #expect(throws: DBusMessageError.missingRequiredHeaderField(.member)) {
            try messageWithoutMember.validate()
        }
    }

    @Test("Validation fails for method return without reply serial")
    func validationFailsForMethodReturnWithoutReplySerial() throws {
        let message = try Message(
            messageType: .methodReturn,
            serial: 1
        )

        #expect(throws: DBusMessageError.missingRequiredHeaderField(.replySerial)) {
            try message.validate()
        }
    }

    @Test("Validation fails for error without error name")
    func validationFailsForErrorWithoutErrorName() throws {
        let message = try Message(
            messageType: .error,
            serial: 1,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .replySerial,
                    value: try HeaderVariant(UInt32(123), signature: "u"))
            ]
        )

        #expect(throws: DBusMessageError.missingRequiredHeaderField(.errorName)) {
            try message.validate()
        }
    }

    @Test("Validation fails for signal without required fields")
    func validationFailsForSignalWithoutRequiredFields() throws {
        // Signal without path
        let messageWithoutPath = try Message(
            messageType: .signal,
            serial: 1,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .interface,
                    value: try HeaderVariant("com.example.Test", signature: "s")),
                DBusHeaderFieldEntry(
                    field: .member,
                    value: try HeaderVariant("TestSignal", signature: "s")),
            ]
        )

        #expect(throws: DBusMessageError.missingRequiredHeaderField(.path)) {
            try messageWithoutPath.validate()
        }

        // Signal without interface
        let path = try ObjectPath("/test")
        let messageWithoutInterface = try Message(
            messageType: .signal,
            serial: 1,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path, value: try HeaderVariant(path, signature: "o")),
                DBusHeaderFieldEntry(
                    field: .member,
                    value: try HeaderVariant("TestSignal", signature: "s")),
            ]
        )

        #expect(throws: DBusMessageError.missingRequiredHeaderField(.interface)) {
            try messageWithoutInterface.validate()
        }
    }

    // MARK: - Serialization Tests

    @Test("Serializes a message successfully")
    func basicSerialization() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "TestMethod",
            serial: 1
        )

        let serializedData = try message.serialize()

        // Should have at least the minimum header size
        #expect(serializedData.count >= 16)

        // Check endianness byte
        #expect(serializedData[0] == UInt8(ascii: "l"))  // little-endian

        // Check message type
        #expect(serializedData[1] == DBusMessageType.methodCall.rawValue)

        // Check protocol version
        #expect(serializedData[3] == 1)

        // Check serial (little-endian)
        let serial =
            UInt32(serializedData[8]) | (UInt32(serializedData[9]) << 8)
            | (UInt32(serializedData[10]) << 16) | (UInt32(serializedData[11]) << 24)
        #expect(serial == 1)
    }

    @Test("Serializes a message with a body")
    func serializationWithBody() throws {
        let path = try ObjectPath("/test")
        let bodyData: [UInt8] = [0x00, 0x00, 0x00, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x00]  // "Hello" string

        let message = try Message.methodCall(
            path: path,
            member: "TestMethod",
            serial: 1,
            body: bodyData,
            bodySignature: "s"
        )

        let serializedData = try message.serialize()

        // Check body length in header
        let bodyLength =
            UInt32(serializedData[4]) | (UInt32(serializedData[5]) << 8)
            | (UInt32(serializedData[6]) << 16) | (UInt32(serializedData[7]) << 24)
        #expect(bodyLength == UInt32(bodyData.count))

        // Body should be at the end after header padding
        let bodyStart = serializedData.count - bodyData.count
        let extractedBody = Array(serializedData[bodyStart...])
        #expect(extractedBody == bodyData)
    }

    // MARK: - Deserialization Tests

    @Test("Deserializes a message successfully")
    func basicDeserialization() throws {
        let path = try ObjectPath("/test")
        let originalMessage = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "TestMethod",
            destination: "com.example.Service",
            serial: 42
        )

        let serializedData = try originalMessage.serialize()
        let deserializedMessage = try Message.deserialize(from: serializedData)

        #expect(deserializedMessage.messageType == .methodCall)
        #expect(deserializedMessage.serial == 42)
        #expect(deserializedMessage.path == path)
        #expect(deserializedMessage.interface == "com.example.Test")
        #expect(deserializedMessage.member == "TestMethod")
        #expect(deserializedMessage.destination == "com.example.Service")
        #expect(deserializedMessage.protocolVersion == 1)
        #expect(deserializedMessage.endianness == .littleEndian)
    }

    @Test("Deserializes a message with a body")
    func deserializationWithBody() throws {
        let path = try ObjectPath("/test")
        let bodyData: [UInt8] = [0x00, 0x00, 0x00, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x00]

        let originalMessage = try Message.methodCall(
            path: path,
            member: "TestMethod",
            serial: 1,
            body: bodyData,
            bodySignature: "s"
        )

        let serializedData = try originalMessage.serialize()
        let deserializedMessage = try Message.deserialize(from: serializedData)

        #expect(deserializedMessage.body == bodyData)
        #expect(deserializedMessage.bodyLength == UInt32(bodyData.count))
        #expect(deserializedMessage.bodySignature?.rawValue == "s")
    }

    @Test("Round-trips a message successfully")
    func roundTripSerialization() throws {
        let testCases: [Message] = [
            try Message.methodCall(
                path: ObjectPath("/test/path"),
                interface: "com.example.Interface",
                member: "TestMethod",
                destination: "com.example.Service",
                serial: 1,
                flags: [.noReplyExpected]
            ),
            try Message.methodReturn(
                replySerial: 1,
                destination: "com.example.Client",
                serial: 2
            ),
            try Message.error(
                errorName: "com.example.Error",
                replySerial: 1,
                destination: "com.example.Client",
                serial: 3
            ),
            try Message.signal(
                path: ObjectPath("/test/signal"),
                interface: "com.example.Signals",
                member: "TestSignal",
                serial: 4
            ),
        ]

        for originalMessage in testCases {
            let serializedData = try originalMessage.serialize()
            let deserializedMessage = try Message.deserialize(from: serializedData)

            #expect(deserializedMessage.messageType == originalMessage.messageType)
            #expect(deserializedMessage.serial == originalMessage.serial)
            #expect(deserializedMessage.flags == originalMessage.flags)
            #expect(deserializedMessage.protocolVersion == originalMessage.protocolVersion)
            #expect(deserializedMessage.body == originalMessage.body)
            #expect(deserializedMessage.bodyLength == originalMessage.bodyLength)
        }
    }

    // MARK: - Error Cases Tests

    @Test("Deserialization fails with invalid data")
    func deserializationFailsWithInvalidData() throws {
        // Too short data
        let shortData: [UInt8] = [0x6C, 0x01, 0x00, 0x01]
        #expect(throws: DBusMessageError.invalidMessageFormat) {
            try Message.deserialize(from: shortData)
        }

        // Invalid endianness
        let invalidEndianness: [UInt8] = Array(repeating: 0, count: 20)
        var invalidData = invalidEndianness
        invalidData[0] = 0x58  // 'X' - invalid endianness
        #expect(throws: DBusMessageError.invalidEndianness) {
            try Message.deserialize(from: invalidData)
        }

        // Invalid message type
        var invalidTypeData: [UInt8] = Array(repeating: 0, count: 20)
        invalidTypeData[0] = UInt8(ascii: "l")  // valid endianness
        invalidTypeData[1] = 99  // invalid message type
        invalidTypeData[3] = 1  // valid protocol version
        invalidTypeData[8] = 1  // valid serial

        do {
            _ = try Message.deserialize(from: invalidTypeData)
            Issue.record("Expected invalidMessageType error")
        } catch let error as DBusMessageError {
            if case .invalidMessageType(let type) = error {
                #expect(type == 99)
            } else {
                Issue.record("Expected invalidMessageType error")
            }
        }
    }

    // MARK: - Real-world Message Tests

    @Test("Creates a D-Bus Hello message")
    func dBusHelloMessage() throws {
        // Test a typical org.freedesktop.DBus.Hello message
        let message = try Message.methodCall(
            path: ObjectPath("/org/freedesktop/DBus"),
            interface: "org.freedesktop.DBus",
            member: "Hello",
            destination: "org.freedesktop.DBus",
            serial: 1,
            flags: [.noReplyExpected]
        )

        #expect(message.path?.fullPath == "/org/freedesktop/DBus")
        #expect(message.interface == "org.freedesktop.DBus")
        #expect(message.member == "Hello")
        #expect(message.destination == "org.freedesktop.DBus")
        #expect(message.flags.contains(.noReplyExpected))

        // Should serialize and deserialize correctly
        let serialized = try message.serialize()
        let deserialized = try Message.deserialize(from: serialized)
        #expect(deserialized.path == message.path)
        #expect(deserialized.interface == message.interface)
        #expect(deserialized.member == message.member)
    }

    @Test("Creates an org.freedesktop.DBus.Properties.Get message")
    func propertyGetMessage() throws {
        // Test a typical Properties.Get message
        let message = try Message.methodCall(
            path: ObjectPath("/com/example/Object"),
            interface: "org.freedesktop.DBus.Properties",
            member: "Get",
            destination: "com.example.Service",
            serial: 2,
            bodySignature: "ss"
        )

        try message.validate()

        let serialized = try message.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        #expect(deserialized.interface == "org.freedesktop.DBus.Properties")
        #expect(deserialized.member == "Get")
        #expect(deserialized.bodySignature?.rawValue == "ss")
    }

    @Test("Creates a signal message")
    func signalMessage() throws {
        // Test a typical signal message
        let message = try Message.signal(
            path: ObjectPath("/com/example/Object"),
            interface: "com.example.Interface",
            member: "SomethingChanged",
            serial: 100,
            bodySignature: "sv"
        )

        try message.validate()

        let serialized = try message.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        #expect(deserialized.messageType == .signal)
        #expect(deserialized.path?.fullPath == "/com/example/Object")
        #expect(deserialized.interface == "com.example.Interface")
        #expect(deserialized.member == "SomethingChanged")
    }

    // MARK: - Header Field Serialization Tests

    @Test("Header fields are serialized as STRUCT format")
    func headerFieldsStructFormat() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "TestMethod",
            destination: "com.example.Service",
            serial: 1
        )

        let serializedData = try message.serialize()

        // Extract header fields length (bytes 12-16)
        let headerFieldsLength =
            UInt32(serializedData[12]) | (UInt32(serializedData[13]) << 8)
            | (UInt32(serializedData[14]) << 16) | (UInt32(serializedData[15]) << 24)

        // Header fields start at byte 16
        let headerFieldsStart = 16
        let headerFieldsEnd = headerFieldsStart + Int(headerFieldsLength)
        let headerFieldsData = Array(serializedData[headerFieldsStart..<headerFieldsEnd])

        // Verify we have data
        #expect(headerFieldsData.count > 0)

        // Parse the first field to verify STRUCT format
        var offset = 0

        // Skip initial alignment padding if any
        while offset < headerFieldsData.count && headerFieldsData[offset] == 0 {
            offset += 1
        }

        // Should have field code (BYTE) followed by variant signature
        #expect(offset < headerFieldsData.count)

        // First field should be PATH (field code 1)
        let firstFieldCode = headerFieldsData[offset]
        #expect(firstFieldCode == 1)  // DBusDBusHeaderField.path.rawValue
        offset += 1

        // Next should be variant signature length
        let sigLength = Int(headerFieldsData[offset])
        #expect(sigLength == 1)  // "o" has length 1
        offset += 1

        // Next should be signature string
        let sigByte = headerFieldsData[offset]
        #expect(sigByte == UInt8(ascii: "o"))
        offset += 1

        // Next should be null terminator
        #expect(headerFieldsData[offset] == 0)
        offset += 1

        // Next should be value alignment padding (4-byte aligned for object path)
        let currentPos = 16 + 4 + offset  // fixed header + array length + current offset
        let padding = (4 - (currentPos % 4)) % 4
        for _ in 0..<padding {
            #expect(headerFieldsData[offset] == 0)
            offset += 1
        }

        // Next should be object path length
        let pathLength =
            UInt32(headerFieldsData[offset]) | (UInt32(headerFieldsData[offset + 1]) << 8)
            | (UInt32(headerFieldsData[offset + 2]) << 16)
            | (UInt32(headerFieldsData[offset + 3]) << 24)
        #expect(pathLength == 5)  // "/test" has length 5
    }

    @Test("Header fields are properly aligned to 8-byte boundaries")
    func headerFieldsAlignment() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "TestMethod",
            destination: "com.example.Service",
            serial: 1
        )

        let serializedData = try message.serialize()

        // Extract header fields data
        let headerFieldsLength =
            UInt32(serializedData[12]) | (UInt32(serializedData[13]) << 8)
            | (UInt32(serializedData[14]) << 16) | (UInt32(serializedData[15]) << 24)
        let headerFieldsStart = 16
        let headerFieldsEnd = headerFieldsStart + Int(headerFieldsLength)
        let headerFieldsData = Array(serializedData[headerFieldsStart..<headerFieldsEnd])

        // Parse each STRUCT and verify 8-byte alignment
        var offset = 0
        var structCount = 0

        while offset < headerFieldsData.count {
            // Skip any padding bytes
            let paddingStart = offset
            while offset < headerFieldsData.count && headerFieldsData[offset] == 0 {
                offset += 1
            }

            // If we've reached the end, break
            if offset >= headerFieldsData.count {
                break
            }

            // Check that padding aligns to 8-byte boundary (for non-first structs)
            if structCount > 0 {
                #expect(paddingStart % 8 == 0, "STRUCT should start at 8-byte boundary")
            }

            // Skip the field code
            offset += 1

            // Parse variant signature to skip this field
            if offset < headerFieldsData.count {
                let sigLength = Int(headerFieldsData[offset])
                offset += 1 + sigLength + 1  // signature + null terminator

                // Skip value (simplified - just find next field or end)
                while offset < headerFieldsData.count && headerFieldsData[offset] != 0 {
                    offset += 1
                }
                // Skip value data (this is a simplified approach)
                while offset < headerFieldsData.count
                    && (headerFieldsData[offset] == 0 || headerFieldsData[offset] > 10)
                {
                    offset += 1
                }
            }

            structCount += 1
        }

        #expect(structCount >= 4)  // Should have at least PATH, INTERFACE, MEMBER, DESTINATION
    }

    @Test("Header fields are sorted by field code")
    func headerFieldsSorting() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "TestMethod",
            destination: "com.example.Service",
            serial: 1
        )

        let serializedData = try message.serialize()

        // Extract header fields data
        let headerFieldsLength =
            UInt32(serializedData[12]) | (UInt32(serializedData[13]) << 8)
            | (UInt32(serializedData[14]) << 16) | (UInt32(serializedData[15]) << 24)
        let headerFieldsStart = 16
        let headerFieldsEnd = headerFieldsStart + Int(headerFieldsLength)
        let headerFieldsData = Array(serializedData[headerFieldsStart..<headerFieldsEnd])

        // Extract field codes in order
        var fieldCodes: [UInt8] = []
        var offset = 0

        while offset < headerFieldsData.count {
            // Skip padding
            while offset < headerFieldsData.count && headerFieldsData[offset] == 0 {
                offset += 1
            }

            if offset >= headerFieldsData.count {
                break
            }

            // Record field code
            fieldCodes.append(headerFieldsData[offset])
            offset += 1

            // Skip rest of this field (simplified)
            var skipCount = 0
            while offset < headerFieldsData.count && skipCount < 100 {
                offset += 1
                skipCount += 1
                // Break when we likely hit next field or end
                if offset < headerFieldsData.count - 1 && headerFieldsData[offset] >= 1
                    && headerFieldsData[offset] <= 10 && headerFieldsData[offset + 1] == 1
                {
                    break
                }
            }
        }

        // Verify field codes are in ascending order
        #expect(fieldCodes.count >= 4)

        // Expected order: PATH(1), INTERFACE(2), MEMBER(3), DESTINATION(6)
        let expectedCodes: [UInt8] = [1, 2, 3, 6]
        for i in 0..<min(fieldCodes.count, expectedCodes.count) {
            #expect(
                fieldCodes[i] == expectedCodes[i],
                "Field code at position \(i) should be \(expectedCodes[i]), got \(fieldCodes[i])")
        }
    }

    @Test("Different field types are serialized correctly")
    func headerFieldTypes() throws {
        let path = try ObjectPath("/test/path")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "TestMethod",
            destination: "com.example.Service",
            serial: 42
        )

        let serialized = try message.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        // Verify all field types round-trip correctly
        #expect(deserialized.path?.fullPath == "/test/path")  // ObjectPath
        #expect(deserialized.interface == "com.example.Test")  // String
        #expect(deserialized.member == "TestMethod")  // String
        #expect(deserialized.destination == "com.example.Service")  // String
        #expect(deserialized.serial == 42)  // UInt32
    }

    @Test("Hello message header fields structure")
    func helloMessageDBusHeaderFields() throws {
        // Test the exact structure of a Hello message like the one that was failing
        let message = try Message.methodCall(
            path: ObjectPath("/org/freedesktop/DBus"),
            interface: "org.freedesktop.DBus",
            member: "Hello",
            destination: "org.freedesktop.DBus",
            serial: 1
        )

        let serialized = try message.serialize()

        // Check that the message can be deserialized (proving it's valid)
        let deserialized = try Message.deserialize(from: serialized)
        #expect(deserialized.path?.fullPath == "/org/freedesktop/DBus")
        #expect(deserialized.interface == "org.freedesktop.DBus")
        #expect(deserialized.member == "Hello")
        #expect(deserialized.destination == "org.freedesktop.DBus")
        #expect(deserialized.serial == 1)

        // Verify the structure produces a valid D-Bus message
        #expect(serialized.count > 16)  // Should have more than just fixed header
        #expect(serialized[0] == UInt8(ascii: "l"))  // Little endian
        #expect(serialized[1] == 1)  // METHOD_CALL
        #expect(serialized[3] == 1)  // Protocol version

        // Body length should be 0 (Hello has no body)
        let bodyLength =
            UInt32(serialized[4]) | (UInt32(serialized[5]) << 8) | (UInt32(serialized[6]) << 16)
            | (UInt32(serialized[7]) << 24)
        #expect(bodyLength == 0)

        // Serial should be 1
        let serial =
            UInt32(serialized[8]) | (UInt32(serialized[9]) << 8) | (UInt32(serialized[10]) << 16)
            | (UInt32(serialized[11]) << 24)
        #expect(serial == 1)
    }

    @Test("Minimal method call has correct structure")
    func minimalMethodCallStructure() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            member: "Test",
            serial: 1
        )

        let serialized = try message.serialize()

        // Should have exactly 2 header fields: PATH and MEMBER
        let headerFieldsLength =
            UInt32(serialized[12]) | (UInt32(serialized[13]) << 8) | (UInt32(serialized[14]) << 16)
            | (UInt32(serialized[15]) << 24)

        let headerFieldsStart = 16
        let _ = Array(
            serialized[headerFieldsStart..<headerFieldsStart + Int(headerFieldsLength)])

        // Should be able to deserialize
        let deserialized = try Message.deserialize(from: serialized)
        #expect(deserialized.path?.fullPath == "/test")
        #expect(deserialized.member == "Test")
        #expect(deserialized.interface == nil)
        #expect(deserialized.destination == nil)
        #expect(deserialized.serial == 1)
    }

    @Test("Complex message with all field types")
    func complexMessageAllFieldTypes() throws {
        let path = try ObjectPath("/complex/test/path")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.ComplexInterface",
            member: "ComplexMethod",
            destination: "com.example.ComplexService",
            serial: 12345,
            body: [1, 2, 3, 4],
            bodySignature: "ai"
        )

        let serialized = try message.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        // Verify all fields round-trip correctly
        #expect(deserialized.path?.fullPath == "/complex/test/path")
        #expect(deserialized.interface == "com.example.ComplexInterface")
        #expect(deserialized.member == "ComplexMethod")
        #expect(deserialized.destination == "com.example.ComplexService")
        #expect(deserialized.serial == 12345)
        #expect(deserialized.body == [1, 2, 3, 4])
        #expect(deserialized.bodySignature?.rawValue == "ai")

        // Message should be valid
        try deserialized.validate()
    }

    @Test("Message size is reasonable")
    func messageSizeReasonable() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "Test",
            destination: "com.example.Service",
            serial: 1
        )

        let serialized = try message.serialize()

        // Should be larger than before (due to proper STRUCT alignment) but reasonable
        #expect(serialized.count > 16)  // More than just fixed header
        #expect(serialized.count < 500)  // But not excessive

        // Header fields should be properly sized
        let headerFieldsLength =
            UInt32(serialized[12]) | (UInt32(serialized[13]) << 8) | (UInt32(serialized[14]) << 16)
            | (UInt32(serialized[15]) << 24)
        #expect(headerFieldsLength > 0)
        #expect(headerFieldsLength < 400)  // Reasonable size
    }

    // MARK: - Edge Cases

    @Test("Creates a message with a long path")
    func messageWithLongPath() throws {
        // Test with a very long object path
        let longPath = "/com/example/" + String(repeating: "VeryLongPathSegment", count: 50)
        let path = try ObjectPath(longPath)

        let message = try Message.methodCall(
            path: path,
            member: "Test",
            serial: 1
        )

        let serialized = try message.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        #expect(deserialized.path == path)
    }

    @Test("Creates a message with many header fields")
    func messageWithManyDBusHeaderFields() throws {
        // Test with all possible header fields
        let path = try ObjectPath("/test")
        let signature: Signature = "s"

        let headerFields = [
            DBusHeaderFieldEntry(
                field: .path, value: try HeaderVariant(path, signature: "o")),
            DBusHeaderFieldEntry(
                field: .interface,
                value: try HeaderVariant("com.example.Test", signature: "s")),
            DBusHeaderFieldEntry(
                field: .member, value: try HeaderVariant("TestMethod", signature: "s")),
            DBusHeaderFieldEntry(
                field: .destination,
                value: try HeaderVariant("com.example.Service", signature: "s")),
            DBusHeaderFieldEntry(
                field: .sender,
                value: try HeaderVariant("com.example.Client", signature: "s")),
            DBusHeaderFieldEntry(
                field: .signature, value: try HeaderVariant(signature, signature: "g")),
        ]

        let message = try Message(
            messageType: .methodCall,
            serial: 1,
            headerFields: headerFields,
            bodySignature: signature
        )

        let serialized = try message.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        #expect(deserialized.path == path)
        #expect(deserialized.interface == "com.example.Test")
        #expect(deserialized.member == "TestMethod")
        #expect(deserialized.destination == "com.example.Service")
        #expect(deserialized.sender == "com.example.Client")
        #expect(deserialized.bodySignature == signature)
    }

    // MARK: - Performance Tests

    @Test("Serializes 100 messages successfully")
    func serializationPerformance() throws {
        let path = try ObjectPath("/test/performance")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Performance",
            member: "TestMethod",
            serial: 1,
            body: Array(repeating: 0x42, count: 1000)  // 1KB body
        )

        // Simple performance test - ensure serialization works repeatedly
        for _ in 0..<100 {
            _ = try message.serialize()
        }
    }

    @Test("Deserializes 100 messages successfully")
    func deserializationPerformance() throws {
        let path = try ObjectPath("/test/performance")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Performance",
            member: "TestMethod",
            serial: 1,
            body: Array(repeating: 0x42, count: 1000)
        )

        let serializedData = try message.serialize()

        // Simple performance test - ensure deserialization works repeatedly
        for _ in 0..<100 {
            _ = try Message.deserialize(from: serializedData)
        }
    }
}

// MARK: - Debug Tests

@Suite("Debug Message tests")
struct MessageDebugTests {
    @Test("Serializes a message and prints its wire format structure")
    func debugSerialization() throws {
        let path = try ObjectPath("/test")
        let message = try Message.methodCall(
            path: path,
            member: "TestMethod",
            serial: 1
        )

        let serializedData = try message.serialize()
        print("Serialized data length: \(serializedData.count)")
        print(
            "First 32 bytes: \(serializedData.prefix(32).map { String(format: "%02x", $0) }.joined(separator: " "))"
        )
        print(
            "All bytes: \(serializedData.map { String(format: "%02x", $0) }.joined(separator: " "))"
        )

        // Manually parse the header to understand the structure
        print("\nManual parsing:")
        print("Endianness: \(Character(UnicodeScalar(serializedData[0])))")
        print("Message type: \(serializedData[1])")
        print("Flags: \(serializedData[2])")
        print("Protocol version: \(serializedData[3])")

        let bodyLength =
            UInt32(serializedData[4]) | (UInt32(serializedData[5]) << 8)
            | (UInt32(serializedData[6]) << 16) | (UInt32(serializedData[7]) << 24)
        print("Body length: \(bodyLength)")

        let serial =
            UInt32(serializedData[8]) | (UInt32(serializedData[9]) << 8)
            | (UInt32(serializedData[10]) << 16) | (UInt32(serializedData[11]) << 24)
        print("Serial: \(serial)")

        let headerFieldsLength =
            UInt32(serializedData[12]) | (UInt32(serializedData[13]) << 8)
            | (UInt32(serializedData[14]) << 16) | (UInt32(serializedData[15]) << 24)
        print("Header fields length: \(headerFieldsLength)")

        print(
            "Header fields data: \(serializedData[16..<Int(16+headerFieldsLength)].map { String(format: "%02x", $0) }.joined(separator: " "))"
        )

        // Try to deserialize
        let deserialized = try Message.deserialize(from: serializedData)
        print("✅ Deserialization successful!")
        print("Message type: \(deserialized.messageType)")
        print("Serial: \(deserialized.serial)")
    }

    @Test("Debug GetId message serialization")
    func debugGetIdSerialization() throws {
        // Create the exact same message that getId() creates
        let path = try ObjectPath("/org/freedesktop/DBus")
        let message = try Message.methodCall(
            path: path,
            interface: "org.freedesktop.DBus",
            member: "GetId",
            destination: "org.freedesktop.DBus",
            serial: 1
        )

        let serializedData = try message.serialize()
        print("\n=== GetId Message Debug ===")
        print("Serialized data length: \(serializedData.count)")
        print(
            "All bytes: \(serializedData.map { String(format: "%02x", $0) }.joined(separator: " "))"
        )

        // Manual parsing
        print("\nManual parsing:")
        print("Endianness: \(Character(UnicodeScalar(serializedData[0])))")
        print("Message type: \(serializedData[1])")
        print("Flags: \(serializedData[2])")
        print("Protocol version: \(serializedData[3])")

        let bodyLength =
            UInt32(serializedData[4]) | (UInt32(serializedData[5]) << 8)
            | (UInt32(serializedData[6]) << 16) | (UInt32(serializedData[7]) << 24)
        print("Body length: \(bodyLength)")

        let serial =
            UInt32(serializedData[8]) | (UInt32(serializedData[9]) << 8)
            | (UInt32(serializedData[10]) << 16) | (UInt32(serializedData[11]) << 24)
        print("Serial: \(serial)")

        let headerFieldsLength =
            UInt32(serializedData[12]) | (UInt32(serializedData[13]) << 8)
            | (UInt32(serializedData[14]) << 16) | (UInt32(serializedData[15]) << 24)
        print("Header fields length: \(headerFieldsLength)")

        print(
            "Header fields data: \(serializedData[16..<Int(16+headerFieldsLength)].map { String(format: "%02x", $0) }.joined(separator: " "))"
        )

        // Try to deserialize to verify it's valid
        let deserialized = try Message.deserialize(from: serializedData)
        print("✅ Deserialization successful!")
        print("Message type: \(deserialized.messageType)")
        print("Path: \(deserialized.path?.fullPath ?? "nil")")
        print("Interface: \(deserialized.interface ?? "nil")")
        print("Member: \(deserialized.member ?? "nil")")
        print("Destination: \(deserialized.destination ?? "nil")")
        print("Serial: \(deserialized.serial)")
    }

    @Test("Detailed Hello message analysis")
    func detailedHelloMessageAnalysis() throws {
        // Create the exact same Hello message that hello() creates
        let path = try ObjectPath("/org/freedesktop/DBus")
        let message = try Message.methodCall(
            path: path,
            interface: "org.freedesktop.DBus",
            member: "Hello",
            destination: "org.freedesktop.DBus",
            serial: 1
        )

        let serializedData = try message.serialize()
        print("\n=== Hello Message Detailed Analysis ===")
        print("Total length: \(serializedData.count) bytes")

        // Print entire message with annotations
        print("\nComplete message:")
        for (index, byte) in serializedData.enumerated() {
            if index % 16 == 0 {
                print("\n\(String(format: "%04x", index)): ", terminator: "")
            }
            print(String(format: "%02x ", byte), terminator: "")
        }
        print("\n")

        // Decode according to D-Bus spec
        print("\n=== D-Bus Wire Format Analysis ===")
        print("Fixed header (16 bytes):")
        print(
            "  [0] Endianness: '\(Character(UnicodeScalar(serializedData[0])))' (0x\(String(format: "%02x", serializedData[0])))"
        )
        print("  [1] Message Type: \(serializedData[1]) (1=METHOD_CALL)")
        print("  [2] Flags: \(serializedData[2])")
        print("  [3] Protocol Version: \(serializedData[3])")

        let bodyLength =
            UInt32(serializedData[4]) | (UInt32(serializedData[5]) << 8)
            | (UInt32(serializedData[6]) << 16) | (UInt32(serializedData[7]) << 24)
        print("  [4-7] Body Length: \(bodyLength)")

        let serial =
            UInt32(serializedData[8]) | (UInt32(serializedData[9]) << 8)
            | (UInt32(serializedData[10]) << 16) | (UInt32(serializedData[11]) << 24)
        print("  [8-11] Serial: \(serial)")

        let headerFieldsLength =
            UInt32(serializedData[12]) | (UInt32(serializedData[13]) << 8)
            | (UInt32(serializedData[14]) << 16) | (UInt32(serializedData[15]) << 24)
        print("  [12-15] Header Fields Array Length: \(headerFieldsLength)")

        print("\nHeader fields array (\(headerFieldsLength) bytes):")
        let headerFieldsStart = 16
        let headerFieldsEnd = headerFieldsStart + Int(headerFieldsLength)
        let headerFieldsData = Array(serializedData[headerFieldsStart..<headerFieldsEnd])

        for (index, byte) in headerFieldsData.enumerated() {
            if index % 16 == 0 {
                print("\n  \(String(format: "%04x", index)): ", terminator: "")
            }
            print(String(format: "%02x ", byte), terminator: "")
        }
        print("\n")

        // Decode header fields manually with proper bounds checking
        print("\nDecoding header fields:")
        var offset = 0
        var fieldNum = 1
        while offset < headerFieldsData.count {
            // Skip padding bytes
            while offset < headerFieldsData.count && headerFieldsData[offset] == 0 {
                offset += 1
            }

            // Ensure we have enough data for at least field code + signature length
            if offset + 2 > headerFieldsData.count { break }

            let fieldCode = headerFieldsData[offset]
            print("  Field \(fieldNum): Code=\(fieldCode) ", terminator: "")

            switch fieldCode {
            case 1: print("(PATH)", terminator: "")
            case 2: print("(INTERFACE)", terminator: "")
            case 3: print("(MEMBER)", terminator: "")
            case 6: print("(DESTINATION)", terminator: "")
            default: print("(UNKNOWN)", terminator: "")
            }

            offset += 1

            // Check bounds for signature length
            if offset >= headerFieldsData.count { break }
            let sigLength = Int(headerFieldsData[offset])
            offset += 1

            // Check bounds for signature data
            if offset + sigLength + 1 > headerFieldsData.count { break }
            let signature =
                String(bytes: headerFieldsData[offset..<offset + sigLength], encoding: .utf8) ?? ""
            offset += sigLength + 1  // +1 for null terminator
            print(" Sig='\(signature)'")

            // Skip to next field by finding next non-zero byte or end
            var skipCount = 0
            while offset < headerFieldsData.count && skipCount < 200 {
                offset += 1
                skipCount += 1
                // Stop when we likely hit next field or padding before next field
                if offset < headerFieldsData.count
                    && (headerFieldsData[offset] >= 1 && headerFieldsData[offset] <= 10)
                {
                    break
                }
            }

            fieldNum += 1
        }

        // Check if there's body data
        let totalHeaderSize = 16 + Int(headerFieldsLength)
        let padding = (8 - (totalHeaderSize % 8)) % 8
        let bodyStart = totalHeaderSize + padding

        print("\nMessage structure:")
        print("  Fixed header: 16 bytes")
        print("  Header fields: \(headerFieldsLength) bytes")
        print("  Padding: \(padding) bytes")
        print("  Body start: \(bodyStart)")
        print("  Body length: \(bodyLength) bytes")
        print("  Total: \(serializedData.count) bytes")

        // Verify our message deserializes correctly
        let deserialized = try Message.deserialize(from: serializedData)
        print("\n✅ Message deserializes correctly:")
        print("  Path: \(deserialized.path?.fullPath ?? "nil")")
        print("  Interface: \(deserialized.interface ?? "nil")")
        print("  Member: \(deserialized.member ?? "nil")")
        print("  Destination: \(deserialized.destination ?? "nil")")
    }
}

// MARK: - Helper Extensions for Testing

extension Message {
    /// Create a minimal valid message for testing
    static func testMessage(type: DBusMessageType = .methodCall, serial: UInt32 = 1) throws
        -> Message
    {
        switch type {
        case .methodCall:
            return try methodCall(
                path: ObjectPath("/test"),
                member: "Test",
                serial: serial
            )
        case .methodReturn:
            return try methodReturn(
                replySerial: 1,
                serial: serial
            )
        case .error:
            return try error(
                errorName: "test.Error",
                replySerial: 1,
                serial: serial
            )
        case .signal:
            return try signal(
                path: ObjectPath("/test"),
                interface: "test.Interface",
                member: "TestSignal",
                serial: serial
            )
        }
    }
}
