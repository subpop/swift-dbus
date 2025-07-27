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

/// Enhanced DBusEncoder that provides better signature inference
public class DBusEncoder {
    public struct Options {
        public let alignmentContext: AlignmentContext

        public init(alignmentContext: AlignmentContext = .message) {
            self.alignmentContext = alignmentContext
        }
    }

    public var options: Options = Options()
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    /// Encodes with explicit signature
    public func encode<T: Encodable>(_ value: T, signature: Signature) throws -> [UInt8] {
        var serializer = Serializer(
            signature: signature,
            alignmentContext: options.alignmentContext,
            endianness: .littleEndian)

        // Handle DBusVariant specially - serialize directly without going through Encodable
        if let variant = value as? Variant {
            try serializer.serialize(variant)
        }
        // Handle arrays specially - check if signature is an array and type is array-like
        else if signature.rawValue.hasPrefix("a") && !signature.rawValue.hasPrefix("a{") {
            // This is an array signature, not a dictionary
            return try encodeArray(value, serializer: &serializer)
        }
        // Handle dictionaries specially - check both type and signature
        else if signature.rawValue.hasPrefix("a{") {
            // This is a dictionary signature
            return try encodeDictionary(value, serializer: &serializer)
        }
        // Handle structs specially - check if the signature is a struct by looking at the raw string
        else if signature.rawValue.hasPrefix("(") && signature.rawValue.hasSuffix(")") {
            // Use struct serialization method
            try serializer.serialize { structSerializer in
                let structEncoder = _DBusEncoder(
                    serializer: &structSerializer,
                    codingPath: [],
                    userInfo: userInfo
                )
                try value.encode(to: structEncoder)
            }
        } else {
            let encoder = _DBusEncoder(serializer: &serializer, codingPath: [], userInfo: userInfo)
            try value.encode(to: encoder)
        }

        guard let data = serializer.data else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Serialization incomplete"
                ))
        }

        return data
    }

    /// Helper method to encode arrays
    private func encodeArray<T: Encodable>(_ value: T, serializer: inout Serializer) throws
        -> [UInt8]
    {
        // Get the signature to determine the correct array type
        guard let signatureElement = serializer.signature.element,
            case .array(let arrayElement) = signatureElement
        else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Expected array signature but got: \(serializer.signature)"
                ))
        }

        // Handle empty arrays by looking at the signature element type
        if let anyArray = value as? [Any], anyArray.isEmpty {
            switch arrayElement {
            case .string:
                let emptyStringArray: [String] = []
                try serializer.serialize(emptyStringArray)
            case .bool:
                let emptyBoolArray: [Bool] = []
                try serializer.serialize(emptyBoolArray)
            case .byte:
                let emptyUInt8Array: [UInt8] = []
                try serializer.serialize(emptyUInt8Array)
            case .int16:
                let emptyInt16Array: [Int16] = []
                try serializer.serialize(emptyInt16Array)
            case .uint16:
                let emptyUInt16Array: [UInt16] = []
                try serializer.serialize(emptyUInt16Array)
            case .int32:
                let emptyInt32Array: [Int32] = []
                try serializer.serialize(emptyInt32Array)
            case .uint32:
                let emptyUInt32Array: [UInt32] = []
                try serializer.serialize(emptyUInt32Array)
            case .int64:
                let emptyInt64Array: [Int64] = []
                try serializer.serialize(emptyInt64Array)
            case .uint64:
                let emptyUInt64Array: [UInt64] = []
                try serializer.serialize(emptyUInt64Array)
            case .double:
                let emptyDoubleArray: [Double] = []
                try serializer.serialize(emptyDoubleArray)
            case .objectPath:
                let emptyObjectPathArray: [ObjectPath] = []
                try serializer.serialize(emptyObjectPathArray)
            case .signature:
                let emptySignatureArray: [Signature] = []
                try serializer.serialize(emptySignatureArray)
            case .variant:
                let emptyVariantArray: [Variant] = []
                try serializer.serialize(emptyVariantArray)
            default:
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: [],
                        debugDescription: "Unsupported empty array element type: \(arrayElement)"
                    ))
            }
        } else {
            // For non-empty arrays, use the original type casting approach
            switch value {
            case let stringArray as [String]:
                try serializer.serialize(stringArray)
            case let boolArray as [Bool]:
                try serializer.serialize(boolArray)
            case let uint8Array as [UInt8]:
                try serializer.serialize(uint8Array)
            case let int16Array as [Int16]:
                try serializer.serialize(int16Array)
            case let uint16Array as [UInt16]:
                try serializer.serialize(uint16Array)
            case let int32Array as [Int32]:
                try serializer.serialize(int32Array)
            case let uint32Array as [UInt32]:
                try serializer.serialize(uint32Array)
            case let int64Array as [Int64]:
                try serializer.serialize(int64Array)
            case let uint64Array as [UInt64]:
                try serializer.serialize(uint64Array)
            case let doubleArray as [Double]:
                try serializer.serialize(doubleArray)
            case let objectPathArray as [ObjectPath]:
                try serializer.serialize(objectPathArray)
            case let signatureArray as [Signature]:
                try serializer.serialize(signatureArray)
            case let variantArray as [Variant]:
                try serializer.serialize(variantArray)
            default:
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: [],
                        debugDescription: "Unsupported array type: \(type(of: value))"
                    ))
            }
        }

        guard let data = serializer.data else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Array serialization incomplete"
                ))
        }

        return data
    }

    /// Helper method to encode dictionaries
    private func encodeDictionary<T: Encodable>(_ value: T, serializer: inout Serializer) throws
        -> [UInt8]
    {
        // Handle specific dictionary types by casting and serializing directly
        if let stringDict = value as? [String: String] {
            try serializer.serialize(stringDict)
        } else if let variantDict = value as? [String: Variant] {
            try serializer.serialize(variantDict)
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Unsupported dictionary type: \(type(of: value))"
                ))
        }

        guard let data = serializer.data else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Dictionary serialization incomplete"
                ))
        }

        return data
    }

    /// Convenience method with signature string
    public func encode<T: Encodable>(_ value: T, signature: String) throws -> [UInt8] {
        guard let sig = Signature(rawValue: signature) else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid D-Bus signature: \(signature)"
                ))
        }
        return try encode(value, signature: sig)
    }

    /// Encode basic types with automatic signature inference
    public func encode<T: Encodable>(_ value: T) throws -> [UInt8] {
        let signature = try inferSignature(for: T.self)
        return try encode(value, signature: signature)
    }

    private func inferSignature<T>(for type: T.Type) throws -> Signature {
        if let element = SignatureElement(type) {
            return Signature(elements: [element])
        }

        // Handle arrays
        if type is [Any].Type {
            // This is a simplified approach - in practice you'd need more sophisticated type introspection
            throw EncodingError.invalidValue(
                type,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription:
                        "Cannot infer signature for array type \(type). Use explicit signature."
                ))
        }

        throw EncodingError.invalidValue(
            type,
            EncodingError.Context(
                codingPath: [],
                debugDescription:
                    "Cannot infer D-Bus signature for type \(type). Use explicit signature."
            ))
    }
}

