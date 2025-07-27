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

@Suite("Deserializer tests") struct DeserializerTests {
    @Test("Deserialize bytes as a bool")
    func deserializeBool() throws {
        let testCases: [(Endianness, Signature, [UInt8], Bool)] = [
            (
                Endianness.littleEndian, Signature(elements: [.bool]),
                [0x01, 0x00, 0x00, 0x00], true
            ),
            (
                Endianness.littleEndian, Signature(elements: [.bool]),
                [0x00, 0x00, 0x00, 0x00], false
            ),
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness,
                alignmentContext: .structContent)
            let got: Bool = try deserializer.unserialize()
            #expect(got == want)
        }
    }

    @Test("Deserialize bytes as a byte (uint8)")
    func deserializeUInt8() throws {
        let testCases: [(Endianness, Signature, [UInt8], UInt8)] = [
            (
                Endianness.littleEndian, Signature(elements: [.byte]),
                [0x00], 0
            ),
            (
                Endianness.littleEndian, Signature(elements: [.byte]),
                [0x01], 1
            ),
            (
                Endianness.littleEndian, Signature(elements: [.byte]),
                [0x02], 2
            ),
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness,
                alignmentContext: .structContent)
            let got: UInt8 = try deserializer.unserialize()
            #expect(got == want)
        }
    }

    @Test("Deserialize bytes as a uint16")
    func deserializeUInt16() throws {
        let testCases: [(Endianness, Signature, [UInt8], UInt16)] = [
            (
                Endianness.littleEndian, Signature(elements: [.uint16]),
                [0x00, 0x00], 0
            ),
            (
                Endianness.littleEndian, Signature(elements: [.uint16]),
                [0x01, 0x00], 1
            ),
            (
                Endianness.littleEndian, Signature(elements: [.uint16]),
                [0x02, 0x00], 2
            ),
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness,
                alignmentContext: .structContent)
            let got: UInt16 = try deserializer.unserialize()
            #expect(got == want)
        }
    }

    @Test("Deserialize bytes as a uint32")
    func deserializeUInt32()
        throws
    {
        let testCases: [(Endianness, Signature, [UInt8], UInt32)] = [
            (
                Endianness.littleEndian, Signature(elements: [.uint32]),
                [0x00, 0x00, 0x00, 0x00], 0
            ),
            (
                Endianness.littleEndian, Signature(elements: [.uint32]),
                [0x01, 0x00, 0x00, 0x00], 1
            ),
            (
                Endianness.littleEndian, Signature(elements: [.uint32]),
                [0x02, 0x00, 0x00, 0x00], 2
            ),
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness)
            let got: UInt32 = try deserializer.unserialize()
            #expect(got == want)
        }
    }

    @Test("Deserialize bytes as a uint64")
    func deserializeUInt64() throws {
        let testCases: [(Endianness, Signature, [UInt8], [UInt64])] = [
            (
                Endianness.littleEndian, Signature(elements: [.uint64, .uint64, .uint64]),
                [
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                ], [0, 1, 2]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness)
            for want in want {
                let got: UInt64 = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as a int16")
    func deserializeInt16() throws {
        let testCases: [(Endianness, Signature, [UInt8], [Int16])] = [
            (
                Endianness.littleEndian, Signature(elements: [.int16, .int16, .int16]),
                [0x00, 0x00, 0x01, 0x00, 0x02, 0x00], [0, 1, 2]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness)
            for want in want {
                let got: Int16 = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as a int32")
    func deserializeInt32() throws {
        let testCases: [(Endianness, Signature, [UInt8], [Int32])] = [
            (
                Endianness.littleEndian, Signature(elements: [.int32, .int32, .int32]),
                [0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00], [0, 1, 2]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness)
            for want in want {
                let got: Int32 = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as a int64")
    func deserializeInt64() throws {
        let testCases: [(Endianness, Signature, [UInt8], [Int64])] = [
            (
                Endianness.littleEndian, Signature(elements: [.int64, .int64, .int64]),
                [
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
                    0x00,
                    0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                ], [0, 1, 2]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness)
            for want in want {
                let got: Int64 = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as a double")
    func deserializeDouble() throws {
        let testCases: [(Endianness, Signature, [UInt8], [Double])] = [
            (
                Endianness.littleEndian, Signature(elements: [.double, .double, .double]),
                [
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xbf, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f,
                ], [-1.0, 0.0, 1.0]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness)
            for want in want {
                let got: Double = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as a string")
    func deserializeString() throws {
        let testCases: [(Endianness, Signature, [UInt8], [String])] = [
            (
                Endianness.littleEndian, Signature(elements: [.string, .string]),
                [0x01, 0x00, 0x00, 0x00, 0x61, 0x00, 0x01, 0x00, 0x00, 0x00, 0x62, 0x00],
                ["a", "b"]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input, signature: signature, endianness: endianness,
                alignmentContext: .structContent)
            for want in want {
                let got: String = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("String deserialization bounds checking")
    func deserializeStringBoundsChecking() throws {
        // Test case 1: Normal string deserialization should work
        do {
            let validData: [UInt8] = [
                0x05, 0x00, 0x00, 0x00,  // Length: 5
                0x68, 0x65, 0x6c, 0x6c, 0x6f,  // "hello"
                0x00,  // Null terminator
            ]
            var deserializer = Deserializer(
                data: validData,
                signature: Signature(elements: [.string]),
                endianness: .littleEndian,
                alignmentContext: .structContent
            )
            let result = try deserializer.unserialize() as String
            #expect(result == "hello")
        }

        // Test case 2: Empty string should work
        do {
            let emptyStringData: [UInt8] = [
                0x00, 0x00, 0x00, 0x00,  // Length: 0
                0x00,  // Null terminator
            ]
            var deserializer = Deserializer(
                data: emptyStringData,
                signature: Signature(elements: [.string]),
                endianness: .littleEndian,
                alignmentContext: .structContent
            )
            let result = try deserializer.unserialize() as String
            #expect(result == "")
        }

        // Test case 3: Insufficient data for length field should throw error
        do {
            let insufficientLengthData: [UInt8] = [
                0x05, 0x00, 0x00,  // Only 3 bytes instead of 4 for length
            ]
            var deserializer = Deserializer(
                data: insufficientLengthData,
                signature: Signature(elements: [.string]),
                endianness: .littleEndian,
                alignmentContext: .structContent
            )
            #expect(throws: DeserializerError.self) {
                let _: String = try deserializer.unserialize()
            }
        }

        // Test case 4: Length field claims more data than available should throw error
        do {
            let truncatedStringData: [UInt8] = [
                0x10, 0x00, 0x00, 0x00,  // Length: 16 (but we only have 3 bytes of string data)
                0x68, 0x65, 0x6c,  // Only "hel" (3 bytes), missing 13 bytes + null terminator
            ]
            var deserializer = Deserializer(
                data: truncatedStringData,
                signature: Signature(elements: [.string]),
                endianness: .littleEndian,
                alignmentContext: .structContent
            )
            #expect(throws: DeserializerError.self) {
                let _: String = try deserializer.unserialize()
            }
        }

        // Test case 5: Missing null terminator should throw error
        do {
            let missingNullTerminatorData: [UInt8] = [
                0x05, 0x00, 0x00, 0x00,  // Length: 5
                0x68, 0x65, 0x6c, 0x6c, 0x6f,  // "hello" but missing null terminator
            ]
            var deserializer = Deserializer(
                data: missingNullTerminatorData,
                signature: Signature(elements: [.string]),
                endianness: .littleEndian,
                alignmentContext: .structContent
            )
            #expect(throws: DeserializerError.self) {
                let _: String = try deserializer.unserialize()
            }
        }

        // Test case 6: Big endian should work correctly
        do {
            let bigEndianData: [UInt8] = [
                0x00, 0x00, 0x00, 0x05,  // Length: 5 (big endian)
                0x68, 0x65, 0x6c, 0x6c, 0x6f,  // "hello"
                0x00,  // Null terminator
            ]
            var deserializer = Deserializer(
                data: bigEndianData,
                signature: Signature(elements: [.string]),
                endianness: .bigEndian,
                alignmentContext: .structContent
            )
            let result = try deserializer.unserialize() as String
            #expect(result == "hello")
        }
    }

    @Test("Deserialize bytes as object path")
    func deserializeObjectPath() throws {
        let testCases: [(Endianness, Signature, [UInt8], [String])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.objectPath, .objectPath]),
                [
                    0x01, 0x00, 0x00, 0x00, 0x2f, 0x00,
                    0x04, 0x00, 0x00, 0x00, 0x2f, 0x66, 0x6f, 0x6f, 0x00,
                ],
                ["/", "/foo"]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for wantStr in want {
                let got: ObjectPath = try deserializer.unserialize()
                let expectedObjectPath = try ObjectPath(wantStr)
                #expect(got == expectedObjectPath)
            }
        }
    }

    @Test("Deserialize bytes as signature")
    func deserializeSignature() throws {
        let testCases: [(Endianness, Signature, [UInt8], [Signature])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.signature, .signature]),
                [0x01, 0x79, 0x00, 0x01, 0x62, 0x00],
                [Signature(elements: [.byte]), Signature(elements: [.bool])]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: Signature = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as variant with UInt8")
    func deserializeVariantUInt8() throws {
        let testCases: [(Endianness, Signature, [UInt8], [UInt8])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.variant]),
                [0x01, 0x79, 0x00, 0x01],
                [UInt8(1)]
            ),
            (
                Endianness.littleEndian,
                Signature(elements: [.variant, .variant]),
                [
                    0x01, 0x79, 0x00, 0x01,
                    0x01, 0x79, 0x00, 0x02,
                ],
                [UInt8(1), UInt8(2)]
            ),
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for wantValue in want {
                let got: Variant = try deserializer.unserialize()
                let expectedVariant = try Variant(
                    wantValue, signature: Signature(elements: [.byte]))
                #expect(got == expectedVariant)
            }
        }
    }

    @Test("Deserialize bytes as variant with Bool")
    func deserializeVariantBool() throws {
        let testCases: [(Endianness, Signature, [UInt8], [Bool])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.variant]),
                [0x01, 0x62, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00],
                [true]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)

            for wantValue in want {
                let got: Variant = try deserializer.unserialize()
                let expectedVariant = try Variant(
                    wantValue, signature: Signature(elements: [.bool]))
                #expect(got == expectedVariant)
            }
        }
    }

    @Test("Deserialize bytes as array of bool")
    func deserializeArrayBool() throws {
        let testCases: [(Endianness, Signature, [UInt8], [[Bool]])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.bool)]),
                [
                    0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x01, 0x00, 0x00, 0x00,
                ],
                [[false, true]]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: [Bool] = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as array of byte")
    func deserializeArrayUInt8() throws {
        let testCases: [(Endianness, Signature, [UInt8], [[UInt8]])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.byte)]),
                [0x02, 0x00, 0x00, 0x00, 0x01, 0x02],
                [[1, 2]]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: [UInt8] = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    // TODO: write testDeserializeArray for other fixed-width integers and Double

    @Test("Deserialize bytes as array of string")
    func deserializeArrayString() throws {
        let testCases: [(Endianness, Signature, [UInt8], [[String]])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.string)]),
                [
                    0x06, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
                    0x61, 0x00,
                ],
                [["a"]]
            ),
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.string)]),
                [
                    0x0f, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
                    0x61, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x62, 0x62,
                    0x00,
                ],
                [["a", "bb"]]
            ),
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: [String] = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as array of object path")
    func deserializeArrayObjectPath() throws {
        let testCases: [(Endianness, Signature, [UInt8], [[ObjectPath]])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.objectPath)]),
                [
                    0x06, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
                    0x2f, 0x00,
                ],
                [[ObjectPath(components: [])]]
            ),
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.objectPath)]),
                [
                    0x09, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00,
                    0x2f, 0x66, 0x6f, 0x6f, 0x00,
                ],
                [[ObjectPath(components: ["foo"])]]
            ),
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: [ObjectPath] = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as array of signature")
    func deserializeArraySignature() throws {
        let testCases: [(Endianness, Signature, [UInt8], [[Signature]])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.signature)]),
                [0x03, 0x00, 0x00, 0x00, 0x01, 0x79, 0x00],
                [[Signature(elements: [.byte])]]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: [Signature] = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as array of variant with UInt8")
    func deserializeArrayVariantUInt8() throws {
        let testCases: [(Endianness, Signature, [UInt8], [[UInt8]])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.array(.variant)]),
                [
                    0x08, 0x00, 0x00, 0x00, 0x01, 0x79, 0x00, 0x01,
                    0x01, 0x79, 0x00, 0x02,
                ],
                [[UInt8(1), UInt8(2)]]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for wantValues in want {
                let got: [Variant] = try deserializer.unserialize()
                let expectedVariants = try wantValues.map { value in
                    try Variant(value, signature: Signature(elements: [.byte]))
                }
                #expect(got == expectedVariants)
            }
        }
    }

    // MARK: Dictionary Type Tests

    @Test("Deserialize bytes as string-to-string dictionary")
    func deserializeDictionaryStringString() throws {
        let testCases: [(String, Endianness, Signature, [UInt8], [[String: String]])] = [
            (
                "Single entry dictionary",
                Endianness.littleEndian,
                Signature(elements: [.dictionary(.string, .string)]),
                [
                    0x12, 0x00, 0x00, 0x00,  // Dictionary length: 18 bytes
                    0x00, 0x00, 0x00, 0x00,  // 4 bytes padding for 8-byte alignment
                    0x03, 0x00, 0x00, 0x00, 0x6b, 0x65, 0x79, 0x00,  // "key\0" (length 3)
                    0x05, 0x00, 0x00, 0x00, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x00,  // "value\0" (length 5)
                ],
                [["key": "value"]]
            ),
            (
                "Two entry dictionary",
                Endianness.littleEndian,
                Signature(elements: [.dictionary(.string, .string)]),
                [
                    0x29, 0x00, 0x00, 0x00,  // Dictionary length: 41 bytes
                    0x00, 0x00, 0x00, 0x00,  // 4 bytes padding for 8-byte alignment
                    0x04, 0x00, 0x00, 0x00, 0x6b, 0x65, 0x79, 0x32, 0x00,  // "key2\0" (length 4)
                    0x03, 0x00, 0x00, 0x00, 0x74, 0x77, 0x6f, 0x00,  // "two\0" (length 3)
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // 7 bytes padding to 8-byte alignment
                    0x04, 0x00, 0x00, 0x00, 0x6b, 0x65, 0x79, 0x31, 0x00,  // "key1\0" (length 4)
                    0x03, 0x00, 0x00, 0x00, 0x6f, 0x6e, 0x65, 0x00,  // "one\0" (length 3)
                ],
                [["key1": "one", "key2": "two"]]
            ),
            (
                "Empty dictionary",
                Endianness.littleEndian,
                Signature(elements: [.dictionary(.string, .string)]),
                [0x00, 0x00, 0x00, 0x00],
                [[String: String]()]
            ),
        ]

        for (_, endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: [String: String] = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }

    @Test("Deserialize bytes as string-to-variant dictionary")
    func deserializeDictionaryStringVariant() throws {
        let testCases: [(Endianness, Signature, [UInt8], [[String: Variant]])] = [
            (
                Endianness.littleEndian,
                Signature(elements: [.dictionary(.string, .variant)]),
                [
                    0x0c, 0x00, 0x00, 0x00,  // Dictionary length: 12 bytes
                    0x00, 0x00, 0x00, 0x00,  // 4 bytes padding for 8-byte alignment
                    0x03, 0x00, 0x00, 0x00, 0x6b, 0x65, 0x79, 0x00,  // "key\0" (length 3)
                    0x01, 0x79, 0x00, 0x2a,  // Variant: signature "y\0" + value 42
                ],
                [["key": try Variant(UInt8(42), signature: Signature(elements: [.byte]))]]
            )
        ]

        for (endianness, signature, input, want) in testCases {
            var deserializer = Deserializer(
                data: input,
                signature: signature,
                endianness: endianness)
            for want in want {
                let got: [String: Variant] = try deserializer.unserialize()
                #expect(got == want)
            }
        }
    }
}
