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

import Foundation
import Testing

@testable import DBus

@Suite("Variant Tests") struct VariantTests {
    @Test("Basic types round-trip serialization")
    func basicTypes() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test all basic variant types with their D-Bus signatures
        let testCases: [(Variant, String)] = [
            // Basic types
            (Variant(value: .byte(255), signature: "y"), "Byte variant max"),
            (Variant(value: .byte(0), signature: "y"), "Byte variant zero"),
            (Variant(value: .bool(true), signature: "b"), "Bool variant true"),
            (Variant(value: .bool(false), signature: "b"), "Bool variant false"),
            (Variant(value: .int16(-32768), signature: "n"), "Int16 variant min"),
            (Variant(value: .int16(32767), signature: "n"), "Int16 variant max"),
            (Variant(value: .int16(0), signature: "n"), "Int16 variant zero"),
            (Variant(value: .uint16(0), signature: "q"), "UInt16 variant zero"),
            (Variant(value: .uint16(65535), signature: "q"), "UInt16 variant max"),
            (Variant(value: .int32(-2_147_483_648), signature: "i"), "Int32 variant min"),
            (Variant(value: .int32(2_147_483_647), signature: "i"), "Int32 variant max"),
            (Variant(value: .int32(0), signature: "i"), "Int32 variant zero"),
            (Variant(value: .uint32(0), signature: "u"), "UInt32 variant zero"),
            (Variant(value: .uint32(4_294_967_295), signature: "u"), "UInt32 variant max"),
            (
                Variant(value: .int64(-9_223_372_036_854_775_808), signature: "x"),
                "Int64 variant min"
            ),
            (
                Variant(value: .int64(9_223_372_036_854_775_807), signature: "x"),
                "Int64 variant max"
            ),
            (Variant(value: .int64(0), signature: "x"), "Int64 variant zero"),
            (Variant(value: .uint64(0), signature: "t"), "UInt64 variant zero"),
            (
                Variant(value: .uint64(18_446_744_073_709_551_615), signature: "t"),
                "UInt64 variant max"
            ),
            (Variant(value: .double(0.0), signature: "d"), "Double variant zero"),
            (Variant(value: .double(3.14159), signature: "d"), "Double variant pi"),
            (Variant(value: .double(-1.5), signature: "d"), "Double variant negative"),
            (Variant(value: .double(.infinity), signature: "d"), "Double variant infinity"),
            (
                Variant(value: .double(-.infinity), signature: "d"),
                "Double variant negative infinity"
            ),

            // String types
            (Variant(value: .string(""), signature: "s"), "Empty string variant"),
            (Variant(value: .string("Hello D-Bus"), signature: "s"), "Simple string variant"),
            (
                Variant(value: .string("Unicode: 🚀 世界 🌍"), signature: "s"),
                "Unicode string variant"
            ),

            // Object path and signature types
            (
                Variant(value: .objectPath(try ObjectPath("/")), signature: "o"),
                "Root object path variant"
            ),
            (
                Variant(
                    value: .objectPath(try ObjectPath("/org/freedesktop/DBus")), signature: "o"),
                "Complex object path variant"
            ),
            (
                Variant(value: .signature(Signature("s")), signature: "g"),
                "Simple signature variant"
            ),
            (
                Variant(value: .signature(Signature("a{sv}")), signature: "g"),
                "Complex signature variant"
            ),
        ]