/// Enhanced DBusDecoder with better container support
public class DBusDecoder {
    public struct Options {
        public let endianness: Endianness

        public init(endianness: Endianness = .littleEndian) {
            self.endianness = endianness
        }
    }

    public var options: Options = Options()
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from data: [UInt8], signature: Signature)
        throws -> T
    {
        var deserializer = Deserializer(
            data: data,
            signature: signature,
            endianness: options.endianness,
            alignmentContext: .message
        )

        // Handle DBusVariant specially - deserialize directly without going through Decodable
        if type is Variant.Type {
            let result: Variant = try deserializer.unserialize()
            return result as! T
        }

        // Handle arrays specially - check if signature is an array and type is array-like
        if signature.rawValue.hasPrefix("a") && !signature.rawValue.hasPrefix("a{") {
            // This is an array signature, not a dictionary
            return try decodeArray(type, deserializer: &deserializer)
        }

        // Handle dictionaries specially - check both type and signature
        if signature.rawValue.hasPrefix("a{") {
            // This is a dictionary signature
            switch type {
            case is [String: Variant].Type:
                // Explicitly call the dictionary unserialize method to avoid ambiguity
                let result: [String: Variant] = try unserializeDictionary(&deserializer)
                return result as! T
            case is [String: String].Type:
                // Explicitly call the dictionary unserialize method to avoid ambiguity
                let result: [String: String] = try unserializeDictionary(&deserializer)
                return result as! T
            default:
                throw DecodingError.typeMismatch(
                    type,
                    DecodingError.Context(
                        codingPath: [], debugDescription: "Unsupported dictionary type: \(type)")
                )
            }
        }

        // Handle structs specially
        if signature.rawValue.hasPrefix("(") && signature.rawValue.hasSuffix(")") {
            // Use struct deserialization method
            var result: T?
            try deserializer.unserialize { structDeserializer in
                let structDecoder = _DBusDecoder(
                    deserializer: &structDeserializer,
                    codingPath: [],
                    userInfo: userInfo
                )
                result = try T(from: structDecoder)
            }
            return result!
        }

        let decoder = _DBusDecoder(deserializer: &deserializer, codingPath: [], userInfo: userInfo)
        return try T(from: decoder)
    }

    public func decode<T: Decodable>(_ type: T.Type, from data: [UInt8], signature: String) throws
        -> T
    {
        guard let sig = Signature(rawValue: signature) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid D-Bus signature: \(signature)"
                ))
        }
        return try decode(type, from: data, signature: sig)
    }

    // Helper function that forces the correct generic method resolution
    private func unserializeArray<Element>(
        _ deserializer: inout Deserializer, elementType: Element.Type
    ) throws -> [Element] {
        // Explicitly call the generic array unserialize method by providing type context
        let result: [Element] = try deserializer.unserialize()
        return result
    }

    // Helper function that forces the correct dictionary method resolution
    private func unserializeDictionary<K: Hashable, V>(
        _ deserializer: inout Deserializer
    ) throws -> [K: V] {
        // Explicitly call the generic dictionary unserialize method by providing type context
        let result: [K: V] = try deserializer.unserialize()
        return result
    }

    private func decodeArray<T>(_ type: T.Type, deserializer: inout Deserializer) throws -> T {
        do {
            // Use generic helper function with explicit type annotation to
            // avoid method resolution ambiguity
            switch type {
            case is [String].Type:
                return try unserializeArray(&deserializer, elementType: String.self) as! T
            case is [Bool].Type:
                return try unserializeArray(&deserializer, elementType: Bool.self) as! T
            case is [UInt8].Type:
                return try unserializeArray(&deserializer, elementType: UInt8.self) as! T
            case is [Int16].Type:
                return try unserializeArray(&deserializer, elementType: Int16.self) as! T
            case is [UInt16].Type:
                return try unserializeArray(&deserializer, elementType: UInt16.self) as! T
            case is [Int32].Type:
                return try unserializeArray(&deserializer, elementType: Int32.self) as! T
            case is [UInt32].Type:
                return try unserializeArray(&deserializer, elementType: UInt32.self) as! T
            case is [Int64].Type:
                return try unserializeArray(&deserializer, elementType: Int64.self) as! T
            case is [UInt64].Type:
                return try unserializeArray(&deserializer, elementType: UInt64.self) as! T
            case is [Double].Type:
                return try unserializeArray(&deserializer, elementType: Double.self) as! T
            case is [ObjectPath].Type:
                return try unserializeArray(&deserializer, elementType: ObjectPath.self) as! T
            case is [Signature].Type:
                return try unserializeArray(&deserializer, elementType: Signature.self) as! T
            case is [Variant].Type:
                return try unserializeArray(&deserializer, elementType: Variant.self) as! T
            default:
                throw DecodingError.typeMismatch(
                    type,
                    DecodingError.Context(
                        codingPath: [], debugDescription: "Unsupported array type: \(type)")
                )
            }
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to decode array: \(error)"
                ))
        }
    }
}

