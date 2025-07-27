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

@Suite("Endianness tests") struct EndiannessTests {
    // MARK: - Basic Endianness Tests

    @Test func endiannessEnumValues() {
        // Test that the enum has the expected cases
        let littleEndian = Endianness.littleEndian
        let bigEndian = Endianness.bigEndian

        #expect(littleEndian != bigEndian)
    }

    // MARK: - Deserializer Endianness Tests

    @Test func deserializerLittleEndianUInt16() throws {
        // Test little-endian UInt16: 0x1234 should be stored as [0x34, 0x12]
        let data: [UInt8] = [0x34, 0x12]
        let signature = Signature("q")  // UInt16

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        let result: UInt16 = try deserializer.unserialize()

        #expect(result == 0x1234)
    }

    @Test func deserializerBigEndianUInt16() throws {
        // Test big-endian UInt16: 0x1234 should be stored as [0x12, 0x34]
        let data: [UInt8] = [0x12, 0x34]
        let signature = Signature("q")  // UInt16

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .bigEndian)
        let result: UInt16 = try deserializer.unserialize()

        #expect(result == 0x1234)
    }

    @Test func deserializerLittleEndianUInt32() throws {
        // Test little-endian UInt32: 0x12345678 should be stored as [0x78, 0x56, 0x34, 0x12]
        let data: [UInt8] = [0x78, 0x56, 0x34, 0x12]
        let signature = Signature("u")  // UInt32

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        let result: UInt32 = try deserializer.unserialize()

        #expect(result == 0x1234_5678)
    }

    @Test func deserializerBigEndianUInt32() throws {
        // Test big-endian UInt32: 0x12345678 should be stored as [0x12, 0x34, 0x56, 0x78]
        let data: [UInt8] = [0x12, 0x34, 0x56, 0x78]
        let signature = Signature("u")  // UInt32

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .bigEndian)
        let result: UInt32 = try deserializer.unserialize()

        #expect(result == 0x1234_5678)
    }

    @Test func deserializerLittleEndianUInt64() throws {
        // Test little-endian UInt64: 0x123456789ABCDEF0 should be stored as [0xF0, 0xDE, 0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12]
        let data: [UInt8] = [0xF0, 0xDE, 0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12]
        let signature = Signature("t")  // UInt64

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        let result: UInt64 = try deserializer.unserialize()

        #expect(result == 0x1234_5678_9ABC_DEF0)
    }

    @Test func deserializerBigEndianUInt64() throws {
        // Test big-endian UInt64: 0x123456789ABCDEF0 should be stored as [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0]
        let data: [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0]
        let signature = Signature("t")  // UInt64

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .bigEndian)
        let result: UInt64 = try deserializer.unserialize()

        #expect(result == 0x1234_5678_9ABC_DEF0)
    }

    // MARK: - Message Endianness Tests

    @Test func dBusMessageLittleEndianSerialization() throws {
        let message = try Message(
            endianness: .littleEndian,
            messageType: .methodCall,
            serial: 0x1234_5678,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path,
                    value: try HeaderVariant(ObjectPath("/test/path"), signature: "o")),
                DBusHeaderFieldEntry(
                    field: .interface,
                    value: try HeaderVariant("com.example.Test", signature: "s")),
                DBusHeaderFieldEntry(
                    field: .member,
                    value: try HeaderVariant("TestMethod", signature: "s")),
            ]
        )

        let serialized = try message.serialize()

        // Check endianness marker
        #expect(serialized[0] == UInt8(ascii: "l"))

        // Check serial (should be little-endian: 0x78, 0x56, 0x34, 0x12)
        let serialBytes = Array(serialized[8..<12])
        #expect(serialBytes == [0x78, 0x56, 0x34, 0x12])
    }

    @Test func dBusMessageBigEndianSerialization() throws {
        let message = try Message(
            endianness: .bigEndian,
            messageType: .methodCall,
            serial: 0x1234_5678,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path,
                    value: try HeaderVariant(ObjectPath("/test/path"), signature: "o")),
                DBusHeaderFieldEntry(
                    field: .interface,
                    value: try HeaderVariant("com.example.Test", signature: "s")),
                DBusHeaderFieldEntry(
                    field: .member,
                    value: try HeaderVariant("TestMethod", signature: "s")),
            ]
        )

        let serialized = try message.serialize()

        // Check endianness marker
        #expect(serialized[0] == UInt8(ascii: "B"))

        // Check serial (should be big-endian: 0x12, 0x34, 0x56, 0x78)
        let serialBytes = Array(serialized[8..<12])
        #expect(serialBytes == [0x12, 0x34, 0x56, 0x78])
    }

    // MARK: - Round-trip Tests

    @Test func littleEndianRoundTrip() throws {
        let originalMessage = try Message(
            endianness: .littleEndian,
            messageType: .methodCall,
            serial: 0xDEAD_BEEF,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path,
                    value: try HeaderVariant(ObjectPath("/com/example/Test"), signature: "o")),
                DBusHeaderFieldEntry(
                    field: .interface,
                    value: try HeaderVariant("com.example.TestInterface", signature: "s")
                ),
                DBusHeaderFieldEntry(
                    field: .member,
                    value: try HeaderVariant("TestMethod", signature: "s")),
            ]
        )

        let serialized = try originalMessage.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        #expect(deserialized.endianness == .littleEndian)
        #expect(deserialized.serial == 0xDEAD_BEEF)
        #expect(deserialized.messageType == .methodCall)
    }

    @Test func bigEndianRoundTrip() throws {
        let originalMessage = try Message(
            endianness: .bigEndian,
            messageType: .methodCall,
            serial: 0xDEAD_BEEF,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path,
                    value: try HeaderVariant(ObjectPath("/com/example/Test"), signature: "o")),
                DBusHeaderFieldEntry(
                    field: .interface,
                    value: try HeaderVariant("com.example.TestInterface", signature: "s")
                ),
                DBusHeaderFieldEntry(
                    field: .member,
                    value: try HeaderVariant("TestMethod", signature: "s")),
            ]
        )

        let serialized = try originalMessage.serialize()
        let deserialized = try Message.deserialize(from: serialized)

        #expect(deserialized.endianness == .bigEndian)
        #expect(deserialized.serial == 0xDEAD_BEEF)
        #expect(deserialized.messageType == .methodCall)
    }

    // MARK: - Edge Cases

    @Test func endiannessMismatchDetection() throws {
        // Create data with little-endian marker but big-endian values
        var data: [UInt8] = []
        data.append(UInt8(ascii: "l"))  // little-endian marker
        data.append(1)  // method call
        data.append(0)  // no flags
        data.append(1)  // protocol version
        data.append(contentsOf: [0, 0, 0, 0])  // body length (0)
        data.append(contentsOf: [0x12, 0x34, 0x56, 0x78])  // serial in big-endian format

        // This should still work because we parse according to the endianness marker
        // The serial should be interpreted as little-endian: 0x78563412
        data.append(contentsOf: [0, 0, 0, 0])  // empty header fields

        // Pad to 8-byte boundary
        while data.count % 8 != 0 {
            data.append(0)
        }

        let message = try Message.deserialize(from: data)
        #expect(message.endianness == .littleEndian)
        #expect(message.serial == 0x7856_3412)  // Interpreted as little-endian
    }

    @Test func invalidEndiannessMarker() {
        let data: [UInt8] = [UInt8(ascii: "X")] + Array(repeating: 0, count: 19)

        #expect(throws: DBusMessageError.invalidEndianness) {
            try Message.deserialize(from: data)
        }
    }

    // MARK: - Message Serialization Endianness Bug Test

    @Test func serializationRespectsEndianness() throws {
        // This test specifically checks that serialization respects the message's endianness
        // Currently, there's a bug where serialization always uses little-endian regardless
        // of the message's endianness setting

        let littleEndianMessage = try Message(
            endianness: .littleEndian,
            messageType: .methodCall,
            serial: 0x1234_5678,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path,
                    value: try HeaderVariant(ObjectPath("/test"), signature: "o"))
            ]
        )

        let bigEndianMessage = try Message(
            endianness: .bigEndian,
            messageType: .methodCall,
            serial: 0x1234_5678,
            headerFields: [
                DBusHeaderFieldEntry(
                    field: .path,
                    value: try HeaderVariant(ObjectPath("/test"), signature: "o"))
            ]
        )

        let littleEndianSerialized = try littleEndianMessage.serialize()
        let bigEndianSerialized = try bigEndianMessage.serialize()

        // Check endianness markers
        #expect(littleEndianSerialized[0] == UInt8(ascii: "l"))
        #expect(bigEndianSerialized[0] == UInt8(ascii: "B"))

        // Check that multi-byte values are serialized differently
        let littleEndianSerial = Array(littleEndianSerialized[8..<12])
        let bigEndianSerial = Array(bigEndianSerialized[8..<12])

        // These should be different if endianness is respected
        #expect(littleEndianSerial == [0x78, 0x56, 0x34, 0x12])
        #expect(bigEndianSerial == [0x12, 0x34, 0x56, 0x78])
        #expect(littleEndianSerial != bigEndianSerial)
    }
}
