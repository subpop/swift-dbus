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

/// Represents the possible values that can be stored in D-Bus variants
///
/// D-Bus variants are a way to represent dynamically-typed values in an otherwise
/// statically-typed message system. Each variant contains both a value and its
/// type information (signature). This enum represents all the possible value
/// types that can be stored in a variant.
///
/// ## Usage Examples
///
/// ```swift
/// // Create variant values from Swift types
/// let stringValue = try VariantValue("Hello World")         // .string("Hello World")
/// let intValue = try VariantValue(Int32(42))               // .int32(42)
/// let boolValue = try VariantValue(true)                   // .bool(true)
///
/// // Work with complex types
/// let arrayValue = VariantValue.array([.string("a"), .string("b")])
/// let dictValue = VariantValue.dictionary(["key": .string("value")])
///
/// // Extract underlying values
/// if case .string(let str) = stringValue {
///     print("String value: \(str)")
/// }
///
/// // Use anyValue for type-erased access
/// print("Any value: \(stringValue.anyValue)")
/// ```
///
/// ## Supported Types
///
/// This enum supports all basic D-Bus types as well as container types:
/// - All integer types (8, 16, 32, 64-bit signed and unsigned)
/// - Boolean and floating-point types
/// - String types (regular strings, object paths, signatures)
/// - Container types (arrays, dictionaries, structures)
///
/// ## Internal Implementation
///
/// The enum cases directly correspond to D-Bus type codes, making serialization
/// and deserialization straightforward. Each case stores the actual Swift value
/// in its native type for type safety and performance.
public enum VariantValue: Equatable, Sendable, Encodable, Decodable {
    /// 8-bit unsigned integer value
    case byte(UInt8)
    /// Boolean value (encoded as 32-bit integer in D-Bus)
    case bool(Bool)
    /// 16-bit signed integer value
    case int16(Int16)
    /// 16-bit unsigned integer value
    case uint16(UInt16)
    /// 32-bit signed integer value
    case int32(Int32)
    /// 32-bit unsigned integer value
    case uint32(UInt32)
    /// 64-bit signed integer value
    case int64(Int64)
    /// 64-bit unsigned integer value
    case uint64(UInt64)
    /// Double-precision floating point value
    case double(Double)
    /// UTF-8 string value
    case string(String)
    /// D-Bus object path value
    case objectPath(ObjectPath)
    /// D-Bus type signature value
    case signature(Signature)

    // Complex types
    /// Array of variant values
    ///
    /// Represents a D-Bus array where all elements have the same type.
    /// The array can contain any variant value type.
    case array([VariantValue])
    /// Dictionary mapping strings to variant values
    ///
    /// Represents a D-Bus dictionary (technically an array of dict entries).
    /// Keys are always strings, but values can be any variant type.
    case dictionary([String: VariantValue])
    /// Structure containing an ordered list of variant values
    ///
    /// Represents a D-Bus structure with fixed-order fields.
    /// Each field can be a different variant type.
    case `struct`([VariantValue])

    /// Get the underlying value as Any for compatibility
    ///
    /// Provides type-erased access to the underlying value, useful when you need
    /// to work with the value without knowing its specific type at compile time.
    ///
    /// ```swift
    /// let variant = VariantValue.string("hello")
    /// let anyValue = variant.anyValue  // Returns "hello" as Any
    ///
    /// // Useful for logging or generic processing
    /// print("Variant contains: \(variant.anyValue)")
    /// ```
    public var anyValue: Any {
        switch self {
        case .byte(let value): return value
        case .bool(let value): return value
        case .int16(let value): return value
        case .uint16(let value): return value
        case .int32(let value): return value
        case .uint32(let value): return value
        case .int64(let value): return value
        case .uint64(let value): return value
        case .double(let value): return value
        case .string(let value): return value
        case .objectPath(let value): return value
        case .signature(let value): return value
        case .array(let value): return value
        case .dictionary(let value): return value
        case .`struct`(let value): return value
        }
    }

    /// Initialize a variant value from any supported Swift type
    ///
    /// This initializer provides a convenient way to create variant values from
    /// Swift's native types, automatically mapping them to the appropriate D-Bus
    /// variant case.
    ///
    /// - Parameter value: A Swift value of a supported type
    /// - Throws: `DBusVariantError.unsupportedType` if the type is not supported
    ///
    /// ```swift
    /// // Basic types
    /// let stringVariant = try VariantValue("Hello")
    /// let intVariant = try VariantValue(Int32(42))
    /// let boolVariant = try VariantValue(true)
    ///
    /// // D-Bus specific types
    /// let pathVariant = try VariantValue(ObjectPath("/org/example"))
    /// let sigVariant = try VariantValue(Signature("s"))
    ///
    /// // Container types
    /// let arrayVariant = try VariantValue([VariantValue.string("a"), VariantValue.string("b")])
    /// ```
    public init<T>(_ value: T) throws {
        switch value {
        case let v as UInt8: self = .byte(v)
        case let v as Bool: self = .bool(v)
        case let v as Int16: self = .int16(v)
        case let v as UInt16: self = .uint16(v)
        case let v as Int32: self = .int32(v)
        case let v as UInt32: self = .uint32(v)
        case let v as Int64: self = .int64(v)
        case let v as UInt64: self = .uint64(v)
        case let v as Double: self = .double(v)
        case let v as String: self = .string(v)
        case let v as ObjectPath: self = .objectPath(v)
        case let v as Signature: self = .signature(v)
        case let v as [VariantValue]: self = .array(v)
        case let v as [String: VariantValue]: self = .dictionary(v)
        default:
            throw DBusVariantError.unsupportedType(type: T.self)
        }
    }