// MARK: - Internal Encoder Implementation

private class _DBusEncoder {
    var serializer: UnsafeMutablePointer<Serializer>
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    init(
        serializer: inout Serializer, codingPath: [CodingKey],
        userInfo: [CodingUserInfoKey: Any]
    ) {
        self.serializer = withUnsafeMutablePointer(to: &serializer) { $0 }
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
}

extension _DBusEncoder: Encoder {
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
    where Key: CodingKey {
        return KeyedEncodingContainer(
            _DBusKeyedEncodingContainer<Key>(
                encoder: self,
                codingPath: codingPath
            ))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _DBusUnkeyedEncodingContainer(encoder: self, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return _DBusSingleValueEncodingContainer(encoder: self, codingPath: codingPath)
    }
}

// MARK: - Internal Decoder Implementation

private class _DBusDecoder {
    var deserializer: UnsafeMutablePointer<Deserializer>
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    init(
        deserializer: inout Deserializer, codingPath: [CodingKey],
        userInfo: [CodingUserInfoKey: Any]
    ) {
        self.deserializer = withUnsafeMutablePointer(to: &deserializer) { $0 }
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
}

extension _DBusDecoder: Decoder {
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
    where Key: CodingKey {
        return KeyedDecodingContainer(
            _DBusKeyedDecodingContainer<Key>(
                decoder: self,
                codingPath: codingPath
            ))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _DBusUnkeyedDecodingContainer(decoder: self, codingPath: codingPath)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _DBusSingleValueDecodingContainer(decoder: self, codingPath: codingPath)
    }
}

// MARK: - Container Implementations (Simplified versions of the original containers)

private struct _DBusSingleValueEncodingContainer {
    let encoder: _DBusEncoder
    let codingPath: [CodingKey]
}

extension _DBusSingleValueEncodingContainer: SingleValueEncodingContainer {
    func encodeNil() throws {
        throw EncodingError.invalidValue(
            Optional<Any>.none as Any,
            EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "D-Bus does not support null values"
            ))
    }

