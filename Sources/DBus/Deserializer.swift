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

public struct Deserializer {
    var data: [UInt8]
    var signature: Signature
    var endianness: Endianness
    var alignmentContext: AlignmentContext

    private var currentSignatureIndex: Signature.Index
    private var currentDataIndex: [UInt8].Index

    public init(
        data: [UInt8], signature: Signature, endianness: Endianness,
        alignmentContext: AlignmentContext = .message
    ) {
        self.data = data
        self.signature = signature
        self.endianness = endianness
        self.alignmentContext = alignmentContext

        self.currentDataIndex = data.startIndex
        self.currentSignatureIndex = signature.startIndex
    }

    /// Get the current expected signature element
    public var currentSignatureElement: SignatureElement {
        signature[currentSignatureIndex]
    }

    // MARK: - Scalar Types

    /// Unmarshal `bytes` as a `Bool`.
    private func unmarshal(_ bytes: [UInt8]) -> Bool {
        let value: UInt32 = load(from: bytes)
        return value == 1
    }

    /// Decode the next element as a `Bool`.
    public mutating func unserialize() throws -> Bool {
        guard signature[currentSignatureIndex] == .bool else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: Bool.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }
        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as a `UInt8`.
    private func unmarshal(_ bytes: [UInt8]) -> UInt8 {
        return load(from: bytes)
    }

    /// Decode the next element as a `UInt8`.
    public mutating func unserialize() throws -> UInt8 {
        guard signature[currentSignatureIndex] == .byte else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: UInt8.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as a `UInt16`.
    private func unmarshal(_ bytes: [UInt8]) -> UInt16 {
        return load(from: bytes)
    }

    /// Decode the next element as a `UInt16`.
    public mutating func unserialize() throws -> UInt16 {
        guard signature[currentSignatureIndex] == .uint16 else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: UInt16.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as `UInt32`.
    private func unmarshal(_ bytes: [UInt8]) -> UInt32 {
        return load(from: bytes)
    }

    /// Decode the next element as a `UInt32`.
    public mutating func unserialize() throws -> UInt32 {
        guard signature[currentSignatureIndex] == .uint32 else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: UInt32.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as `UInt64`.
    private func unmarshal(_ bytes: [UInt8]) -> UInt64 {
        return load(from: bytes)
    }

    /// Decode the next element as a `UInt64`.
    public mutating func unserialize() throws -> UInt64 {
        guard signature[currentSignatureIndex] == .uint64 else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: UInt64.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as `Int16`.
    private func unmarshal(_ bytes: [UInt8]) -> Int16 {
        return load(from: bytes)
    }

    /// Decode the next element as a `Int16`.
    public mutating func unserialize() throws -> Int16 {
        guard signature[currentSignatureIndex] == .int16 else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: Int16.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as `Int32`.
    private func unmarshal(_ bytes: [UInt8]) -> Int32 {
        return load(from: bytes)
    }

    /// Decode the next element as a `Int32`.
    public mutating func unserialize() throws -> Int32 {
        guard signature[currentSignatureIndex] == .int32 else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: Int32.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as `Int64`.
    private func unmarshal(_ bytes: [UInt8]) -> Int64 {
        return load(from: bytes)
    }

    /// Decode the next element as a `Int64`.
    public mutating func unserialize() throws -> Int64 {
        guard signature[currentSignatureIndex] == .int64 else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: Int64.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    /// Unmarshal `bytes` as `Double`.
    private func unmarshal(_ bytes: [UInt8]) -> Double {
        let bitPattern: UInt64 = load(from: bytes)
        return Double(bitPattern: bitPattern)
    }

    /// Decode the next element as a `Double`.
    public mutating func unserialize() throws -> Double {
        guard signature[currentSignatureIndex] == .double else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: Double.self)
        }
        defer {
            currentDataIndex += signature[currentSignatureIndex].alignment
            currentSignatureIndex += 1
        }

        let startIndex = currentDataIndex
        let endIndex = currentDataIndex + signature[currentSignatureIndex].alignment
        let data = [UInt8](data[startIndex..<endIndex])
        return unmarshal(data)
    }

    // MARK: String Types

    /// Unmarshal `bytes` as `String`.
    private func unmarshal(_ bytes: [UInt8]) -> String {
        // Check if we have enough bytes for the length field
        guard bytes.count >= 4 else {
            return ""  // Return empty string for malformed data
        }

        // Decode the length field based on endianness
        let length: UInt32
        if endianness == .littleEndian {
            length =
                UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16)
                | (UInt32(bytes[3]) << 24)
        } else {
            length =
                (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8)
                | UInt32(bytes[3])
        }

        // Check if we have enough bytes for the string data
        let stringEndIndex = 4 + Int(length)
        guard bytes.count >= stringEndIndex else {
            return ""  // Return empty string for malformed data
        }

        // Extract the string data (skip length field + null terminator)
        let stringData = bytes[4..<stringEndIndex]
        return String(decoding: stringData, as: UTF8.self)
    }

    /// Decode the next element as a `String`.
    public mutating func unserialize() throws -> String {
        guard signature[currentSignatureIndex] == .string else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: String.self)
        }

        // Apply alignment for message context
        if alignmentContext == .message {
            let alignment = 4
            let paddingNeeded = (alignment - (currentDataIndex % alignment)) % alignment
            currentDataIndex += paddingNeeded
        }

        // Check if we have enough data for the length field (4 bytes)
        guard currentDataIndex + 4 <= data.endIndex else {
            throw DeserializerError.invalidValue(forType: String.self)
        }

        // Read the string length from the first 4 bytes
        let lengthBytes = Array(data[currentDataIndex..<currentDataIndex + 4])
        let length: UInt32
        if endianness == .littleEndian {
            length =
                UInt32(lengthBytes[0]) | (UInt32(lengthBytes[1]) << 8)
                | (UInt32(lengthBytes[2]) << 16) | (UInt32(lengthBytes[3]) << 24)
        } else {
            length =
                (UInt32(lengthBytes[0]) << 24) | (UInt32(lengthBytes[1]) << 16)
                | (UInt32(lengthBytes[2]) << 8) | UInt32(lengthBytes[3])
        }

        // Check if we have enough data for the string content + null terminator
        let totalStringBytes = 4 + Int(length) + 1  // length field + string data + null terminator
        guard currentDataIndex + totalStringBytes <= data.endIndex else {
            throw DeserializerError.invalidValue(forType: String.self)
        }

        // Extract the string data (excluding length field and null terminator)
        let stringData = data[currentDataIndex + 4..<currentDataIndex + 4 + Int(length)]
        let result = String(decoding: stringData, as: UTF8.self)

        // Update indices
        currentDataIndex += totalStringBytes
        currentSignatureIndex += 1

        return result
    }

    /// Unmarshal `bytes` as `ObjectPath`.
    private func unmarshal(_ bytes: [UInt8]) throws -> ObjectPath {
        let value: String = unmarshal(bytes)
        return try ObjectPath(value)
    }

    /// Decode the next element as an `ObjectPath`.
    public mutating func unserialize() throws -> ObjectPath {
        guard signature[currentSignatureIndex] == .objectPath else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: ObjectPath.self)
        }

        let startIndex = currentDataIndex
        guard let endIndex = data[currentDataIndex + 4..<data.endIndex].firstIndex(of: 0x00) else {
            throw DeserializerError.invalidValue(forType: ObjectPath.self)
        }

        defer {
            currentDataIndex = endIndex + 1
            currentSignatureIndex += 1
        }

        let data = [UInt8](data[startIndex..<endIndex])
        return try unmarshal(data)
    }