    // MARK: - Encodable Conformance

    /// Encodes the variant value for serialization
    ///
    /// The encoding includes both the type information and the actual value,
    /// allowing for complete round-trip serialization and deserialization.
    ///
    /// Used internally for JSON serialization and other encoding scenarios.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .byte(let value):
            try container.encode("byte", forKey: .type)
            try container.encode(value, forKey: .value)
        case .bool(let value):
            try container.encode("bool", forKey: .type)
            try container.encode(value, forKey: .value)
        case .int16(let value):
            try container.encode("int16", forKey: .type)
            try container.encode(value, forKey: .value)
        case .uint16(let value):
            try container.encode("uint16", forKey: .type)
            try container.encode(value, forKey: .value)
        case .int32(let value):
            try container.encode("int32", forKey: .type)
            try container.encode(value, forKey: .value)
        case .uint32(let value):
            try container.encode("uint32", forKey: .type)
            try container.encode(value, forKey: .value)
        case .int64(let value):
            try container.encode("int64", forKey: .type)
            try container.encode(value, forKey: .value)
        case .uint64(let value):
            try container.encode("uint64", forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode("double", forKey: .type)
            try container.encode(value, forKey: .value)
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .objectPath(let value):
            try container.encode("objectPath", forKey: .type)
            try container.encode(value.fullPath, forKey: .value)
        case .signature(let value):
            try container.encode("signature", forKey: .type)
            try container.encode(value.rawValue, forKey: .value)
        case .array(let value):
            try container.encode("array", forKey: .type)
            try container.encode(value, forKey: .value)
        case .dictionary(let value):
            try container.encode("dictionary", forKey: .type)
            try container.encode(value, forKey: .value)
        case .`struct`(let value):
            try container.encode("struct", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    // MARK: - Decodable Conformance

    /// Decodes a variant value from serialized data
    ///
    /// Reconstructs both the type information and value from encoded data,
    /// ensuring type safety and proper variant reconstruction.
    ///
    /// Used internally for JSON deserialization and other decoding scenarios.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "byte":
            let value = try container.decode(UInt8.self, forKey: .value)
            self = .byte(value)
        case "bool":
            let value = try container.decode(Bool.self, forKey: .value)
            self = .bool(value)
        case "int16":
            let value = try container.decode(Int16.self, forKey: .value)
            self = .int16(value)
        case "uint16":
            let value = try container.decode(UInt16.self, forKey: .value)
            self = .uint16(value)
        case "int32":
            let value = try container.decode(Int32.self, forKey: .value)
            self = .int32(value)
        case "uint32":
            let value = try container.decode(UInt32.self, forKey: .value)
            self = .uint32(value)
        case "int64":
            let value = try container.decode(Int64.self, forKey: .value)
            self = .int64(value)
        case "uint64":
            let value = try container.decode(UInt64.self, forKey: .value)
            self = .uint64(value)
        case "double":
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
        case "string":
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case "objectPath":
            let pathString = try container.decode(String.self, forKey: .value)
            let objectPath = try ObjectPath(pathString)
            self = .objectPath(objectPath)
        case "signature":
            let sigString = try container.decode(String.self, forKey: .value)
            guard let signature = Signature(rawValue: sigString) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid signature: \(sigString)"
                    )
                )
            }
            self = .signature(signature)
        case "array":
            let value = try container.decode([VariantValue].self, forKey: .value)
            self = .array(value)
        case "dictionary":
            let value = try container.decode([String: VariantValue].self, forKey: .value)
            self = .dictionary(value)
        case "struct":
            let value = try container.decode([VariantValue].self, forKey: .value)
            self = .`struct`(value)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown variant type: \(type)"
                )
            )
        }
    }

    /// Internal coding keys for serialization
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }
}