    func encode(_ value: Bool) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: String) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: Double) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: Float) throws {
        try encoder.serializer.pointee.serialize(Double(value))
    }

    func encode(_ value: Int) throws {
        #if arch(i386) || arch(arm)
            try encoder.serializer.pointee.serialize(Int32(value))
        #else
            try encoder.serializer.pointee.serialize(Int64(value))
        #endif
    }

    func encode(_ value: Int8) throws {
        try encoder.serializer.pointee.serialize(UInt8(bitPattern: value))
    }

    func encode(_ value: Int16) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: Int32) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: Int64) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: UInt) throws {
        #if arch(i386) || arch(arm)
            try encoder.serializer.pointee.serialize(UInt32(value))
        #else
            try encoder.serializer.pointee.serialize(UInt64(value))
        #endif
    }

    func encode(_ value: UInt8) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: UInt16) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: UInt32) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode(_ value: UInt64) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        if let objectPath = value as? ObjectPath {
            try encoder.serializer.pointee.serialize(objectPath)
        } else if let signature = value as? Signature {
            try encoder.serializer.pointee.serialize(signature)
        } else if let variant = value as? Variant {
            try encoder.serializer.pointee.serialize(variant)
        } else {
            // Check if this is a struct type that needs special handling
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .struct {
                // Use struct serialization method
                try encoder.serializer.pointee.serialize { structSerializer in
                    let structEncoder = _DBusEncoder(
                        serializer: &structSerializer,
                        codingPath: codingPath,
                        userInfo: encoder.userInfo
                    )
                    try value.encode(to: structEncoder)
                }
            } else {
                try value.encode(to: encoder)
            }
        }
    }
}

private struct _DBusSingleValueDecodingContainer {
    let decoder: _DBusDecoder
    let codingPath: [CodingKey]
}

extension _DBusSingleValueDecodingContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool { false }

    func decode(_ type: Bool.Type) throws -> Bool {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode Bool: \(error)"
                ))
        }
    }

    func decode(_ type: String.Type) throws -> String {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode String: \(error)"
                ))
        }
    }

    func decode(_ type: Double.Type) throws -> Double {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode Double: \(error)"
                ))
        }
    }

    func decode(_ type: Float.Type) throws -> Float {
        let double = try decode(Double.self)
        return Float(double)
    }

    func decode(_ type: Int.Type) throws -> Int {
        do {
            #if arch(i386) || arch(arm)
                let value: Int32 = try decoder.deserializer.pointee.unserialize()
                return Int(value)
            #else
                let value: Int64 = try decoder.deserializer.pointee.unserialize()
                return Int(value)
            #endif
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode Int: \(error)"
                ))
        }
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        do {
            let value: UInt8 = try decoder.deserializer.pointee.unserialize()
            return Int8(bitPattern: value)
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode Int8: \(error)"
                ))
        }
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode Int16: \(error)"
                ))
        }
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode Int32: \(error)"
                ))
        }
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode Int64: \(error)"
                ))
        }
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        do {
            #if arch(i386) || arch(arm)
                let value: UInt32 = try decoder.deserializer.pointee.unserialize()
                return UInt(value)
            #else
                let value: UInt64 = try decoder.deserializer.pointee.unserialize()
                return UInt(value)
            #endif
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode UInt: \(error)"
                ))
        }
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode UInt8: \(error)"
                ))
        }
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode UInt16: \(error)"
                ))
        }
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode UInt32: \(error)"
                ))
        }
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Failed to decode UInt64: \(error)"
                ))
        }
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if type == ObjectPath.self {
            do {
                let objectPath: ObjectPath = try decoder.deserializer.pointee.unserialize()
                return objectPath as! T
            } catch let error as DeserializerError {
                throw DecodingError.typeMismatch(
                    type,
                    DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Failed to decode ObjectPath: \(error)"
                    ))
            }
        } else if type == Signature.self {
            do {
                let signature: Signature = try decoder.deserializer.pointee.unserialize()
                return signature as! T
            } catch let error as DeserializerError {
                throw DecodingError.typeMismatch(
                    type,
                    DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Failed to decode Signature: \(error)"
                    ))
            }
        } else if type == Variant.self {
            // Handle DBusVariant specifically to avoid Mirror inspection issues
            do {
                let variant: Variant = try decoder.deserializer.pointee.unserialize()
                return variant as! T
            } catch let error as DeserializerError {
                throw DecodingError.typeMismatch(
                    type,
                    DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Failed to decode DBusVariant: \(error)"
                    ))
            }
        } else {
            // Check if this is a struct type that needs special handling
            let mirror = Mirror(reflecting: type)
            if mirror.displayStyle == .struct {
                // Use struct deserialization method
                var deserializer = decoder.deserializer.pointee
                var result: T?
                try deserializer.unserialize { structDeserializer in
                    let structDecoder = _DBusDecoder(
                        deserializer: &structDeserializer,
                        codingPath: codingPath,
                        userInfo: decoder.userInfo
                    )
                    result = try T(from: structDecoder)
                }
                decoder.deserializer.pointee = deserializer
                return result!
            } else {
                return try T(from: decoder)
            }
        }
    }
}

// Minimal container implementations for structures
private struct _DBusKeyedEncodingContainer<Key: CodingKey> {
    let encoder: _DBusEncoder
    let codingPath: [CodingKey]
}