    /// Decode the next element as a `Signature`.
    public mutating func unserialize() throws -> Signature {
        guard signature[currentSignatureIndex] == .signature else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: Signature.self)
        }

        // Read the signature length byte
        let sigLength = Int(data[currentDataIndex])
        currentDataIndex += 1

        // Read the signature string (without the length byte)
        let signatureEndIndex = currentDataIndex + sigLength
        guard signatureEndIndex <= data.endIndex else {
            throw DeserializerError.invalidValue(forType: Signature.self)
        }

        let signatureString =
            String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8) ?? ""
        guard let signature = Signature(rawValue: signatureString) else {
            throw DeserializerError.invalidValue(forType: Signature.self)
        }

        defer {
            currentDataIndex = signatureEndIndex + 1  // +1 for null terminator
            currentSignatureIndex += 1
        }

        return signature
    }

    // MARK: - Variants

    /// Decode the next element as a `DBusVariant`.
    public mutating func unserialize() throws -> Variant {
        guard signature[currentSignatureIndex] == .variant else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: Variant.self)
        }

        // Read the signature length byte
        let sigLength = Int(data[currentDataIndex])
        currentDataIndex += 1

        // Read the signature string (without the length byte)
        let signatureEndIndex = currentDataIndex + sigLength
        guard signatureEndIndex <= data.endIndex else {
            throw DeserializerError.invalidValue(forType: Variant.self)
        }

        let signatureString =
            String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8) ?? ""
        guard let signature = Signature(rawValue: signatureString) else {
            throw DeserializerError.invalidValue(forType: Variant.self)
        }

        // Move past the signature string and null terminator
        currentDataIndex = signatureEndIndex + 1

        // Apply alignment for the value based on the signature
        guard let signatureElement = signature.element else {
            throw DeserializerError.invalidValue(forType: Variant.self)
        }

        // Apply padding based on relative position within variant data (like serializer does)
        let variantDataSize = sigLength + 2  // signature length + signature + null terminator
        let alignment = signatureElement.alignment
        let paddingNeeded = (alignment - (variantDataSize % alignment)) % alignment
        currentDataIndex += paddingNeeded

        // Deserialize the variant value based on its signature
        let variantValue = try deserializeVariantValue(
            signatureElement: signatureElement, signature: signature)

        defer {
            currentSignatureIndex += 1
        }

        return Variant(value: variantValue, signature: signature)
    }

    /// Helper method to deserialize a variant value based on its signature element
    private mutating func deserializeVariantValue(
        signatureElement: SignatureElement, signature: Signature
    ) throws -> VariantValue {
        switch signatureElement {
        case .byte:
            let endIndex = currentDataIndex + MemoryLayout<UInt8>.stride
            guard endIndex <= data.endIndex else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }
            let value: UInt8 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .byte(value)
        case .bool:
            let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
            let value: Bool = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .bool(value)
        case .int16:
            let endIndex = currentDataIndex + MemoryLayout<Int16>.stride
            let value: Int16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .int16(value)
        case .uint16:
            let endIndex = currentDataIndex + MemoryLayout<UInt16>.stride
            let value: UInt16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .uint16(value)
        case .int32:
            let endIndex = currentDataIndex + MemoryLayout<Int32>.stride
            let value: Int32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .int32(value)
        case .uint32:
            let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
            let value: UInt32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .uint32(value)
        case .int64:
            let endIndex = currentDataIndex + MemoryLayout<Int64>.stride
            let value: Int64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .int64(value)
        case .uint64:
            let endIndex = currentDataIndex + MemoryLayout<UInt64>.stride
            let value: UInt64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .uint64(value)
        case .double:
            let endIndex = currentDataIndex + MemoryLayout<Double>.stride
            let value: Double = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
            currentDataIndex = endIndex
            return .double(value)
        case .string:
            let lengthStartIndex = currentDataIndex
            let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
            guard lengthEndIndex <= data.endIndex else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }
            let lengthBytes = [UInt8](data[lengthStartIndex..<lengthEndIndex])
            let length: UInt32 = unmarshal(lengthBytes)
            let stringEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride + Int(length)
            guard stringEndIndex + 1 <= data.endIndex else {  // +1 to ensure null terminator exists
                throw DeserializerError.invalidValue(forType: Variant.self)
            }
            let stringValue: String = unmarshal([UInt8](data[lengthStartIndex..<stringEndIndex]))
            currentDataIndex = stringEndIndex + 1  // +1 to skip null terminator
            return .string(stringValue)
        case .objectPath:
            let lengthStartIndex = currentDataIndex
            let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
            let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))
            let pathEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride + Int(length)
            let pathValue: ObjectPath = try unmarshal(
                [UInt8](data[lengthStartIndex..<pathEndIndex]))
            currentDataIndex = pathEndIndex + 1
            return .objectPath(pathValue)
        case .signature:
            // Read the signature length byte
            let sigLength = Int(data[currentDataIndex])
            currentDataIndex += 1

            // Read the signature string (without the length byte)
            let signatureEndIndex = currentDataIndex + sigLength
            guard signatureEndIndex <= data.endIndex else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }

            let signatureString =
                String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8) ?? ""
            guard let signatureValue = Signature(rawValue: signatureString) else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }

            currentDataIndex = signatureEndIndex + 1  // +1 for null terminator
            return .signature(signatureValue)
        case .array(let elementType):
            // Read array length
            let lengthEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
            let length: UInt32 = unmarshal([UInt8](data[currentDataIndex..<lengthEndIndex]))

            currentDataIndex = lengthEndIndex
            let dataEndIndex = currentDataIndex + Int(length)

            guard dataEndIndex <= data.endIndex else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }

            // Apply alignment for first element
            // The alignment should be calculated from the start of the array data
            // after the array length field
            let arrayDataStart = currentDataIndex - MemoryLayout<UInt32>.stride
            let alignment = elementType.alignment
            let paddingNeeded = (alignment - (arrayDataStart % alignment)) % alignment
            currentDataIndex += paddingNeeded

            // Deserialize each element (elements are packed consecutively)
            var elements: [VariantValue] = []
            while currentDataIndex < dataEndIndex {
                let elementSignature = Signature(elements: [elementType])
                let elementValue = try deserializeVariantValue(
                    signatureElement: elementType, signature: elementSignature)
                elements.append(elementValue)

                // Add padding for string elements to maintain 4-byte alignment (except for the last element)
                if elementType == .string && currentDataIndex < dataEndIndex {
                    let padding = (4 - (currentDataIndex % 4)) % 4
                    currentDataIndex += padding
                }
            }

            return .array(elements)
        case .dictionary(let keyType, let valueType):
            // Read dictionary length
            let lengthEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
            let length: UInt32 = unmarshal([UInt8](data[currentDataIndex..<lengthEndIndex]))

            currentDataIndex = lengthEndIndex
            let dataEndIndex = currentDataIndex + Int(length)

            guard dataEndIndex <= data.endIndex else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }

            // Apply 8-byte alignment for first dictionary entry
            let paddingNeeded = (8 - (currentDataIndex % 8)) % 8
            currentDataIndex += paddingNeeded

            // Deserialize each key-value pair
            var dictionary: [String: VariantValue] = [:]
            while currentDataIndex < dataEndIndex {
                // Apply 8-byte alignment for each dictionary entry
                let entryPadding = (8 - (currentDataIndex % 8)) % 8
                currentDataIndex += entryPadding

                // Deserialize key (must be string for now)
                guard case .string = keyType else {
                    throw DeserializerError.cannotUnmarshalType(type: Variant.self)
                }

                let keySignature = Signature(elements: [keyType])
                let keyValue = try deserializeVariantValue(
                    signatureElement: keyType, signature: keySignature)

                guard case .string(let keyString) = keyValue else {
                    throw DeserializerError.invalidValue(forType: Variant.self)
                }

                // Deserialize value
                let valueSignature = Signature(elements: [valueType])
                let valueValue = try deserializeVariantValue(
                    signatureElement: valueType, signature: valueSignature)

                dictionary[keyString] = valueValue
            }

            return .dictionary(dictionary)
        case .struct(let elementTypes):
            // Apply 8-byte alignment for struct
            let paddingNeeded = (8 - (currentDataIndex % 8)) % 8
            currentDataIndex += paddingNeeded

            // Deserialize each struct element
            var elements: [VariantValue] = []
            for elementType in elementTypes {
                // Apply alignment for each element
                let alignment = elementType.alignment
                let elementPadding = (alignment - (currentDataIndex % alignment)) % alignment
                currentDataIndex += elementPadding

                let elementSignature = Signature(elements: [elementType])
                let elementValue = try deserializeVariantValue(
                    signatureElement: elementType, signature: elementSignature)
                elements.append(elementValue)
            }

            return .struct(elements)
        case .variant:
            // Nested variant - read signature and deserialize recursively
            let sigLength = Int(data[currentDataIndex])
            currentDataIndex += 1

            let signatureEndIndex = currentDataIndex + sigLength
            guard signatureEndIndex <= data.endIndex else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }

            let signatureString =
                String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8) ?? ""
            guard let nestedSignature = Signature(rawValue: signatureString) else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }

            currentDataIndex = signatureEndIndex + 1

            guard let nestedElement = nestedSignature.element else {
                throw DeserializerError.invalidValue(forType: Variant.self)
            }

            // Apply alignment for nested variant value
            let nestedAlignment = nestedElement.alignment
            let nestedPadding =
                (nestedAlignment - (currentDataIndex % nestedAlignment)) % nestedAlignment
            currentDataIndex += nestedPadding

            // Deserialize the nested variant value
            return try deserializeVariantValue(
                signatureElement: nestedElement, signature: nestedSignature)
        default:
            throw DeserializerError.cannotUnmarshalType(type: Variant.self)
        }
    }

    // MARK: - Dictionary types

    /// Decode the next element as a dictionary of (`K`, `V`).
    public mutating func unserialize<K: Hashable, V>() throws -> [K: V] {
        guard case .dictionary(let keyElement, let valueElement) = signature[currentSignatureIndex]
        else {
            throw DeserializerError.signatureElementMismatch(
                gotElement: signature[currentSignatureIndex],
                forType: [K: V].self)
        }

        defer { currentSignatureIndex += 1 }

        let lengthStartIndex = currentDataIndex
        let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
        let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))

        currentDataIndex += MemoryLayout<UInt32>.stride

        // Apply 8-byte alignment for dictionary data start
        let paddingNeeded = (8 - (currentDataIndex % 8)) % 8
        currentDataIndex += paddingNeeded

        let dictDataStart = currentDataIndex
        let dataEndIndex = dictDataStart + Int(length)

        var dictionary: [K: V] = [:]

        while currentDataIndex < dataEndIndex {
            // Apply padding relative to dictionary data start (like serializer does)
            let dictDataOffset = currentDataIndex - dictDataStart
            let entryPaddingNeeded = (8 - (dictDataOffset % 8)) % 8

            currentDataIndex += entryPaddingNeeded

            // Deserialize key
            let key: K
            switch keyElement {
            case .string:
                let keyLengthEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                guard keyLengthEndIndex <= data.endIndex else {
                    throw DeserializerError.invalidValue(forType: K.self)
                }
                let keyLength: UInt32 = unmarshal(
                    [UInt8](data[currentDataIndex..<keyLengthEndIndex]))
                let keyDataEndIndex =
                    currentDataIndex + MemoryLayout<UInt32>.stride + Int(keyLength)
                guard keyDataEndIndex + 1 <= data.endIndex else {  // +1 to ensure null terminator exists
                    throw DeserializerError.invalidValue(forType: K.self)
                }
                let keyValue: String = unmarshal([UInt8](data[currentDataIndex..<keyDataEndIndex]))
                key = keyValue as! K
                currentDataIndex = keyDataEndIndex + 1  // +1 to skip null terminator

            default:
                throw DeserializerError.cannotUnmarshalType(type: K.self)
            }

            // Deserialize value
            let value: V
            switch valueElement {
            case .variant:
                // For variants, we need to handle the nested signature
                let signatureStartIndex = currentDataIndex
                guard signatureStartIndex + 1 < data.endIndex else {
                    throw DeserializerError.invalidValue(forType: V.self)
                }

                // Read the signature length byte
                let sigLength = Int(data[currentDataIndex])
                currentDataIndex += 1

                // Read the signature string (without the length byte)
                let signatureEndIndex = currentDataIndex + sigLength
                guard signatureEndIndex <= data.endIndex else {
                    throw DeserializerError.invalidValue(forType: V.self)
                }

                let signatureBytes = data[currentDataIndex..<signatureEndIndex]
                let signatureString =
                    String(bytes: signatureBytes, encoding: .utf8) ?? ""
                guard let variantSignature = Signature(rawValue: signatureString) else {
                    throw DeserializerError.invalidValue(forType: V.self)
                }

                // Move past the signature string and null terminator
                currentDataIndex = signatureEndIndex + 1

                guard let variantElement = variantSignature.element else {
                    throw DeserializerError.invalidValue(forType: V.self)
                }

                // Apply padding based on relative position within variant data (like serializer does)
                let variantDataSize = sigLength + 2  // signature length + signature + null terminator
                let alignment = variantElement.alignment
                let paddingNeeded = (alignment - (variantDataSize % alignment)) % alignment
                currentDataIndex += paddingNeeded

                let variantValue: Variant
                switch variantElement {
                case .byte:
                    let endIndex = currentDataIndex + MemoryLayout<UInt8>.stride
                    let byteValue: UInt8 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(byteValue, signature: variantSignature)
                    currentDataIndex = endIndex
                case .bool:
                    let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                    let boolValue: Bool = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(boolValue, signature: variantSignature)
                    currentDataIndex = endIndex
                case .int16:
                    let endIndex = currentDataIndex + MemoryLayout<Int16>.stride
                    let int16Value: Int16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(int16Value, signature: variantSignature)
                    currentDataIndex = endIndex
                case .uint16:
                    let endIndex = currentDataIndex + MemoryLayout<UInt16>.stride
                    let uint16Value: UInt16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(uint16Value, signature: variantSignature)
                    currentDataIndex = endIndex
                case .int32:
                    let endIndex = currentDataIndex + MemoryLayout<Int32>.stride
                    let int32Value: Int32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(int32Value, signature: variantSignature)
                    currentDataIndex = endIndex
                case .uint32:
                    let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                    let uint32Value: UInt32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(uint32Value, signature: variantSignature)
                    currentDataIndex = endIndex
                case .int64:
                    let endIndex = currentDataIndex + MemoryLayout<Int64>.stride
                    let int64Value: Int64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(int64Value, signature: variantSignature)
                    currentDataIndex = endIndex
                case .uint64:
                    let endIndex = currentDataIndex + MemoryLayout<UInt64>.stride
                    let uint64Value: UInt64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(uint64Value, signature: variantSignature)
                    currentDataIndex = endIndex
                case .double:
                    let endIndex = currentDataIndex + MemoryLayout<Double>.stride
                    let doubleValue: Double = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    variantValue = try Variant(doubleValue, signature: variantSignature)
                    currentDataIndex = endIndex
                case .string:
                    let lengthStartIndex = currentDataIndex
                    let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
                    guard lengthEndIndex <= data.endIndex else {
                        throw DeserializerError.invalidValue(forType: V.self)
                    }
                    let lengthBytes = [UInt8](data[lengthStartIndex..<lengthEndIndex])
                    let length: UInt32 = unmarshal(lengthBytes)
                    let stringEndIndex =
                        lengthStartIndex + MemoryLayout<UInt32>.stride + Int(length)
                    guard stringEndIndex <= data.endIndex else {
                        throw DeserializerError.invalidValue(forType: V.self)
                    }
                    let stringValue: String = unmarshal(
                        [UInt8](data[lengthStartIndex..<stringEndIndex]))
                    variantValue = try Variant(stringValue, signature: variantSignature)
                    currentDataIndex = stringEndIndex + 1
                case .objectPath:
                    let lengthStartIndex = currentDataIndex
                    let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
                    let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))
                    let pathEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride + Int(length)
                    let value: ObjectPath = try unmarshal(
                        [UInt8](data[lengthStartIndex..<pathEndIndex]))
                    variantValue = try Variant(value, signature: variantSignature)
                    currentDataIndex = pathEndIndex + 1
                case .signature:
                    // Read the signature length byte
                    let sigLength = Int(data[currentDataIndex])
                    currentDataIndex += 1

                    // Read the signature string (without the length byte)
                    let signatureEndIndex = currentDataIndex + sigLength
                    guard signatureEndIndex <= data.endIndex else {
                        throw DeserializerError.invalidValue(forType: V.self)
                    }

                    let signatureString =
                        String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8)
                        ?? ""
                    guard let signatureValue = Signature(rawValue: signatureString) else {
                        throw DeserializerError.invalidValue(forType: V.self)
                    }

                    variantValue = try Variant(signatureValue, signature: variantSignature)
                    currentDataIndex = signatureEndIndex + 1  // +1 for null terminator
                case .array:
                    // Properly deserialize array variants using the new helper method
                    let arrayValue = try deserializeVariantValue(
                        signatureElement: variantElement, signature: variantSignature)
                    variantValue = Variant(value: arrayValue, signature: variantSignature)
                default:
                    throw DeserializerError.cannotUnmarshalType(type: V.self)
                }
                value = variantValue as! V
            case .string:
                let lengthStartIndex = currentDataIndex
                let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
                guard lengthEndIndex <= data.endIndex else {
                    throw DeserializerError.invalidValue(forType: V.self)
                }
                let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))
                let stringEndIndex =
                    lengthStartIndex + MemoryLayout<UInt32>.stride + Int(length)
                guard stringEndIndex + 1 <= data.endIndex else {  // +1 to ensure null terminator exists
                    throw DeserializerError.invalidValue(forType: V.self)
                }
                let stringValue: String = unmarshal(
                    [UInt8](data[lengthStartIndex..<stringEndIndex]))
                value = stringValue as! V
                currentDataIndex = stringEndIndex + 1  // +1 to skip null terminator
            default:
                throw DeserializerError.cannotUnmarshalType(type: V.self)
            }

            dictionary[key] = value
        }

        currentDataIndex = dataEndIndex
        return dictionary
    }

    /// Unmarshal `bytes` as `T`.
    private func unmarshal<T>(_ bytes: [UInt8]) throws -> T {
        switch T.self {
        case is Bool.Type:
            let value: Bool = unmarshal(bytes)
            return value as! T
        case is UInt8.Type:
            let value: UInt8 = unmarshal(bytes)
            return value as! T
        case is UInt16.Type:
            let value: UInt16 = unmarshal(bytes)
            return value as! T
        case is UInt32.Type:
            let value: UInt32 = unmarshal(bytes)
            return value as! T
        case is Int16.Type:
            let value: Int16 = unmarshal(bytes)
            return value as! T
        case is Int32.Type:
            let value: Int32 = unmarshal(bytes)
            return value as! T
        case is Int64.Type:
            let value: Int64 = unmarshal(bytes)
            return value as! T
        case is Double.Type:
            let value: Double = unmarshal(bytes)
            return value as! T
        case is String.Type:
            let value: String = unmarshal(bytes)
            return value as! T
        case is ObjectPath.Type:
            let value: ObjectPath = try unmarshal(bytes)
            return value as! T
        case is Signature.Type:
            // Parse signature: length byte + signature string + null terminator
            let sigLength = Int(bytes[0])
            let signatureString = String(bytes: bytes[1..<1 + sigLength], encoding: .utf8) ?? ""
            guard let signature = Signature(rawValue: signatureString) else {
                throw DeserializerError.invalidValue(forType: T.self)
            }
            return signature as! T
        default:
            throw DeserializerError.cannotUnmarshalType(type: T.self)
        }
    }

    // MARK: - Array Types

    /// Decode the next element as an `Array<T>`.
    public mutating func unserialize<T>() throws -> [T] {
        guard case .array(let arrayElement) = signature[currentSignatureIndex] else {
            throw
                DeserializerError
                .signatureElementMismatch(
                    gotElement: signature[currentSignatureIndex],
                    forType: [T].self)
        }
        let lengthStartIndex = currentDataIndex
        let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride

        // Check if we have enough data to read the length field
        guard lengthEndIndex <= data.endIndex else {
            throw DeserializerError.invalidValue(forType: [T].self)
        }

        let lengthBytes = [UInt8](data[lengthStartIndex..<lengthEndIndex])
        let length: UInt32 = unmarshal(lengthBytes)

        currentDataIndex += MemoryLayout<UInt32>.stride
        let dataEndIndex = currentDataIndex + Int(length)

        // Check if the claimed array length exceeds available data
        guard dataEndIndex <= data.endIndex else {
            throw DeserializerError.invalidValue(forType: [T].self)
        }

        defer {
            currentDataIndex = dataEndIndex
            currentSignatureIndex += 1
        }

        switch arrayElement {
        case .bool:
            var elements: [Bool] = []
            while currentDataIndex < dataEndIndex {
                let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                let value: Bool = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                elements.append(value)
                currentDataIndex += MemoryLayout<UInt32>.stride
            }
            return elements as! [T]
        case .byte, .int16, .int32, .int64, .uint16, .uint32, .uint64, .double, .unixFD:
            var elements: [T] = []
            while currentDataIndex < dataEndIndex {
                let endIndex = currentDataIndex + MemoryLayout<T>.stride
                let value: T = try unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                elements.append(value)
                currentDataIndex += MemoryLayout<T>.stride
            }
            return elements
        case .string:
            var elements: [String] = []
            while currentDataIndex < dataEndIndex {
                // Unmarshal the length of the string
                let lengthStartIndex = currentDataIndex
                let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride

                // Check bounds before reading length
                guard lengthEndIndex <= dataEndIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))

                // Find the end of the string content
                let stringDataEndIndex =
                    currentDataIndex + MemoryLayout<UInt32>.stride + Int(length)

                // Check bounds before reading string data + null terminator
                guard stringDataEndIndex + 1 <= dataEndIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                let value: String = unmarshal([UInt8](data[lengthStartIndex..<stringDataEndIndex]))
                elements.append(value)
                currentDataIndex = stringDataEndIndex + 1

                // Apply padding to 4-byte boundary for next string
                let padding = (4 - (currentDataIndex % 4)) % 4
                currentDataIndex += padding
            }
            return elements as! [T]
        case .objectPath:
            var elements: [ObjectPath] = []
            while currentDataIndex < dataEndIndex {
                // Unmarshal the length of the string
                let lengthStartIndex = currentDataIndex
                let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride

                // Check bounds for length field
                guard lengthEndIndex <= dataEndIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))

                // Find the end of the string content
                let stringDataEndIndex =
                    currentDataIndex + MemoryLayout<UInt32>.stride + Int(length)

                // Check bounds for string data + null terminator
                guard stringDataEndIndex + 1 <= dataEndIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                let value: ObjectPath = try unmarshal(
                    [UInt8](data[lengthStartIndex..<stringDataEndIndex]))
                elements.append(value)
                currentDataIndex = stringDataEndIndex + 1

                // Apply padding to 4-byte boundary for next object path
                let padding = (4 - (currentDataIndex % 4)) % 4
                currentDataIndex += padding
            }
            return elements as! [T]
        case .signature:
            var elements: [Signature] = []
            while currentDataIndex < dataEndIndex {
                // Read the signature length byte
                guard currentDataIndex < dataEndIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                let sigLength = Int(data[currentDataIndex])
                currentDataIndex += 1

                // Read the signature string (without the length byte)
                let signatureEndIndex = currentDataIndex + sigLength
                guard signatureEndIndex <= dataEndIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                // Also check bounds for null terminator
                guard signatureEndIndex + 1 <= dataEndIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                let signatureString =
                    String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8) ?? ""
                guard let signature = Signature(rawValue: signatureString) else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                elements.append(signature)
                currentDataIndex = signatureEndIndex + 1  // +1 for null terminator
            }
            return elements as! [T]
        case .variant:
            var elements: [Variant] = []
            while currentDataIndex < dataEndIndex {
                // Read the signature length byte
                let sigLength = Int(data[currentDataIndex])
                currentDataIndex += 1

                // Read the signature string (without the length byte)
                let signatureEndIndex = currentDataIndex + sigLength
                guard signatureEndIndex <= data.endIndex else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                let signatureString =
                    String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8) ?? ""
                guard let signature = Signature(rawValue: signatureString) else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                // Move past the signature string and null terminator
                currentDataIndex = signatureEndIndex + 1

                // Apply alignment for the value based on the signature
                guard let signatureElement = signature.element else {
                    throw DeserializerError.invalidValue(forType: [T].self)
                }

                // Apply padding based on relative position within variant data (like serializer does)
                let variantDataSize = sigLength + 2  // signature length + signature + null terminator
                let alignment = signatureElement.alignment
                let paddingNeeded = (alignment - (variantDataSize % alignment)) % alignment
                currentDataIndex += paddingNeeded

                switch signatureElement {
                case .byte:
                    let endIndex = currentDataIndex + MemoryLayout<UInt8>.stride
                    let value: UInt8 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .bool:
                    let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                    let value: Bool = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .int16:
                    let endIndex = currentDataIndex + MemoryLayout<Int16>.stride
                    let value: Int16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .uint16:
                    let endIndex = currentDataIndex + MemoryLayout<UInt16>.stride
                    let value: UInt16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .int32:
                    let endIndex = currentDataIndex + MemoryLayout<Int32>.stride
                    let value: Int32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .uint32:
                    let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                    let value: UInt32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .int64:
                    let endIndex = currentDataIndex + MemoryLayout<Int64>.stride
                    let value: Int64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .uint64:
                    let endIndex = currentDataIndex + MemoryLayout<UInt64>.stride
                    let value: UInt64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .double:
                    let endIndex = currentDataIndex + MemoryLayout<Double>.stride
                    let value: Double = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                case .string:
                    let lengthStartIndex = currentDataIndex
                    let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride

                    // Check bounds for length field
                    guard lengthEndIndex <= dataEndIndex else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))
                    let stringEndIndex =
                        currentDataIndex + MemoryLayout<UInt32>.stride + Int(length)

                    // Check bounds for string data + null terminator
                    guard stringEndIndex + 1 <= dataEndIndex else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    let value: String = unmarshal([UInt8](data[lengthStartIndex..<stringEndIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = stringEndIndex + 1
                case .objectPath:
                    let lengthStartIndex = currentDataIndex
                    let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride

                    // Check bounds for length field
                    guard lengthEndIndex <= dataEndIndex else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    let length: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))
                    let pathEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride + Int(length)

                    // Check bounds for path data + null terminator
                    guard pathEndIndex + 1 <= dataEndIndex else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    let value: ObjectPath = try unmarshal(
                        [UInt8](data[lengthStartIndex..<pathEndIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = pathEndIndex + 1
                case .signature:
                    // Read the signature length byte
                    guard currentDataIndex < dataEndIndex else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    let sigLength = Int(data[currentDataIndex])
                    currentDataIndex += 1

                    // Read the signature string (without the length byte)
                    let signatureEndIndex = currentDataIndex + sigLength
                    guard signatureEndIndex <= dataEndIndex else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    // Also check bounds for null terminator
                    guard signatureEndIndex + 1 <= dataEndIndex else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    let signatureString =
                        String(bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8)
                        ?? ""
                    guard let signatureValue = Signature(rawValue: signatureString) else {
                        throw DeserializerError.invalidValue(forType: [T].self)
                    }

                    elements.append(try Variant(signatureValue, signature: signature))
                    currentDataIndex = signatureEndIndex + 1  // +1 for null terminator
                case .unixFD:
                    let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                    let value: UInt32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                    elements.append(try Variant(value, signature: signature))
                    currentDataIndex = endIndex
                default:
                    // For complex types (arrays, dictionaries, structs, variants),
                    // we would need more sophisticated handling
                    throw DeserializerError.cannotUnmarshalType(type: T.self)
                }
            }
            return elements as! [T]
        case .array(let nestedArrayElement):
            var elements: [[Any]] = []
            while currentDataIndex < dataEndIndex {
                pad(to: 4)  // Arrays are aligned to 4-byte boundaries

                // Read the length of this nested array
                let lengthStartIndex = currentDataIndex
                let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
                let nestedLength: UInt32 = unmarshal(
                    [UInt8](data[lengthStartIndex..<lengthEndIndex]))

                currentDataIndex += MemoryLayout<UInt32>.stride
                let nestedEndIndex = currentDataIndex + Int(nestedLength)

                // Create a nested deserializer for this array
                var nestedDeserializer = Deserializer(
                    data: [UInt8](data[currentDataIndex..<nestedEndIndex]),
                    signature: Signature(elements: [nestedArrayElement]),
                    endianness: endianness,
                    alignmentContext: .structContent
                )

                // Deserialize the nested array based on its element type
                switch nestedArrayElement {
                case .byte:
                    let nestedArray: [UInt8] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .bool:
                    let nestedArray: [Bool] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .int16:
                    let nestedArray: [Int16] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .uint16:
                    let nestedArray: [UInt16] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .int32:
                    let nestedArray: [Int32] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .uint32:
                    let nestedArray: [UInt32] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .int64:
                    let nestedArray: [Int64] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .uint64:
                    let nestedArray: [UInt64] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .double:
                    let nestedArray: [Double] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .string:
                    let nestedArray: [String] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .objectPath:
                    let nestedArray: [ObjectPath] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .signature:
                    let nestedArray: [Signature] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                case .unixFD:
                    let nestedArray: [UInt32] = try nestedDeserializer.unserialize()
                    elements.append(nestedArray)
                default:
                    throw DeserializerError.cannotUnmarshalType(type: Array<Any>.self)
                }

                currentDataIndex = nestedEndIndex
            }
            return elements as! [T]
        case .dictionary(let keyElement, let valueElement):
            var elements: [[String: Any]] = []
            while currentDataIndex < dataEndIndex {
                pad(to: 8)  // Dictionary entries are aligned to 8-byte boundaries

                // Read the length of this dictionary entry
                let lengthStartIndex = currentDataIndex
                let lengthEndIndex = lengthStartIndex + MemoryLayout<UInt32>.stride
                let dictLength: UInt32 = unmarshal([UInt8](data[lengthStartIndex..<lengthEndIndex]))

                currentDataIndex += MemoryLayout<UInt32>.stride
                let dictEndIndex = currentDataIndex + Int(dictLength)

                var dictEntries: [String: Any] = [:]

                // Parse dictionary entries (each entry is a struct with key and value)
                while currentDataIndex < dictEndIndex {
                    pad(to: 8)  // Dict entry struct alignment

                    // Deserialize key
                    let keyStartIndex = currentDataIndex
                    let key: String
                    switch keyElement {
                    case .string:
                        let keyLengthEndIndex = keyStartIndex + MemoryLayout<UInt32>.stride
                        let keyLength: UInt32 = unmarshal(
                            [UInt8](data[keyStartIndex..<keyLengthEndIndex]))
                        let keyDataEndIndex =
                            keyStartIndex + MemoryLayout<UInt32>.stride + Int(keyLength) + 1  // +1 for null terminator
                        key = unmarshal([UInt8](data[keyStartIndex..<keyDataEndIndex]))
                        currentDataIndex = keyDataEndIndex
                    case .byte:
                        let keyEndIndex = keyStartIndex + MemoryLayout<UInt8>.stride
                        let keyValue: UInt8 = unmarshal([UInt8](data[keyStartIndex..<keyEndIndex]))
                        key = String(keyValue)
                        currentDataIndex = keyEndIndex
                    case .int32:
                        let keyEndIndex = keyStartIndex + MemoryLayout<Int32>.stride
                        let keyValue: Int32 = unmarshal([UInt8](data[keyStartIndex..<keyEndIndex]))
                        key = String(keyValue)
                        currentDataIndex = keyEndIndex
                    case .uint32:
                        let keyEndIndex = keyStartIndex + MemoryLayout<UInt32>.stride
                        let keyValue: UInt32 = unmarshal([UInt8](data[keyStartIndex..<keyEndIndex]))
                        key = String(keyValue)
                        currentDataIndex = keyEndIndex
                    default:
                        throw DeserializerError.cannotUnmarshalType(type: String.self)
                    }

                    pad(to: valueElement.alignment)

                    // Deserialize value
                    let value: Any
                    switch valueElement {
                    case .byte:
                        let valueEndIndex = currentDataIndex + MemoryLayout<UInt8>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as UInt8
                        currentDataIndex = valueEndIndex
                    case .bool:
                        let valueEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as Bool
                        currentDataIndex = valueEndIndex
                    case .int16:
                        let valueEndIndex = currentDataIndex + MemoryLayout<Int16>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as Int16
                        currentDataIndex = valueEndIndex
                    case .uint16:
                        let valueEndIndex = currentDataIndex + MemoryLayout<UInt16>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as UInt16
                        currentDataIndex = valueEndIndex
                    case .int32:
                        let valueEndIndex = currentDataIndex + MemoryLayout<Int32>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as Int32
                        currentDataIndex = valueEndIndex
                    case .uint32:
                        let valueEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as UInt32
                        currentDataIndex = valueEndIndex
                    case .int64:
                        let valueEndIndex = currentDataIndex + MemoryLayout<Int64>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as Int64
                        currentDataIndex = valueEndIndex
                    case .uint64:
                        let valueEndIndex = currentDataIndex + MemoryLayout<UInt64>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as UInt64
                        currentDataIndex = valueEndIndex
                    case .double:
                        let valueEndIndex = currentDataIndex + MemoryLayout<Double>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as Double
                        currentDataIndex = valueEndIndex
                    case .string:
                        let valueLengthEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        let valueLength: UInt32 = unmarshal(
                            [UInt8](data[currentDataIndex..<valueLengthEndIndex]))
                        let valueDataEndIndex =
                            currentDataIndex + MemoryLayout<UInt32>.stride + Int(valueLength)
                        value =
                            unmarshal([UInt8](data[currentDataIndex..<valueDataEndIndex])) as String
                        currentDataIndex = valueDataEndIndex + 1
                    case .objectPath:
                        let valueLengthEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        let valueLength: UInt32 = unmarshal(
                            [UInt8](data[currentDataIndex..<valueLengthEndIndex]))
                        let valueDataEndIndex =
                            currentDataIndex + MemoryLayout<UInt32>.stride + Int(valueLength)
                        value =
                            try unmarshal([UInt8](data[currentDataIndex..<valueDataEndIndex]))
                            as ObjectPath
                        currentDataIndex = valueDataEndIndex + 1
                    case .signature:
                        // Read the signature length byte
                        let sigLength = Int(data[currentDataIndex])
                        currentDataIndex += 1

                        // Read the signature string (without the length byte)
                        let signatureEndIndex = currentDataIndex + sigLength
                        guard signatureEndIndex <= data.endIndex else {
                            throw DeserializerError.invalidValue(forType: [String: Any].self)
                        }

                        let signatureString =
                            String(
                                bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8)
                            ?? ""
                        guard let signatureValue = Signature(rawValue: signatureString) else {
                            throw DeserializerError.invalidValue(forType: [String: Any].self)
                        }

                        value = signatureValue
                        currentDataIndex = signatureEndIndex + 1  // +1 for null terminator
                    case .unixFD:
                        let valueEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        value = unmarshal([UInt8](data[currentDataIndex..<valueEndIndex])) as UInt32
                        currentDataIndex = valueEndIndex
                    default:
                        throw DeserializerError.cannotUnmarshalType(type: Any.self)
                    }

                    dictEntries[key] = value
                }

                elements.append(dictEntries)
                currentDataIndex = dictEndIndex
            }
            return elements as! [T]
        case .struct(let structElements):
            var elements: [[Any]] = []
            while currentDataIndex < dataEndIndex {
                pad(to: 8)  // Structs are aligned to 8-byte boundaries

                var structValues: [Any] = []

                // Deserialize each element in the struct
                for element in structElements {
                    pad(to: element.alignment)

                    switch element {
                    case .byte:
                        let endIndex = currentDataIndex + MemoryLayout<UInt8>.stride
                        let value: UInt8 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .bool:
                        let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        let value: Bool = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .int16:
                        let endIndex = currentDataIndex + MemoryLayout<Int16>.stride
                        let value: Int16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .uint16:
                        let endIndex = currentDataIndex + MemoryLayout<UInt16>.stride
                        let value: UInt16 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .int32:
                        let endIndex = currentDataIndex + MemoryLayout<Int32>.stride
                        let value: Int32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .uint32:
                        let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        let value: UInt32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .int64:
                        let endIndex = currentDataIndex + MemoryLayout<Int64>.stride
                        let value: Int64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .uint64:
                        let endIndex = currentDataIndex + MemoryLayout<UInt64>.stride
                        let value: UInt64 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .double:
                        let endIndex = currentDataIndex + MemoryLayout<Double>.stride
                        let value: Double = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    case .string:
                        let lengthEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        let length: UInt32 = unmarshal(
                            [UInt8](data[currentDataIndex..<lengthEndIndex]))
                        let stringEndIndex =
                            currentDataIndex + MemoryLayout<UInt32>.stride + Int(length)
                        let value: String = unmarshal(
                            [UInt8](data[currentDataIndex..<stringEndIndex]))
                        structValues.append(value)
                        currentDataIndex = stringEndIndex + 1
                    case .objectPath:
                        let lengthEndIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        let length: UInt32 = unmarshal(
                            [UInt8](data[currentDataIndex..<lengthEndIndex]))
                        let pathEndIndex =
                            currentDataIndex + MemoryLayout<UInt32>.stride + Int(length)
                        let value: ObjectPath = try unmarshal(
                            [UInt8](data[currentDataIndex..<pathEndIndex]))
                        structValues.append(value)
                        currentDataIndex = pathEndIndex + 1
                    case .signature:
                        // Read the signature length byte
                        let sigLength = Int(data[currentDataIndex])
                        currentDataIndex += 1

                        // Read the signature string (without the length byte)
                        let signatureEndIndex = currentDataIndex + sigLength
                        guard signatureEndIndex <= data.endIndex else {
                            throw DeserializerError.invalidValue(forType: [Any].self)
                        }

                        let signatureString =
                            String(
                                bytes: data[currentDataIndex..<signatureEndIndex], encoding: .utf8)
                            ?? ""
                        guard let signatureValue = Signature(rawValue: signatureString) else {
                            throw DeserializerError.invalidValue(forType: [Any].self)
                        }

                        structValues.append(signatureValue)
                        currentDataIndex = signatureEndIndex + 1  // +1 for null terminator
                    case .unixFD:
                        let endIndex = currentDataIndex + MemoryLayout<UInt32>.stride
                        let value: UInt32 = unmarshal([UInt8](data[currentDataIndex..<endIndex]))
                        structValues.append(value)
                        currentDataIndex = endIndex
                    default:
                        throw DeserializerError.cannotUnmarshalType(type: Any.self)
                    }
                }

                elements.append(structValues)
            }
            return elements as! [T]
        }
    }

    /// Interprets bytes from `data` as a value of the specified fixed-width integer type by
    /// initializing values one byte at a time and ORing the result to the previous value.
    private func load<T: FixedWidthInteger>(from data: [UInt8]) -> T {
        precondition(data.count == T.bitWidth / 8)

        var value: T = 0
        for i in 0..<data.count {
            switch endianness {
            case .littleEndian:
                value |= T(data[i]) << (i * 8)
            case .bigEndian:
                value |= T(data[i]) << ((data.count - 1 - i) * 8)
            }
        }
        return value
    }

    /// Advances the current index through the buffer to align with the given alignment.
    ///
    /// Parameters:
    /// - alignment: Boundary within the sequence to align to a factor of
    private mutating func pad(to alignment: Int) {
        if currentDataIndex % alignment != 0 {
            let newIndex = (currentDataIndex + alignment - 1) & ~(alignment - 1)
            currentDataIndex += newIndex - currentDataIndex
        }
    }

    /// Decode a struct using a closure. If the signature is not a STRUCT container,
    /// an error is thrown. The closure is called with a deserializer initialized
    /// with the STRUCT container elements. For example, if the deserializer's
    /// signature is `(ux)`, the nested deserializer's signature will be `ux`.
    public mutating func unserialize(_ f: (inout Deserializer) throws -> Void) throws {
        guard case .struct(let structElements) = signature[currentSignatureIndex] else {
            throw DeserializerError.signatureElementMismatch(
                gotElement: signature[currentSignatureIndex],
                forType: Void.self)
        }
        defer { currentSignatureIndex += 1 }

        // Apply struct alignment - implement padding logic directly
        let alignment = signature[currentSignatureIndex].alignment
        if currentDataIndex % alignment != 0 {
            let newIndex = (currentDataIndex + alignment - 1) & ~(alignment - 1)
            currentDataIndex = newIndex
        }

        // Create a nested deserializer for the struct contents
        let structSignature = Signature(elements: structElements)
        let structDataStart = currentDataIndex

        // We need to calculate how much data this struct will consume
        // For now, we'll pass the remaining data and let the nested deserializer handle it
        let remainingData = [UInt8](data[currentDataIndex..<data.endIndex])

        var structDeserializer = Deserializer(
            data: remainingData,
            signature: structSignature,
            endianness: endianness,
            alignmentContext: .structContent
        )

        try f(&structDeserializer)

        // Update our current data index based on how much the struct consumed
        currentDataIndex = structDataStart + structDeserializer.currentDataIndex
    }
}

public enum DeserializerError: Error {
    case signatureElementMismatch(gotElement: SignatureElement, forType: Any.Type)
    case invalidValue(forType: Any.Type)
    case cannotUnmarshalType(type: Any.Type)
}
