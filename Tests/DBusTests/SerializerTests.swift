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

// MARK: Primitive Type Tests

@Suite("Serializer tests") struct SerializerTests {

    // MARK: - Test Methods

    @Test("Serialize a bool into bytes")
    func serializeBool() throws {
        let testCases: [(Signature, Bool, [UInt8])] = [
            (Signature(elements: [.bool]), true, [0x01, 0x00, 0x00, 0x00]),
            (Signature(elements: [.bool]), false, [0x00, 0x00, 0x00, 0x00]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a byte into bytes")
    func serializeUInt8() throws {
        let testCases: [(Signature, UInt8, [UInt8])] = [
            (Signature(elements: [.byte]), 1, [0b0000_0001]),
            (Signature(elements: [.byte]), 2, [0b0000_0010]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a uint16 into bytes")
    func serializeUInt16() throws {
        let testCases: [(Signature, UInt16, [UInt8])] = [
            (Signature(elements: [.uint16]), 1, [0x01, 0x00]),
            (Signature(elements: [.uint16]), 2, [0x02, 0x00]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a uint32 into bytes")
    func serializeUInt32() throws {
        let testCases: [(Signature, UInt32, [UInt8])] = [
            (Signature(elements: [.uint32]), 1, [0x01, 0x00, 0x00, 0x00]),
            (Signature(elements: [.uint32]), 2, [0x02, 0x00, 0x00, 0x00]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a uint64 into bytes")
    func serializeUInt64() throws {
        let testCases: [(Signature, UInt64, [UInt8])] = [
            (Signature(elements: [.uint64]), 1, [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
            (Signature(elements: [.uint64]), 2, [0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a int16 into bytes")
    func serializeInt16() throws {
        let testCases: [(Signature, Int16, [UInt8])] = [
            (Signature(elements: [.int16]), 1, [0x01, 0x00]),
            (Signature(elements: [.int16]), 2, [0x02, 0x00]),
            (Signature(elements: [.int16]), -1, [0xff, 0xff]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a int32 into bytes")
    func serializeInt32() throws {
        let testCases: [(Signature, Int32, [UInt8])] = [
            (Signature(elements: [.int32]), 1, [0x01, 0x00, 0x00, 0x00]),
            (Signature(elements: [.int32]), 2, [0x02, 0x00, 0x00, 0x00]),
            (Signature(elements: [.int32]), -1, [0xff, 0xff, 0xff, 0xff]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a int64 into bytes")
    func serializeInt64() throws {
        let testCases: [(Signature, Int64, [UInt8])] = [
            (Signature(elements: [.int64]), 1, [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
            (Signature(elements: [.int64]), 2, [0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
            (Signature(elements: [.int64]), -1, [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a double into bytes")
    func serializeDouble() throws {
        let testCases: [(Signature, Double, [UInt8])] = [
            (
                Signature(elements: [.double]), -1.0,
                [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xbf]
            ),
            (
                Signature(elements: [.double]), 0.0,
                [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            ),
            (
                Signature(elements: [.double]), 1.0,
                [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a string into bytes")
    func serializeString() throws {
        let testCases: [(Signature, String, [UInt8])] = [
            (
                Signature(elements: [.string]), "foo",
                [0x03, 0x00, 0x00, 0x00, 0x66, 0x6f, 0x6f, 0x00]
            ),
            (Signature(elements: [.string]), "a", [0x01, 0x00, 0x00, 0x00, 0x61, 0x00]),
            (Signature(elements: [.string]), "b", [0x01, 0x00, 0x00, 0x00, 0x62, 0x00]),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a ObjectPath into bytes")
    func serializeObjectPath() throws {
        let testCases: [(Signature, ObjectPath, [UInt8])] = [
            (
                Signature(elements: [.objectPath]), ObjectPath(components: []),
                [0x01, 0x00, 0x00, 0x00, 0x2f, 0x00]
            ),
            (
                Signature(elements: [.objectPath]), ObjectPath(components: ["foo"]),
                [0x04, 0x00, 0x00, 0x00, 0x2f, 0x66, 0x6f, 0x6f, 0x00]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a signature into bytes")
    func serializeSignature() throws {
        let testCases: [(Signature, Signature, [UInt8])] = [
            (Signature(elements: [.signature]), Signature(elements: [.byte]), [0x01, 0x79, 0x00]),
            (
                Signature(elements: [.signature]), Signature(elements: [.byte, .bool]),
                [0x02, 0x79, 0x62, 0x00]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a variant of byte into bytes")
    func serializeVariantUInt8() throws {
        let testCases: [(Signature, Variant, [UInt8])] = [
            (
                Signature(elements: [.variant]),
                Variant(value: .byte(1), signature: Signature(elements: [.byte])),
                [0x01, 0x79, 0x00, 0x01]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a variant of array of types into bytes")
    func serializeVariantArray() throws {
        let testCases: [(Signature, Variant, [UInt8])] = [
            (
                Signature(elements: [.variant]),
                Variant(
                    value: .array([.byte(1), .byte(2)]),
                    signature: Signature(elements: [.array(.byte)])
                ),
                [
                    0x02, 0x61, 0x79, 0x00,  // signature: "ay"
                    0x02, 0x00, 0x00, 0x00,  // array length: 2
                    0x01, 0x02,  // array data: [1, 2]
                ]
            ),
            (
                Signature(elements: [.variant]),
                Variant(
                    value: .array([.string("hello"), .string("world")]),
                    signature: Signature(elements: [.array(.string)])
                ),
                [
                    0x02, 0x61, 0x73, 0x00,  // signature: "as"
                    0x16, 0x00, 0x00, 0x00,  // array length: 22
                    0x05, 0x00, 0x00, 0x00,  // "hello" length: 5
                    0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x00,  // "hello" + null
                    0x00, 0x00,  // padding for next element
                    0x05, 0x00, 0x00, 0x00,  // "world" length: 5
                    0x77, 0x6f, 0x72, 0x6c, 0x64, 0x00,  // "world" + null
                ]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize variant dictionary into bytes")
    func serializeVariantDictionary() throws {
        let testCases: [(Signature, Variant, [UInt8])] = [
            (
                Signature(elements: [.variant]),
                Variant(
                    value: .dictionary(["key": .string("value")]),
                    signature: Signature(elements: [.dictionary(.string, .string)])
                ),
                [
                    0x05, 0x61, 0x7b, 0x73, 0x73, 0x7d, 0x00, 0x00,  // signature: "a{ss}" + padding
                    0x12, 0x00, 0x00, 0x00,  // dictionary length: 18
                    0x00, 0x00, 0x00, 0x00,  // padding for first entry
                    0x03, 0x00, 0x00, 0x00,  // key length: 3
                    0x6b, 0x65, 0x79, 0x00,  // "key" + null
                    0x05, 0x00, 0x00, 0x00,  // value length: 5
                    0x76, 0x61, 0x6c, 0x75, 0x65, 0x00,  // "value" + null
                ]
            ),
            (
                Signature(elements: [.variant]),
                Variant(
                    value: .dictionary(["test": .byte(42)]),
                    signature: Signature(elements: [.dictionary(.string, .byte)])
                ),
                [
                    0x05, 0x61, 0x7b, 0x73, 0x79, 0x7d, 0x00, 0x00,  // signature: "a{sy}" + padding
                    0x0a, 0x00, 0x00, 0x00,  // dictionary length: 10
                    0x00, 0x00, 0x00, 0x00,  // padding for first entry
                    0x04, 0x00, 0x00, 0x00,  // key length: 4
                    0x74, 0x65, 0x73, 0x74, 0x00, 0x2a,  // "test" + null + value 42
                ]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize variant struct signatures into bytes")
    func serializeVariantStruct() throws {
        let testCases: [(Signature, Variant, [UInt8])] = [
            (
                Signature(elements: [.variant]),
                Variant(
                    value: .struct([.uint32(42), .string("test")]),
                    signature: Signature(elements: [.struct([.uint32, .string])])
                ),
                [
                    0x04, 0x28, 0x75, 0x73, 0x29, 0x00, 0x00, 0x00,  // signature: "(us)" + padding
                    0x2a, 0x00, 0x00, 0x00,  // uint32 value: 42
                    0x04, 0x00, 0x00, 0x00,  // string length: 4
                    0x74, 0x65, 0x73, 0x74, 0x00,  // "test" + null
                ]
            ),
            (
                Signature(elements: [.variant]),
                Variant(
                    value: .struct([.bool(true), .int16(-1), .double(3.14)]),
                    signature: Signature(elements: [.struct([.bool, .int16, .double])])
                ),
                [
                    0x05, 0x28, 0x62, 0x6e, 0x64, 0x29, 0x00, 0x00,  // signature: "(bnd)" + padding
                    0x01, 0x00, 0x00, 0x00,  // bool value: true (as uint32)
                    0xff, 0xff, 0x00, 0x00,  // int16 value: -1 + padding
                    0x1f, 0x85, 0xeb, 0x51, 0xb8, 0x1e, 0x09, 0x40,  // double value: 3.14 (little-endian)
                ]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize nested variant signatures into bytes")
    func serializeNestedVariant() throws {
        let testCases: [(Signature, Variant, [UInt8])] = [
            (
                Signature(elements: [.variant]),
                Variant(
                    value: .array([.struct([.string("nested"), .uint32(123)])]),
                    signature: Signature(elements: [.array(.struct([.string, .uint32]))])
                ),
                [
                    0x05, 0x61, 0x28, 0x73, 0x75, 0x29, 0x00, 0x00,  // signature: "a(su)" + padding
                    0x10, 0x00, 0x00, 0x00,  // array length: 16
                    0x00, 0x00, 0x00, 0x00,  // padding for first struct
                    0x06, 0x00, 0x00, 0x00,  // string length: 6
                    0x6e, 0x65, 0x73, 0x74, 0x65, 0x64, 0x00, 0x00,  // "nested" + null + padding
                    0x7b, 0x00, 0x00, 0x00,  // uint32 value: 123
                ]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    // MARK: Array Type Tests

    @Test("Serialize array bool into bytes")
    func serializeArrayBool() throws {
        let testCases: [(Signature, [Bool], [UInt8])] = [
            (
                Signature(elements: [.array(.bool)]), [true],
                [0x04, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array uint8 into bytes")
    func serializeArrayUInt8() throws {
        let testCases: [(Signature, [UInt8], [UInt8])] = [
            (Signature(elements: [.array(.byte)]), [0x01], [0x01, 0x00, 0x00, 0x00, 0x01])
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array uint16 into bytes")
    func serializeArrayUInt16() throws {
        let testCases: [(Signature, [UInt16], [UInt8])] = [
            (Signature(elements: [.array(.uint16)]), [0x01], [0x02, 0x00, 0x00, 0x00, 0x01, 0x00])
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array uint32 into bytes")
    func serializeArrayUInt32() throws {
        let testCases: [(Signature, [UInt32], [UInt8])] = [
            (
                Signature(elements: [.array(.uint32)]), [0x01],
                [0x04, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array uint64 into bytes")
    func serializeArrayUInt64() throws {
        let testCases: [(Signature, [UInt64], [UInt8])] = [
            (
                Signature(elements: [.array(.uint64)]), [0x01],
                [0x08, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array int16 into bytes")
    func serializeArrayInt16() throws {
        let testCases: [(Signature, [Int16], [UInt8])] = [
            (Signature(elements: [.array(.int16)]), [0x01], [0x02, 0x00, 0x00, 0x00, 0x01, 0x00])
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array int32 into bytes")
    func serializeArrayInt32() throws {
        let testCases: [(Signature, [Int32], [UInt8])] = [
            (
                Signature(elements: [.array(.int32)]), [0x01],
                [0x04, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array int64 into bytes")
    func serializeArrayInt64() throws {
        let testCases: [(Signature, [Int64], [UInt8])] = [
            (
                Signature(elements: [.array(.int64)]), [0x01],
                [0x08, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array double into bytes")
    func serializeArrayDouble() throws {
        let testCases: [(Signature, [Double], [UInt8])] = [
            (
                Signature(elements: [.array(.double)]), [-1.0],
                [0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xbf]
            ),
            (
                Signature(elements: [.array(.double)]), [0.0],
                [0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            ),
            (
                Signature(elements: [.array(.double)]), [1.0],
                [0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize array string into bytes")
    func serializeArrayString() throws {
        let testCases: [(Signature, [String], [UInt8])] = [
            (
                Signature(elements: [.array(.string)]), ["foo"],
                [0x08, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x66, 0x6f, 0x6f, 0x00]
            ),
            (
                Signature(elements: [.array(.string)]), ["a", "bb"],
                [
                    0x0f, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x61, 0x00, 0x00, 0x00, 0x02,
                    0x00, 0x00, 0x00, 0x62, 0x62, 0x00,
                ]
            ),
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    // MARK: Dictionary Type Tests

    @Test("Serialize dictionary string-string into bytes")
    func serializeDictionaryStringString() throws {
        let testCases: [(Signature, [String: String], [UInt8])] = [
            (
                Signature(elements: [.dictionary(.string, .string)]), ["a": "b"],
                [
                    0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x61,
                    0x00, 0x01, 0x00, 0x00, 0x00, 0x62, 0x00,
                ]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize dictionary string-uint8 into bytes")
    func serializeDictionaryStringUInt8() throws {
        let testCases: [(Signature, [String: UInt8], [UInt8])] = [
            (
                Signature(elements: [.dictionary(.string, .byte)]), ["a": 1],
                [
                    0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x61,
                    0x00, 0x01,
                ]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    // MARK: Tuple Type Tests

    @Test("Serialize tuple uint32-uint32 into bytes")
    func serializeTupleUInt32UInt32() throws {
        let testCases: [(Signature, (UInt32, UInt32), [UInt8])] = [
            (
                Signature(elements: [.uint32, .uint32]), (UInt32(1), UInt32(1)),
                [0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input.0)
            try serializer.serialize(input.1)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize tuple uint32-string into bytes")
    func serializeTupleUInt32String() throws {
        let testCases: [(Signature, (UInt32, String), [UInt8])] = [
            (
                Signature(elements: [.uint32, .string]), (UInt32(1), "a"),
                [0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x61, 0x00]
            )
        ]

        for (signature, input, expected) in testCases {
            var serializer = Serializer(signature: signature)
            try serializer.serialize(input.0)
            try serializer.serialize(input.1)
            #expect(serializer.data == expected, "\n got: \(serializer.data!)\nwant: \(expected)")
        }
    }

    @Test("Serialize a struct of uint32 and uint64 using a closureinto bytes")
    func serializeClosure() throws {
        let want: [UInt8] = [
            0x01, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]
        var serializer = Serializer(
            signature: Signature(elements: [.struct([.uint32, .uint64])]))
        try serializer.serialize { s in
            try s.serialize(UInt32(1))
            try s.serialize(UInt64(1))
        }
        #expect(
            serializer.data == want, "\n got: \(serializer.data!)\nwant: \(want)")
    }

    @Test("Serialize a struct of int32 and array of byte into bytes")
    func serializeStructInt32ArrayByte() throws {
        let signature = Signature(elements: [.struct([.int32, .array(.byte)])])
        let want: [UInt8] = [
            0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00,
            0x01, 0x02,
        ]
        var serializer = Serializer(signature: signature)
        try serializer.serialize { s in
            try s.serialize(Int32(1))
            try s.serialize([UInt8(1), UInt8(2)])
        }
        #expect(
            serializer.data == want, "\n got: \(serializer.data!)\nwant: \(want)")
    }
}