extension _DBusKeyedEncodingContainer: KeyedEncodingContainerProtocol {
    mutating func encodeNil(forKey key: Key) throws {
        throw EncodingError.invalidValue(
            Optional<Any>.none as Any,
            EncodingError.Context(
                codingPath: codingPath + [DBusCodingKey(key)],
                debugDescription: "D-Bus does not support null values"
            ))
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(Double(value))
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        #if arch(i386) || arch(arm)
            try encoder.serializer.pointee.serialize(Int32(value))
        #else
            try encoder.serializer.pointee.serialize(Int64(value))
        #endif
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(UInt8(bitPattern: value))
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        #if arch(i386) || arch(arm)
            try encoder.serializer.pointee.serialize(UInt32(value))
        #else
            try encoder.serializer.pointee.serialize(UInt64(value))
        #endif
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try encoder.serializer.pointee.serialize(value)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        // For struct fields, we need to handle encoding properly within the struct context
        if let objectPath = value as? ObjectPath {
            try encoder.serializer.pointee.serialize(objectPath)
        } else if let signature = value as? Signature {
            try encoder.serializer.pointee.serialize(signature)
        } else if let variant = value as? Variant {
            try encoder.serializer.pointee.serialize(variant)
        } else {
            try value.encode(to: encoder)
        }
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return encoder.container(keyedBy: keyType)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return encoder.unkeyedContainer()
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        return encoder
    }
}

private struct _DBusKeyedDecodingContainer<Key: CodingKey> {
    let decoder: _DBusDecoder
    let codingPath: [CodingKey]
}

extension _DBusKeyedDecodingContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] { [] }
    func contains(_ key: Key) -> Bool { true }

    func decodeNil(forKey key: Key) throws -> Bool { false }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode Bool for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode String for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode Double for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        let double = try decode(Double.self, forKey: key)
        return Float(double)
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        do {
            #if arch(i386) || arch(arm)
                let value: Int32 = try decoder.deserializer.pointee.unserialize()
                return Int(value)
            #else
                let value: Int64 = try decoder.deserializer.pointee.unserialize()
                return Int(value)
            #endif
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode Int for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        do {
            let value: UInt8 = try decoder.deserializer.pointee.unserialize()
            return Int8(bitPattern: value)
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode Int8 for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode Int16 for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode Int32 for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode Int64 for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        do {
            #if arch(i386) || arch(arm)
                let value: UInt32 = try decoder.deserializer.pointee.unserialize()
                return UInt(value)
            #else
                let value: UInt64 = try decoder.deserializer.pointee.unserialize()
                return UInt(value)
            #endif
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode UInt for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode UInt8 for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode UInt16 for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode UInt32 for key \(key): \(error)"
                ))
        }
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        do {
            return try decoder.deserializer.pointee.unserialize()
        } catch let error as DeserializerError {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [DBusCodingKey(key)],
                    debugDescription: "Failed to decode UInt64 for key \(key): \(error)"
                ))
        }
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        return try T(from: decoder)
    }

    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return try decoder.container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try decoder.unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        return decoder
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        return decoder
    }
}

// Minimal unkeyed container implementations
private struct _DBusUnkeyedEncodingContainer {
    let encoder: _DBusEncoder
    let codingPath: [CodingKey]
    private(set) var count: Int = 0
}

extension _DBusUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    mutating func encodeNil() throws {
        throw EncodingError.invalidValue(
            Optional<Any>.none as Any,
            EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "D-Bus arrays cannot contain null values"
            ))
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        try value.encode(to: encoder)
        count += 1
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        defer { count += 1 }
        return encoder.container(keyedBy: keyType)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        defer { count += 1 }
        return encoder.unkeyedContainer()
    }

    mutating func superEncoder() -> Encoder {
        count += 1
        return encoder
    }
}

private struct _DBusUnkeyedDecodingContainer {
    let decoder: _DBusDecoder
    let codingPath: [CodingKey]
    private(set) var currentIndex: Int = 0
}

extension _DBusUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    var count: Int? { nil }
    var isAtEnd: Bool { false }

    mutating func decodeNil() throws -> Bool { false }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        defer { currentIndex += 1 }
        return try T(from: decoder)
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        defer { currentIndex += 1 }
        return try decoder.container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        defer { currentIndex += 1 }
        return try decoder.unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        currentIndex += 1
        return decoder
    }
}