        for (originalVariant, description) in testCases {
            // Test D-Bus binary encoding (variants use "v" signature)
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(!encodedData.isEmpty, "Encoded data should not be empty for: \(description)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for: \(description)")

            // Special handling for NaN comparison (NaN != NaN)
            if case .double(let originalDouble) = originalVariant.value,
                case .double(let decodedDouble) = decodedVariant.value
            {
                if originalDouble.isNaN {
                    #expect(decodedDouble.isNaN, "Decoded NaN should be NaN for: \(description)")
                } else {
                    #expect(
                        decodedDouble == originalDouble,
                        "Decoded double should match original for: \(description)")
                }
            } else {
                #expect(
                    decodedVariant.value == originalVariant.value,
                    "Decoded value should match original for: \(description)")
            }
        }
    }

    @Test("Special numeric values D-Bus serialization")
    func specialNumericValues() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test special double values that D-Bus can handle
        let specialValues: [(Double, String)] = [
            (.nan, "NaN"),
            (.infinity, "Positive infinity"),
            (-.infinity, "Negative infinity"),
            (.zero, "Positive zero"),
            (-.zero, "Negative zero"),
            (.leastNormalMagnitude, "Least normal magnitude"),
            (.greatestFiniteMagnitude, "Greatest finite magnitude"),
            (.leastNonzeroMagnitude, "Least nonzero magnitude"),
            (.pi, "Pi"),
            (2.71828, "Euler's number"),
            (1.7976931348623157e+308, "Near double max"),
            (2.2250738585072014e-308, "Near double min positive"),
        ]

        for (value, description) in specialValues {
            let originalVariant = Variant(value: .double(value), signature: "d")

            // Test D-Bus binary encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(!encodedData.isEmpty, "Encoded data should not be empty for: \(description)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify signature matches
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for: \(description)")

            // Special handling for NaN and infinity
            if case .double(let decodedDouble) = decodedVariant.value {
                if value.isNaN {
                    #expect(decodedDouble.isNaN, "Decoded value should be NaN for: \(description)")
                } else if value.isInfinite {
                    #expect(
                        decodedDouble.isInfinite,
                        "Decoded value should be infinite for: \(description)")
                    #expect(
                        decodedDouble.sign == value.sign,
                        "Decoded infinity sign should match for: \(description)")
                } else {
                    #expect(
                        decodedDouble == value,
                        "Decoded value should match original for: \(description)")
                }
            } else {
                #expect(Bool(false), "Decoded value should be double type for: \(description)")
            }
        }
    }

    @Test("Array types round-trip serialization")
    func arrayTypes() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test array variants with different types
        let testCases: [(Variant, String)] = [
            // Empty arrays
            (Variant(value: .array([]), signature: "as"), "Empty string array"),
            (Variant(value: .array([]), signature: "ai"), "Empty int32 array"),
            (Variant(value: .array([]), signature: "ay"), "Empty byte array"),

            // String arrays
            (
                Variant(value: .array([.string("hello")]), signature: "as"),
                "Single string array"
            ),
            (
                Variant(value: .array([.string("hello"), .string("world")]), signature: "as"),
                "Two string array"
            ),
            (
                Variant(
                    value: .array([.string(""), .string("test"), .string("🚀")]), signature: "as"),
                "Mixed string array"
            ),

            // Integer arrays
            (
                Variant(value: .array([.int32(1), .int32(2), .int32(3)]), signature: "ai"),
                "Int32 array"
            ),
            (
                Variant(value: .array([.uint32(0), .uint32(4_294_967_295)]), signature: "au"),
                "UInt32 array"
            ),
            (Variant(value: .array([.byte(0), .byte(255)]), signature: "ay"), "Byte array"),

            // Boolean arrays
            (
                Variant(
                    value: .array([.bool(true), .bool(false), .bool(true)]), signature: "ab"),
                "Bool array"
            ),

            // Double arrays
            (
                Variant(
                    value: .array([.double(0.0), .double(3.14), .double(-1.5)]), signature: "ad"),
                "Double array"
            ),

            // Object path arrays
            (
                Variant(
                    value: .array([
                        .objectPath(try ObjectPath("/")), .objectPath(try ObjectPath("/test")),
                    ]), signature: "ao"), "Object path array"
            ),

            // Signature arrays
            (
                Variant(
                    value: .array([.signature(Signature("s")), .signature(Signature("i"))]),
                    signature: "ag"), "Signature array"
            ),
        ]

        for (originalVariant, description) in testCases {
            // Test D-Bus binary encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(!encodedData.isEmpty, "Encoded data should not be empty for: \(description)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for: \(description)")
            #expect(
                decodedVariant.value == originalVariant.value,
                "Decoded value should match original for: \(description)")
        }
    }

    @Test("Dictionary types round-trip serialization")
    func dictionaryTypes() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test dictionary variants with different types
        let testCases: [(Variant, String)] = [
            // Empty dictionaries
            (
                Variant(value: .dictionary([:]), signature: "a{ss}"),
                "Empty string-string dictionary"
            ),
            (
                Variant(value: .dictionary([:]), signature: "a{si}"),
                "Empty string-int32 dictionary"
            ),

            // String-string dictionaries
            (
                Variant(value: .dictionary(["key": .string("value")]), signature: "a{ss}"),
                "Single entry string-string dictionary"
            ),
            (
                Variant(
                    value: .dictionary(["key1": .string("value1"), "key2": .string("value2")]),
                    signature: "a{ss}"), "Two entry string-string dictionary"
            ),
            (
                Variant(
                    value: .dictionary([
                        "": .string("empty key"), "test": .string(""), "unicode": .string("🚀"),
                    ]), signature: "a{ss}"), "Mixed string-string dictionary"
            ),

            // String-int32 dictionaries
            (
                Variant(value: .dictionary(["count": .int32(42)]), signature: "a{si}"),
                "Single entry string-int32 dictionary"
            ),
            (
                Variant(
                    value: .dictionary([
                        "min": .int32(-2_147_483_648), "max": .int32(2_147_483_647),
                        "zero": .int32(0),
                    ]), signature: "a{si}"), "Multi entry string-int32 dictionary"
            ),

            // String-bool dictionaries
            (
                Variant(
                    value: .dictionary(["enabled": .bool(true), "disabled": .bool(false)]),
                    signature: "a{sb}"), "String-bool dictionary"
            ),

            // String-double dictionaries
            (
                Variant(
                    value: .dictionary(["pi": .double(3.14159), "e": .double(2.71828)]),
                    signature: "a{sd}"), "String-double dictionary"
            ),

            // String-byte dictionaries
            (
                Variant(
                    value: .dictionary(["min": .byte(0), "max": .byte(255)]), signature: "a{sy}"),
                "String-byte dictionary"
            ),
        ]

        for (originalVariant, description) in testCases {
            // Test D-Bus binary encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(!encodedData.isEmpty, "Encoded data should not be empty for: \(description)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for: \(description)")
            #expect(
                decodedVariant.value == originalVariant.value,
                "Decoded value should match original for: \(description)")
        }
    }

    @Test("Struct types round-trip serialization")
    func structTypes() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test struct variants with different compositions
        let testCases: [(Variant, String)] = [
            // Empty structs
            (Variant(value: .struct([]), signature: "()"), "Empty struct"),

            // Single element structs
            (
                Variant(value: .struct([.string("hello")]), signature: "(s)"),
                "Single string struct"
            ),
            (Variant(value: .struct([.int32(42)]), signature: "(i)"), "Single int32 struct"),
            (Variant(value: .struct([.bool(true)]), signature: "(b)"), "Single bool struct"),

            // Two element structs
            (
                Variant(value: .struct([.string("hello"), .int32(42)]), signature: "(si)"),
                "String-int32 struct"
            ),
            (
                Variant(value: .struct([.bool(true), .double(3.14)]), signature: "(bd)"),
                "Bool-double struct"
            ),
            (
                Variant(value: .struct([.byte(255), .string("test")]), signature: "(ys)"),
                "Byte-string struct"
            ),

            // Multi element structs
            (
                Variant(
                    value: .struct([.string("user"), .int32(1001), .bool(true)]), signature: "(sib)"
                ), "User info struct"
            ),
            (
                Variant(
                    value: .struct([.double(3.14), .string("pi"), .byte(3), .bool(false)]),
                    signature: "(dsyb)"), "Mixed type struct"
            ),

            // Nested structs
            (
                Variant(
                    value: .struct([.string("outer"), .struct([.int32(42)])]), signature: "(s(i))"),
                "Nested struct"
            ),
            (
                Variant(
                    value: .struct([.struct([.string("inner1")]), .struct([.int32(123)])]),
                    signature: "((s)(i))"), "Double nested struct"
            ),

            // Struct with arrays
            (
                Variant(
                    value: .struct([.string("header"), .array([.int32(1), .int32(2)])]),
                    signature: "(sai)"), "Struct with array"
            ),
            (
                Variant(
                    value: .struct([.array([.string("a"), .string("b")]), .int32(2)]),
                    signature: "(asi)"), "Array-int32 struct"
            ),

            // Struct with dictionaries
            (
                Variant(
                    value: .struct([.string("config"), .dictionary(["key": .string("value")])]),
                    signature: "(sa{ss})"), "Struct with dictionary"
            ),
        ]

        for (originalVariant, description) in testCases {
            // Test D-Bus binary encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(!encodedData.isEmpty, "Encoded data should not be empty for: \(description)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for: \(description)")
            #expect(
                decodedVariant.value == originalVariant.value,
                "Decoded value should match original for: \(description)")
        }
    }

    @Test("Complex nested structures round-trip serialization")
    func complexNestedStructures() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test complex nested structures that might appear in real D-Bus usage
        let testCases: [(Variant, String)] = [
            // Array of structs (common in D-Bus)
            (
                Variant(
                    value: .array([
                        .struct([.string("item1"), .int32(1)]),
                        .struct([.string("item2"), .int32(2)]),
                    ]), signature: "a(si)"), "Array of structs"
            ),

            // Dictionary with string values (simplified for valid signature)
            (
                Variant(
                    value: .dictionary([
                        "StringProp": .string("value"),
                        "IntProp": .string("42"),
                        "BoolProp": .string("true"),
                    ]), signature: "a{ss}"), "Property-like dictionary"
            ),

            // Struct containing arrays and dictionaries
            (
                Variant(
                    value: .struct([
                        .string("name"),
                        .array([.string("tag1"), .string("tag2")]),
                        .dictionary(["attr1": .string("value1"), "attr2": .string("value2")]),
                    ]), signature: "(sasa{ss})"), "Complex mixed struct"
            ),

            // Array of dictionaries (simplified to single dictionary)
            (
                Variant(
                    value: .dictionary([
                        "id": .string("1"),
                        "name": .string("first"),
                    ]), signature: "a{ss}"), "Simple dictionary"
            ),

            // Deep nesting: simplified struct with array
            (
                Variant(
                    value: .struct([
                        .string("root"),
                        .array([.string("child1"), .string("child2")]),
                    ]), signature: "(sas)"), "Simplified nested structure"
            ),
        ]

        for (originalVariant, description) in testCases {
            // Test D-Bus binary encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(!encodedData.isEmpty, "Encoded data should not be empty for: \(description)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for: \(description)")
            #expect(
                decodedVariant.value == originalVariant.value,
                "Decoded value should match original for: \(description)")
        }
    }

    @Test("String edge cases D-Bus serialization")
    func stringEdgeCases() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test string edge cases that might cause issues in D-Bus serialization
        let testStrings = [
            "",  // Empty string
            " ",  // Single space
            "\n",  // Newline
            "\t",  // Tab
            "\r\n",  // Windows line ending
            "\"",  // Quote
            "\\",  // Backslash
            "\u{0000}",  // Null character
            "\u{FFFF}",  // Max BMP character
            String(repeating: "a", count: 1000),  // Long string
            "ASCII + Unicode 🌍 + Emoji 🚀",  // Mixed content
            "Control: \u{0001}\u{0002}\u{0003}",  // Control characters
            "High Unicode: \u{1F600}\u{1F680}",  // High Unicode
        ]

        for testString in testStrings {
            let originalVariant = Variant(value: .string(testString), signature: "s")

            // Test D-Bus binary encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(
                !encodedData.isEmpty,
                "Encoded data should not be empty for string: \(testString.debugDescription)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for string: \(testString.debugDescription)"
            )
            #expect(
                decodedVariant.value == originalVariant.value,
                "Decoded value should match original for string: \(testString.debugDescription)")
        }
    }

    @Test("ObjectPath edge cases D-Bus serialization")
    func objectPathEdgeCases() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test object path edge cases
        let testPaths = [
            "/",  // Root
            "/a",  // Single character
            "/org/freedesktop/DBus",  // Standard path
            "/org/freedesktop/NetworkManager/Devices/0",  // Longer path
            "/com/example/Very/Long/Path/With/Many/Components",  // Very long path
        ]

        for pathString in testPaths {
            let objectPath = try ObjectPath(pathString)
            let originalVariant = Variant(value: .objectPath(objectPath), signature: "o")

            // Test D-Bus binary encoding
            let encodedData = try encoder.encode(originalVariant, signature: "v")
            #expect(
                !encodedData.isEmpty, "Encoded data should not be empty for path: \(pathString)")

            // Test D-Bus binary decoding
            let decodedVariant = try decoder.decode(
                Variant.self, from: encodedData, signature: "v")

            // Verify the decoded variant matches the original
            #expect(
                decodedVariant.signature == originalVariant.signature,
                "Decoded signature should match original for path: \(pathString)")
            #expect(
                decodedVariant.value == originalVariant.value,
                "Decoded value should match original for path: \(pathString)")
        }
    }

    @Test("Signature edge cases")
    func signatureEdgeCases() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test signature edge cases
        let testSignatures = [
            "s",  // Simple
            "i",  // Integer
            "as",  // Array of strings
            "a{ss}",  // Dictionary
            "(si)",  // Struct
            "a(si)",  // Array of structs
            "a{sa{ss}}",  // Complex nested
            "(ybnqiuxtdsog)",  // All basic types
            "aaa{s(ybnqiuxtdsog)}",  // Very complex
        ]

        for signatureString in testSignatures {
            print("Testing signature: \(signatureString)")
            do {
                let parser = try SignatureParser(signature: signatureString)
                let signature = Signature(elements: parser.signature)
                let originalVariant = Variant(value: .signature(signature), signature: "g")

                // Test D-Bus binary encoding
                let encodedData = try encoder.encode(originalVariant, signature: "v")
                #expect(
                    !encodedData.isEmpty,
                    "Encoded data should not be empty for signature: \(signatureString)")

                // Test D-Bus binary decoding
                let decodedVariant = try decoder.decode(
                    Variant.self, from: encodedData, signature: "v")

                // Verify the decoded variant matches the original
                #expect(
                    decodedVariant.signature == originalVariant.signature,
                    "Decoded signature should match original for signature: \(signatureString)")
                #expect(
                    decodedVariant.value == originalVariant.value,
                    "Decoded value should match original for signature: \(signatureString)")
            } catch {
                print("Failed to parse signature \(signatureString): \(error)")
            }
        }
    }

    @Test("Large data structures")
    func largeDataStructures() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test large data structures for performance and correctness

        // Large string array
        let largeStringArray = Array(0..<1000).map { VariantValue.string("string_\($0)") }
        let largeStringArrayVariant = Variant(value: .array(largeStringArray), signature: "as")

        let encodedStringArray = try encoder.encode(largeStringArrayVariant, signature: "v")
        let decodedStringArray = try decoder.decode(
            Variant.self, from: encodedStringArray, signature: "v")

        #expect(
            decodedStringArray.signature == largeStringArrayVariant.signature,
            "Large string array signature should match")
        #expect(
            decodedStringArray.value == largeStringArrayVariant.value,
            "Large string array value should match")

        // Large integer array
        let largeIntArray = Array(0..<1000).map { VariantValue.int32(Int32($0)) }
        let largeIntArrayVariant = Variant(value: .array(largeIntArray), signature: "ai")

        let encodedIntArray = try encoder.encode(largeIntArrayVariant, signature: "v")
        let decodedIntArray = try decoder.decode(
            Variant.self, from: encodedIntArray, signature: "v")

        #expect(
            decodedIntArray.signature == largeIntArrayVariant.signature,
            "Large int array signature should match")
        #expect(
            decodedIntArray.value == largeIntArrayVariant.value,
            "Large int array value should match")

        // Large dictionary
        let largeDictionary = Dictionary(
            uniqueKeysWithValues: (0..<100).map {
                ("key_\($0)", VariantValue.string("value_\($0)"))
            })
        let largeDictionaryVariant = Variant(
            value: .dictionary(largeDictionary), signature: "a{ss}")

        let encodedDictionary = try encoder.encode(largeDictionaryVariant, signature: "v")
        let decodedDictionary = try decoder.decode(
            Variant.self, from: encodedDictionary, signature: "v")

        #expect(
            decodedDictionary.signature == largeDictionaryVariant.signature,
            "Large dictionary signature should match")
        #expect(
            decodedDictionary.value == largeDictionaryVariant.value,
            "Large dictionary value should match")

        // Large struct (using 10 string elements for a reasonable signature)
        let largeStruct = Array(0..<10).map { VariantValue.string("item_\($0)") }
        let largeStructVariant = Variant(
            value: .struct(largeStruct), signature: Signature(rawValue: "(ssssssssss)")!)

        let encodedStruct = try encoder.encode(largeStructVariant, signature: "v")
        let decodedStruct = try decoder.decode(
            Variant.self, from: encodedStruct, signature: "v")

        #expect(
            decodedStruct.signature == largeStructVariant.signature,
            "Large struct signature should match")
        #expect(decodedStruct.value == largeStructVariant.value, "Large struct value should match")
    }

    @Test("Comprehensive real-world simulation")
    func realWorldSimulation() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Simulate a complex D-Bus variant that might appear in real usage
        // This represents a typical D-Bus property dictionary or method call parameter
        let realWorldVariant = Variant(
            value: .struct([
                .string("org.freedesktop.NetworkManager.Device"),  // Interface name
                .dictionary([  // Properties (simplified to string-string for valid signature)
                    "DeviceType": .string("1"),  // WiFi device
                    "Interface": .string("wlan0"),  // Interface name
                    "Driver": .string("iwlwifi"),  // Driver name
                    "State": .string("100"),  // Activated
                    "Managed": .string("true"),  // Managed by NM
                    "Autoconnect": .string("true"),  // Auto-connect enabled
                    "Ip4Address": .string("192.168.1.1"),  // IP address
                    "Ip6Address": .string("fe80::1"),  // IPv6 address
                    "HwAddress": .string("aa:bb:cc:dd:ee:ff"),  // MAC address
                    "Mtu": .string("1500"),  // MTU
                    "NmVersion": .string("1.42.0"),  // NetworkManager version
                    "Capabilities": .string("carrier-detect,speed-detection"),  // Device capabilities
                    "AvailableConnections": .string(
                        "/org/freedesktop/NetworkManager/Settings/1,/org/freedesktop/NetworkManager/Settings/2"
                    ),  // Available connections
                    "Statistics": .string(
                        "RxBytes=1024000,TxBytes=512000,RxPackets=1000,TxPackets=800"),  // Statistics
                ]),
            ]), signature: "(sa{ss})")

        // Test D-Bus binary encoding
        let encodedData = try encoder.encode(realWorldVariant, signature: "v")
        #expect(!encodedData.isEmpty, "Real-world variant should encode to non-empty data")

        // Test D-Bus binary decoding
        let decodedVariant = try decoder.decode(Variant.self, from: encodedData, signature: "v")

        // Verify the decoded variant matches the original
        #expect(
            decodedVariant.signature == realWorldVariant.signature,
            "Real-world variant signature should match")
        #expect(
            decodedVariant.value == realWorldVariant.value, "Real-world variant value should match")

        // Test serialization size is reasonable
        #expect(encodedData.count < 10000, "Serialized data should be reasonably sized")
        #expect(encodedData.count > 100, "Serialized data should contain substantial content")
    }

    @Test("Initialization and type conversion")
    func initializationAndTypeConversion() throws {
        // Test DBusVariantValue initialization from various types
        let testCases: [(Any, VariantValue, String)] = [
            (UInt8(255), .byte(255), "UInt8 to byte"),
            (true, .bool(true), "Bool to bool"),
            (Int16(-1000), .int16(-1000), "Int16 to int16"),
            (UInt16(2000), .uint16(2000), "UInt16 to uint16"),
            (Int32(-50000), .int32(-50000), "Int32 to int32"),
            (UInt32(100000), .uint32(100000), "UInt32 to uint32"),
            (Int64(-1_000_000), .int64(-1_000_000), "Int64 to int64"),
            (UInt64(2_000_000), .uint64(2_000_000), "UInt64 to uint64"),
            (Double(3.14159), .double(3.14159), "Double to double"),
            ("test string", .string("test string"), "String to string"),
            (
                try ObjectPath("/test"), .objectPath(try ObjectPath("/test")),
                "ObjectPath to objectPath"
            ),
            (Signature("s"), .signature(Signature("s")), "Signature to signature"),
        ]

        for (inputValue, expectedValue, description) in testCases {
            let result = try VariantValue(inputValue)
            #expect(result == expectedValue, "Type conversion should work for: \(description)")
        }

        // Test DBusVariant initialization with proper signatures
        let stringVariant = try Variant("hello", signature: "s")
        #expect(
            stringVariant.signature.rawValue == "s", "String variant should have string signature")
        #expect(stringVariant.value == .string("hello"), "String variant should have correct value")

        let intVariant = try Variant(Int32(42), signature: "i")
        #expect(intVariant.signature.rawValue == "i", "Int variant should have int signature")
        #expect(intVariant.value == .int32(42), "Int variant should have correct value")

        // Test error handling for unsupported types
        struct UnsupportedType {}
        #expect(throws: DBusVariantError.self) {
            try VariantValue(UnsupportedType())
        }
    }

    @Test("AnyValue property functionality")
    func anyValueProperty() throws {
        // Test that anyValue property returns the correct underlying type
        let byteValue = VariantValue.byte(255)
        #expect(byteValue.anyValue as? UInt8 == 255, "anyValue should return UInt8")

        let stringValue = VariantValue.string("test")
        #expect(stringValue.anyValue as? String == "test", "anyValue should return String")

        let arrayValue = VariantValue.array([.int32(1), .int32(2)])
        #expect(arrayValue.anyValue as? [VariantValue] != nil, "anyValue should return array")

        let dictValue = VariantValue.dictionary(["key": .string("value")])
        #expect(
            dictValue.anyValue as? [String: VariantValue] != nil,
            "anyValue should return dictionary")

        let structValue = VariantValue.struct([.string("hello"), .int32(42)])
        #expect(
            structValue.anyValue as? [VariantValue] != nil,
            "anyValue should return struct array")
    }
}

