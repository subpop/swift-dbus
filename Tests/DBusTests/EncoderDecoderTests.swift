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

@Suite("Encoder decoder tests") struct EncoderDecoderTests {
    @Test func explicitSignatureEncoding() throws {
        let encoder = DBusEncoder()

        // Test encoding with explicit signatures

        // Test Bool (signature: b)
        let boolValue = true
        let boolData = try encoder.encode(boolValue, signature: "b")
        #expect(!boolData.isEmpty, "Encoded bool data should not be empty")

        // Test String (signature: s)
        let stringValue = "Hello D-Bus"
        let stringData = try encoder.encode(stringValue, signature: "s")
        #expect(!stringData.isEmpty, "Encoded string data should not be empty")

        // Test Int32 (signature: i)
        let int32Value: Int32 = 42
        let int32Data = try encoder.encode(int32Value, signature: "i")
        #expect(!int32Data.isEmpty, "Encoded int32 data should not be empty")
    }

    @Test func simpleTypeEncoding() throws {
        let encoder = DBusEncoder()

        // Test basic types with automatic signature inference

        // Test Bool (signature: b)
        let boolValue = true
        let boolData = try encoder.encode(boolValue)
        #expect(!boolData.isEmpty, "Encoded bool data should not be empty")

        // Test String (signature: s)
        let stringValue = "Hello D-Bus"
        let stringData = try encoder.encode(stringValue)
        #expect(!stringData.isEmpty, "Encoded string data should not be empty")

        // Test Int32 (signature: i)
        let int32Value: Int32 = 42
        let int32Data = try encoder.encode(int32Value)
        #expect(!int32Data.isEmpty, "Encoded int32 data should not be empty")
    }

    @Test func manualSignatureDecoding() throws {
        let decoder = DBusDecoder()

        // Create a manual Serializer to generate test data
        let boolSignature: Signature = "b"
        var serializer = Serializer(signature: boolSignature)
        try serializer.serialize(true)
        guard let boolData = serializer.data else {
            Issue.record("Failed to serialize bool")
            return
        }

        // Test decoding with manual signature
        let decodedBool = try decoder.decode(Bool.self, from: boolData, signature: boolSignature)
        #expect(decodedBool == true, "Decoded bool should match original")

        // Test string
        let stringSignature: Signature = "s"
        var stringSerializer = Serializer(signature: stringSignature)
        let originalString = "Hello D-Bus"
        try stringSerializer.serialize(originalString)
        guard let stringData = stringSerializer.data else {
            Issue.record("Failed to serialize string")
            return
        }

        let decodedString = try decoder.decode(
            String.self, from: stringData, signature: stringSignature)
        #expect(decodedString == originalString, "Decoded string should match original")

        // Test int32
        let int32Signature: Signature = "i"
        var int32Serializer = Serializer(signature: int32Signature)
        let originalInt32: Int32 = 42
        try int32Serializer.serialize(originalInt32)
        guard let int32Data = int32Serializer.data else {
            Issue.record("Failed to serialize int32")
            return
        }

        let decodedInt32 = try decoder.decode(
            Int32.self, from: int32Data, signature: int32Signature)
        #expect(decodedInt32 == originalInt32, "Decoded int32 should match original")
    }

    @Test func structEncodingDecoding() throws {
        // Define a simple struct that can be encoded/decoded
        struct Person: Codable {
            let name: String
            let age: Int32
        }

        let encoder = DBusEncoder()
        let decoder = DBusDecoder()
        let originalPerson = Person(name: "Alice", age: 30)

        // Encode using explicit signature
        let structSignature = "(si)"  // struct with string and int32
        let encodedData = try encoder.encode(originalPerson, signature: structSignature)

        #expect(!encodedData.isEmpty, "Encoded struct data should not be empty")

        // Test decoding
        let decodedPerson = try decoder.decode(
            Person.self, from: encodedData, signature: structSignature)

        #expect(decodedPerson.name == originalPerson.name, "Decoded name should match")
        #expect(decodedPerson.age == originalPerson.age, "Decoded age should match")
    }

    @Test func structDecoding() throws {
        // Define a simple struct that can be encoded/decoded
        struct Person: Codable {
            let name: String
            let age: Int32
        }

        // Create test data using manual serialization
        let structSignature: Signature = "(si)"  // struct with string and int32
        var serializer = Serializer(signature: structSignature)

        let originalPerson = Person(name: "Alice", age: 30)

        try serializer.serialize { structSerializer in
            try structSerializer.serialize(originalPerson.name)
            try structSerializer.serialize(originalPerson.age)
        }

        guard let structData = serializer.data else {
            Issue.record("Failed to serialize struct")
            return
        }

        // Test decoding
        let decoder = DBusDecoder()
        let decodedPerson = try decoder.decode(
            Person.self, from: structData, signature: structSignature)

        #expect(decodedPerson.name == originalPerson.name, "Decoded name should match")
        #expect(decodedPerson.age == originalPerson.age, "Decoded age should match")
    }