/// A complete D-Bus variant containing both value and type signature
///
/// In D-Bus, a variant is a container that holds both a value and its complete
/// type signature. This allows for dynamic typing within the otherwise statically-typed
/// D-Bus message system. Variants are commonly used in properties and method calls
/// where the exact type may not be known at compile time.
///
/// ## Usage Examples
///
/// ```swift
/// // Create variants with explicit signatures
/// let stringVariant = Variant(
///     value: .string("Hello"),
///     signature: Signature("s")
/// )
///
/// let intVariant = try Variant(Int32(42), signature: Signature("i"))
///
/// // Use in property operations
/// try await proxy.setProperty("Volume", value: intVariant)
///
/// // Retrieve and process variants
/// if let (sig, data) = try await proxy.getProperty("Status") {
///     let decoder = DBusDecoder()
///     let variant = try decoder.decode(Variant.self, from: data, signature: sig)
///
///     switch variant.value {
///     case .string(let status):
///         print("Status: \(status)")
///     case .int32(let code):
///         print("Status code: \(code)")
///     default:
///         print("Unexpected status type")
///     }
/// }
/// ```
///
/// ## Internal Structure
///
/// The variant stores both the `VariantValue` (the actual data) and the `Signature`
/// (the type information). This redundancy ensures that the type information is
/// preserved through serialization and allows for proper type checking during
/// deserialization.
///
/// ## Properties and D-Bus
///
/// Variants are particularly important in D-Bus property access, where properties
/// can have different types depending on the specific object and interface. The
/// org.freedesktop.DBus.Properties interface uses variants to represent property
/// values in a type-safe manner.
public struct Variant: Equatable, Sendable {
    /// The actual value stored in the variant
    public let value: VariantValue

    /// The D-Bus type signature describing the value's type
    public let signature: Signature

    /// Creates a variant with a specific value and signature
    ///
    /// This is the primary way to create variants when you have both the value
    /// and know the exact signature it should have.
    ///
    /// - Parameters:
    ///   - value: The variant value to store
    ///   - signature: The D-Bus signature describing the value's type
    ///
    /// ```swift
    /// let variant = Variant(
    ///     value: .array([.string("a"), .string("b")]),
    ///     signature: Signature("as")
    /// )
    /// ```
    public init(value: VariantValue, signature: Signature) {
        self.value = value
        self.signature = signature
    }

    /// Creates a variant from a typed Swift value with an explicit signature
    ///
    /// This initializer converts a Swift value to a variant value and associates
    /// it with the provided signature. The signature should match the type of
    /// the provided value.
    ///
    /// - Parameters:
    ///   - typedValue: The Swift value to convert to a variant
    ///   - signature: The D-Bus signature for the value
    /// - Throws: `DBusVariantError.unsupportedType` if the value type is not supported
    ///
    /// ```swift
    /// let stringVariant = try Variant("Hello World", signature: Signature("s"))
    /// let intVariant = try Variant(Int32(42), signature: Signature("i"))
    /// let pathVariant = try Variant(ObjectPath("/org/example"), signature: Signature("o"))
    /// ```
    public init<T>(_ typedValue: T, signature: Signature) throws {
        self.value = try VariantValue(typedValue)
        self.signature = signature
    }
}

extension Variant: Encodable {
    /// Encodes the variant for serialization
    ///
    /// Serializes both the signature and value, ensuring complete type information
    /// is preserved for round-trip encoding and decoding.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(signature.rawValue, forKey: .signature)
        try container.encode(value, forKey: .value)
    }

    /// Internal coding keys for variant serialization
    private enum CodingKeys: String, CodingKey {
        case signature
        case value
    }
}

extension Variant: Decodable {
    /// Decodes a variant from serialized data
    ///
    /// Reconstructs both the signature and value from encoded data, ensuring
    /// type safety and proper variant reconstruction.
    ///
    /// - Throws: `DecodingError` if the signature is invalid or decoding fails
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let signatureString = try container.decode(String.self, forKey: .signature)

        guard let signature = Signature(rawValue: signatureString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid signature: \(signatureString)"
                )
            )
        }

        self.value = try container.decode(VariantValue.self, forKey: .value)
        self.signature = signature
    }
}

/// Errors that can occur when working with D-Bus variants
///
/// These errors indicate problems with variant creation or manipulation,
/// typically related to unsupported types or invalid type conversions.
public enum DBusVariantError: Error {
    /// The provided Swift type is not supported for variant creation
    ///
    /// This error occurs when trying to create a variant from a Swift type
    /// that doesn't have a corresponding D-Bus type representation.
    ///
    /// - Parameter type: The unsupported Swift type that was provided
    ///
    /// ## Supported Types
    ///
    /// The following Swift types are supported for variant creation:
    /// - All integer types: `UInt8`, `Int16`, `UInt16`, `Int32`, `UInt32`, `Int64`, `UInt64`
    /// - Floating point: `Double`
    /// - Boolean: `Bool`
    /// - String types: `String`, `ObjectPath`, `Signature`
    /// - Container types: `[VariantValue]`, `[String: VariantValue]`
    ///
    /// ```swift
    /// // This will throw unsupportedType error
    /// let variant = try VariantValue(Float(3.14))  // Float is not supported, use Double
    /// ```
    case unsupportedType(type: Any.Type)
}