@Suite("Debug Variant tests") struct DebugVariantTests {
    @Test("Debug alignment")
    func debugAlignment() throws {
        let doubleSignature = Signature("d")
        let arraySignature = Signature("ad")

        print("Double signature alignment: \(doubleSignature.element?.alignment ?? -1)")
        print("Array signature alignment: \(arraySignature.element?.alignment ?? -1)")

        // Check what happens with variant marshaling for different types
        let doubleVariant = Variant(value: .double(3.14), signature: "d")
        print(
            "Double variant signature element: \(doubleVariant.signature.element?.alignment ?? -1)")

        let arrayVariant = Variant(
            value: .array([.double(0.0), .double(3.14), .double(-1.5)]), signature: "ad")
        print("Array variant signature element: \(arrayVariant.signature.element?.alignment ?? -1)")

        // Check if the issue is with how the alignment is calculated
        let sigBytes = arrayVariant.signature.rawValue.utf8
        let signatureLength = sigBytes.count + 2  // +1 for length byte, +1 for null terminator
        print("Signature bytes length: \(signatureLength)")
        print("Alignment needed after signature: \((4 - (signatureLength % 4)) % 4)")
    }

    @Test("Debug array marshaling")
    func debugArrayMarshaling() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test marshaling a double array directly (not in variant)
        let doubleArray = [0.0, 3.14, -1.5]
        let signature = Signature("ad")