    @Test func arrayDecoding() throws {
        // Test array of integers
        let arraySignature: Signature = "ai"  // array of int32
        var serializer = Serializer(signature: arraySignature)

        let originalArray: [Int32] = [1, 2, 3, 4, 5]
        try serializer.serialize(originalArray)

        guard let arrayData = serializer.data else {
            Issue.record("Failed to serialize array")
            return
        }

        let decoder = DBusDecoder()
        let decodedArray = try decoder.decode(
            [Int32].self, from: arrayData, signature: arraySignature)

        #expect(decodedArray == originalArray, "Decoded array should match original")
    }

    @Test func invalidSignature() throws {
        let decoder = DBusDecoder()
        let data: [UInt8] = [0x00, 0x00, 0x00, 0x01]  // Some arbitrary data

        // Test with invalid signature string
        do {
            _ = try decoder.decode(Bool.self, from: data, signature: "invalid_signature")
            Issue.record("Should have thrown an error for invalid signature")
        } catch let error as DecodingError {
            if case .dataCorrupted(let context) = error {
                #expect(context.debugDescription.contains("Invalid D-Bus signature"))
            } else {
                Issue.record("Expected dataCorrupted error, got: \(error)")
            }
        }
    }

    @Test func dictionaryDecoding() throws {
        let dictionarySignature: Signature = "a{sv}"
        var serializer = Serializer(signature: dictionarySignature)

        let originalDictionary: [String: Variant] = [
            "key1": Variant(value: .string("value1"), signature: "s"),
            "key2": Variant(value: .uint32(42), signature: "u"),
        ]
        try serializer.serialize(originalDictionary)

        guard let dictionaryData = serializer.data else {
            Issue.record("Failed to serialize dictionary")
            return
        }

        let decoder = DBusDecoder()
        let decodedDictionary = try decoder.decode(
            [String: Variant].self, from: dictionaryData, signature: dictionarySignature)

        #expect(
            decodedDictionary.count == originalDictionary.count,
            "Decoded dictionary should have the same number of elements")
    }

    @Test func simpleDbusVariantEncodingDecoding() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test various DBusVariant types with round-trip encoding/decoding
        let testCases: [(Variant, String)] = [
            // Basic types
            (Variant(value: .byte(255), signature: "y"), "Byte variant"),
            (Variant(value: .bool(true), signature: "b"), "Bool variant (true)"),
            (Variant(value: .bool(false), signature: "b"), "Bool variant (false)"),
            (Variant(value: .int16(-32768), signature: "n"), "Int16 variant"),
            (Variant(value: .uint16(65535), signature: "q"), "UInt16 variant"),
            (Variant(value: .int32(-2_147_483_648), signature: "i"), "Int32 variant"),
            (Variant(value: .uint32(4_294_967_295), signature: "u"), "UInt32 variant"),
            (
                Variant(value: .int64(-9_223_372_036_854_775_808), signature: "x"),
                "Int64 variant"
            ),
            (
                Variant(value: .uint64(18_446_744_073_709_551_615), signature: "t"),
                "UInt64 variant"
            ),
            (Variant(value: .double(3.14159), signature: "d"), "Double variant"),
            (Variant(value: .string("Hello D-Bus"), signature: "s"), "String variant"),
            (Variant(value: .string(""), signature: "s"), "Empty string variant"),
            (
                Variant(value: .string("Unicode: 🚀 世界"), signature: "s"),
                "Unicode string variant"
            ),

            // Object path and signature types
            (
                Variant(
                    value: .objectPath(try ObjectPath("/org/freedesktop/DBus")), signature: "o"),
                "ObjectPath variant"
            ),
            (Variant(value: .signature(Signature("ai")), signature: "g"), "Signature variant"),
        ]

        for (originalVariant, description) in testCases {
            // Test encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(!encodedData.isEmpty, "Encoded data should not be empty for: \(description)")

            // Test decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for: \(description)")
            #expect(
                decodedVariant.value == originalVariant.value,
                "Decoded value should match original for: \(description)")
            #expect(
                decodedVariant == originalVariant,
                "Decoded variant should equal original for: \(description)")
        }
    }
}