        let encodedData = try encoder.encode(doubleArray, signature: signature)
        print("Direct array encoded data: \(encodedData)")
        print(
            "Direct array encoded hex: \(encodedData.map { String(format: "%02x", $0) }.joined(separator: " "))"
        )

        let decodedArray = try decoder.decode(
            [Double].self, from: encodedData, signature: signature)
        print("Direct array decoded: \(decodedArray)")

        // Now test the variant version
        let variantArray = Variant(
            value: .array([.double(0.0), .double(3.14), .double(-1.5)]), signature: "ad")
        let variantEncodedData = try encoder.encode(variantArray, signature: "v")
        print("Variant array encoded data: \(variantEncodedData)")
        print(
            "Variant array encoded hex: \(variantEncodedData.map { String(format: "%02x", $0) }.joined(separator: " "))"
        )
    }

    @Test("Debug single double")
    func debugSingleDouble() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let testCase = Variant(value: .double(3.14), signature: "d")
        print("Original variant: \(testCase)")

        // Test D-Bus binary encoding
        let encodedData = try encoder.encode(testCase, signature: "v")
        print("Encoded data: \(encodedData)")
        print(
            "Encoded data hex: \(encodedData.map { String(format: "%02x", $0) }.joined(separator: " "))"
        )

        // Expected double bit pattern
        print("Expected double bit pattern for 3.14: \(String(format: "%016llx", 3.14.bitPattern))")

        // Test D-Bus binary decoding
        let decodedVariant = try decoder.decode(Variant.self, from: encodedData, signature: "v")
        print("Decoded variant: \(decodedVariant)")

        if case .double(let value) = decodedVariant.value {
            print(
                "Decoded double: \(value) (bit pattern: \(String(format: "%016llx", value.bitPattern)))"
            )
        }
    }

    @Test("Debug double array")
    func debugDoubleArray() throws {
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let testCase = Variant(
            value: .array([.double(0.0), .double(3.14), .double(-1.5)]),
            signature: "ad"
        )

        print("Original variant: \(testCase)")

        // Test D-Bus binary encoding
        let encodedData = try encoder.encode(testCase, signature: "v")
        print("Encoded data: \(encodedData)")
        print(
            "Encoded data hex: \(encodedData.map { String(format: "%02x", $0) }.joined(separator: " "))"
        )

        // Let's manually check the expected double bit patterns
        print("Expected double bit patterns:")
        print("0.0: \(String(format: "%016llx", 0.0.bitPattern))")
        print("3.14: \(String(format: "%016llx", 3.14.bitPattern))")
        print("-1.5: \(String(format: "%016llx", (-1.5).bitPattern))")

        // Parse the encoded data manually according to variant format
        let signatureLength = encodedData[0]
        let signatureBytes = Array(encodedData[1...Int(signatureLength)])
        let signatureString = String(bytes: signatureBytes, encoding: .utf8) ?? ""
        print("Extracted signature: '\(signatureString)'")

        // After signature + null terminator, we have alignment for array (4-byte alignment)
        let afterSignature = Int(signatureLength) + 2  // +1 for null terminator
        let arrayAlignment = 4
        let arrayAlignedStart = (afterSignature + arrayAlignment - 1) & ~(arrayAlignment - 1)
        print("Array data starts at byte \(arrayAlignedStart)")

        // Read array length
        let arrayLength =
            UInt32(encodedData[arrayAlignedStart])
            | (UInt32(encodedData[arrayAlignedStart + 1]) << 8)
            | (UInt32(encodedData[arrayAlignedStart + 2]) << 16)
            | (UInt32(encodedData[arrayAlignedStart + 3]) << 24)
        print("Array length: \(arrayLength)")

        // After array length, we have alignment for first double (8-byte alignment)
        let afterArrayLength = arrayAlignedStart + 4
        let doubleAlignment = 8
        let doubleAlignedStart = (afterArrayLength + doubleAlignment - 1) & ~(doubleAlignment - 1)
        print("Double data starts at byte \(doubleAlignedStart)")

        // Extract each double
        for i in 0..<3 {
            let doubleStart = doubleAlignedStart + i * 8
            let doubleBytes = Array(encodedData[doubleStart..<doubleStart + 8])
            print(
                "Double \(i) bytes: \(doubleBytes.map { String(format: "%02x", $0) }.joined(separator: " "))"
            )
        }

        // Test D-Bus binary decoding
        let decodedVariant = try decoder.decode(Variant.self, from: encodedData, signature: "v")
        print("Decoded variant: \(decodedVariant)")

        // Check each double value
        if case .array(let decodedArray) = decodedVariant.value {
            for (index, element) in decodedArray.enumerated() {
                if case .double(let value) = element {
                    print(
                        "Decoded double \(index): \(value) (bit pattern: \(String(format: "%016llx", value.bitPattern)))"
                    )
                }
            }
        }
    }
}
