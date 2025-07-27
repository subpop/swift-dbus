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

/// Represents a D-Bus type signature that describes the type of data in a message.
///
/// A type signature is a string of single-character type codes that describes the structure
/// of data encoded in D-Bus messages. Signatures can represent simple types (like integers
/// and strings) or complex types (like arrays, dictionaries, and structures).
///
/// ## Basic Type Signatures
///
/// - `"i"` - A single 32-bit signed integer
/// - `"s"` - A single string
/// - `"b"` - A single boolean
/// - `"d"` - A single double-precision floating point number
///
/// ## Complex Type Signatures
///
/// - `"ai"` - Array of 32-bit signed integers
/// - `"a{sv}"` - Dictionary mapping strings to variants
/// - `"(si)"` - Structure containing a string and an integer
/// - `"ii"` - Two 32-bit signed integers in sequence
///
/// ## Usage Examples
///
/// ```swift
/// // Create signatures from strings
/// let intSignature: Signature = "i"
/// let arraySignature = Signature("ai")
/// let structSignature = Signature("(si)")
///
/// // Use with method calls
/// let result = try await proxy.call(
///     "GetProperty",
///     signature: Signature("ss"),
///     body: encoder.encode(["interface", "property"])
/// )
///
/// // Create from Swift types
/// let signature = try Signature(for: [String: Int].self)  // "a{si}"
/// ```
///
/// ## Internal Implementation
///
/// Internally, signatures are parsed into an array of `SignatureElement` values that
/// represent the structured type information. This allows for efficient type checking,
/// serialization, and deserialization operations.
///
/// For detailed type specification, see:
/// https://dbus.freedesktop.org/doc/dbus-specification.html#type-system
public struct Signature: Sendable {
    /// Returns the single signature element if this signature contains exactly one element
    ///
    /// This computed property is used internally for optimization when working with
    /// single-element signatures, which are common in D-Bus operations.
    var element: SignatureElement? {
        if elements.count == 1 {
            elements.first
        } else {
            nil
        }
    }

    /// Internal array of signature elements that make up this signature
    ///
    /// Each element represents a type in the signature. For example, the signature "si"
    /// would contain [.string, .int32] elements.
    private var elements: [SignatureElement]

    /// Creates a signature from an array of signature elements
    ///
    /// This initializer is primarily used internally when constructing signatures
    /// programmatically from known type elements.
    ///
    /// - Parameter elements: Array of signature elements representing the types
    ///
    /// ```swift
    /// // Create a signature for a string followed by an integer
    /// let signature = Signature(elements: [.string, .int32])  // Equivalent to "si"
    /// ```
    public init(elements: [SignatureElement]) {
        self.elements = elements
    }
}

extension Signature: RawRepresentable {
    /// The string representation of the signature
    ///
    /// Converts the internal signature elements back to their D-Bus type code string.
    /// This is the canonical string form used in D-Bus messages and introspection.
    public var rawValue: String {
        var stringValue = ""
        for element in elements {
            stringValue.append(element.rawValue)
        }
        return stringValue
    }

    /// Creates a signature from a D-Bus type signature string
    ///
    /// Parses a D-Bus signature string into its constituent type elements.
    /// Returns nil if the signature string is malformed or contains invalid type codes.
    ///
    /// - Parameter rawValue: A valid D-Bus signature string (e.g., "i", "as", "(si)")
    /// - Returns: A Signature instance, or nil if parsing fails
    ///
    /// ```swift
    /// let intSig = Signature(rawValue: "i")        // Single integer
    /// let arraySig = Signature(rawValue: "as")     // Array of strings
    /// let structSig = Signature(rawValue: "(si)")  // Struct with string and int
    /// let invalid = Signature(rawValue: "xyz")     // Returns nil
    /// ```
    public init?(rawValue: String) {
        do {
            let parser = try SignatureParser(signature: rawValue)
            self.elements = parser.signature
        } catch {
            return nil
        }
    }
}

extension Signature: ExpressibleByStringLiteral {
    /// Allows creating signatures using string literals
    ///
    /// Enables convenient syntax for creating signatures directly from string literals.
    /// This will crash at runtime if the signature string is invalid, so it should only
    /// be used with known-good signature strings.
    ///
    /// ```swift
    /// let signature: Signature = "i"      // Single integer
    /// let complex: Signature = "a{sv}"    // String-to-variant dictionary
    /// ```
    public init(stringLiteral value: String) {
        self.elements = try! SignatureParser(signature: value).signature
    }
}

extension Signature: Equatable {}

extension Signature: Encodable {
    /// Encodes the signature as its string representation
    ///
    /// Supports Swift's Encodable protocol for JSON and other serialization formats.
    /// The signature is encoded as its raw string value.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension Signature: Decodable {
    /// Decodes a signature from its string representation
    ///
    /// Supports Swift's Decodable protocol for JSON and other deserialization formats.
    /// Validates that the decoded string is a valid D-Bus signature.
    ///
    /// - Throws: `DecodingError` if the signature string is invalid
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let signatureString = try container.decode(String.self)
        guard let signature = Signature(rawValue: signatureString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid signature string: \(signatureString)"
                )
            )
        }
        self = signature
    }
}

/// Represents individual type elements that can appear in D-Bus signatures
///
/// Each case corresponds to a specific D-Bus type code and represents the type
/// information needed for serialization and deserialization operations.
///
/// ## Basic Types
///
/// - `.byte` - 8-bit unsigned integer (`y`)
/// - `.bool` - Boolean value (`b`)
/// - `.int16` - 16-bit signed integer (`n`)
/// - `.uint16` - 16-bit unsigned integer (`q`)
/// - `.int32` - 32-bit signed integer (`i`)
/// - `.uint32` - 32-bit unsigned integer (`u`)
/// - `.int64` - 64-bit signed integer (`x`)
/// - `.uint64` - 64-bit unsigned integer (`t`)
/// - `.double` - Double-precision floating point (`d`)
/// - `.string` - UTF-8 string (`s`)
/// - `.objectPath` - D-Bus object path (`o`)
/// - `.signature` - D-Bus type signature (`g`)
/// - `.variant` - D-Bus variant type (`v`)
/// - `.unixFD` - Unix file descriptor (`h`)
///
/// ## Container Types
///
/// - `.array(SignatureElement)` - Array of elements (`a` + element type)
/// - `.dictionary(key, value)` - Dictionary mapping keys to values (`a{` + key type + value type + `}`)
/// - `.struct([SignatureElement])` - Structure with ordered fields (`(` + field types + `)`)
///
/// ## Internal Usage
///
/// This enum is used internally by the serialization system to understand the structure
/// of data being encoded or decoded. The alignment and size properties are used for
/// proper D-Bus wire format handling.
public indirect enum SignatureElement: Sendable {
    /// 8-bit unsigned integer (D-Bus type code: `y`)
    case byte
    /// Boolean value, encoded as 32-bit integer (D-Bus type code: `b`)
    case bool
    /// 16-bit signed integer (D-Bus type code: `n`)
    case int16
    /// 16-bit unsigned integer (D-Bus type code: `q`)
    case uint16
    /// 32-bit signed integer (D-Bus type code: `i`)
    case int32
    /// 32-bit unsigned integer (D-Bus type code: `u`)
    case uint32
    /// 64-bit signed integer (D-Bus type code: `x`)
    case int64
    /// 64-bit unsigned integer (D-Bus type code: `t`)
    case uint64
    /// Double-precision floating point number (D-Bus type code: `d`)
    case double
    /// UTF-8 encoded string (D-Bus type code: `s`)
    case string
    /// D-Bus object path (D-Bus type code: `o`)
    case objectPath
    /// D-Bus type signature (D-Bus type code: `g`)
    case signature
    /// D-Bus variant type (D-Bus type code: `v`)
    case variant
    /// Unix file descriptor (D-Bus type code: `h`)
    case unixFD
    /// Array of elements (D-Bus type code: `a` + element type)
    case array(SignatureElement)
    /// Dictionary mapping keys to values (D-Bus type code: `a{` + key + value + `}`)
    case dictionary(SignatureElement, SignatureElement)
    /// Structure with ordered fields (D-Bus type code: `(` + field types + `)`)
    case `struct`([SignatureElement])

    /// Internal initializer from signature tokens
    ///
    /// Used by the signature parser to convert lexical tokens into signature elements.
    /// Returns nil for tokens that don't represent basic types.
    init?(token: SignatureToken) {
        switch token {
        case .byte:
            self = .byte
        case .bool:
            self = .bool
        case .int16:
            self = .int16
        case .uint16:
            self = .uint16
        case .int32:
            self = .int32
        case .uint32:
            self = .uint32
        case .int64:
            self = .int64
        case .uint64:
            self = .uint64
        case .double:
            self = .double
        case .string:
            self = .string
        case .objectPath:
            self = .objectPath
        case .signature:
            self = .signature
        case .variant:
            self = .variant
        case .unixFD:
            self = .unixFD
        default:
            return nil
        }
    }

    /// Creates a signature element from a Swift type
    ///
    /// This initializer maps Swift types to their corresponding D-Bus signature elements,
    /// enabling automatic signature generation from Swift type information.
    ///
    /// - Parameter type: The Swift type to map to a signature element
    /// - Returns: The corresponding signature element, or nil if the type is not supported
    ///
    /// ```swift
    /// let intElement = SignatureElement(Int32.self)     // .int32
    /// let stringElement = SignatureElement(String.self) // .string
    /// let boolElement = SignatureElement(Bool.self)     // .bool
    /// ```
    public init?<T>(_ type: T.Type) {
        switch T.self {
        case is UInt8.Type: self = .byte
        case is Bool.Type: self = .bool
        case is Int16.Type: self = .int16
        case is UInt16.Type: self = .uint16
        case is Int32.Type: self = .int32
        case is UInt32.Type: self = .uint32
        case is Int64.Type: self = .int64
        case is UInt64.Type: self = .uint64
        case is Int.Type:
            #if arch(i386) || arch(arm)
                self = .int32
            #else
                self = .int64
            #endif
        case is UInt.Type:
            #if arch(i386) || arch(arm)
                self = .uint32
            #else
                self = .uint64
            #endif
        case is Double.Type: self = .double
        case is String.Type: self = .string
        case is ObjectPath.Type: self = .objectPath
        case is Signature.Type: self = .signature
        case is HeaderVariant.Type: self = .variant
        case is Variant.Type: self = .variant
        default: return nil
        }
    }

    /// Size in bytes of fixed-width elements
    ///
    /// Returns the byte size for elements that have a fixed size in the D-Bus wire format.
    /// Variable-length types like strings and arrays return nil since their size depends
    /// on the actual data content.
    ///
    /// This property is used internally by the serialization system for proper alignment
    /// and buffer management.
    var size: Int? {
        switch self {
        case .byte:
            return MemoryLayout<UInt8>.stride
        case .bool:
            return MemoryLayout<UInt32>.stride
        case .int16:
            return MemoryLayout<Int16>.stride
        case .uint16:
            return MemoryLayout<UInt16>.stride
        case .int32:
            return MemoryLayout<Int32>.stride
        case .uint32:
            return MemoryLayout<UInt32>.stride
        case .int64:
            return MemoryLayout<Int64>.stride
        case .uint64:
            return MemoryLayout<UInt64>.stride
        case .double:
            return MemoryLayout<Double>.stride
        case .unixFD:
            return MemoryLayout<UInt32>.stride
        default:
            return nil
        }
    }
}

extension Signature: MutableCollection {
    /// Element type for collection conformance
    public typealias Element = SignatureElement
    /// Index type for collection conformance
    public typealias Index = Int

    /// Starting index of the signature elements
    public var startIndex: Int {
        elements.startIndex
    }

    /// Ending index of the signature elements
    public var endIndex: Int {
        elements.endIndex
    }

    /// Accesses signature elements by index
    ///
    /// Allows treating a signature as a collection of signature elements,
    /// enabling iteration and indexed access.
    public subscript(position: Int) -> SignatureElement {
        get {
            elements[position]
        }
        set(newValue) {
            elements[position] = newValue
        }
    }

    /// Returns the index after the given index
    public func index(after i: Int) -> Int {
        elements.index(after: i)
    }

    /// Appends a signature element to the signature
    ///
    /// Allows building up complex signatures programmatically by adding elements.
    ///
    /// ```swift
    /// var signature = Signature(elements: [.string])
    /// signature.append(.int32)  // Now represents "si"
    /// ```
    public mutating func append(_ newElement: SignatureElement) {
        elements.append(newElement)
    }
}

extension SignatureElement: Equatable {}

extension SignatureElement {
    /// Alignment requirement for this signature element in bytes
    ///
    /// D-Bus requires specific alignment for different types to ensure proper
    /// wire format compatibility. This property returns the required alignment
    /// boundary for each type.
    ///
    /// Used internally by the serialization system to ensure proper padding
    /// and alignment in D-Bus messages.
    var alignment: Int {
        switch self {
        case .byte, .signature, .variant:
            1
        case .int16, .uint16:
            2
        case .bool, .uint32, .int32, .string, .objectPath, .unixFD, .array(_):
            4
        case .int64, .uint64, .double, .struct(_), .dictionary(_, _):
            8
        }
    }
}

extension SignatureElement: RawRepresentable {
    /// Creates a signature element from a D-Bus type code string
    ///
    /// Parses a single-element signature string into its corresponding signature element.
    /// Returns nil if the string is not a valid single-element signature.
    ///
    /// - Parameter rawValue: A single D-Bus type code (e.g., "i", "s", "ai")
    /// - Returns: The corresponding signature element, or nil if invalid
    public init?(rawValue: String) {
        do {
            let parser = try SignatureParser(signature: rawValue)
            guard let element = parser.signature.first else {
                return nil
            }
            self = element
        } catch {
            return nil
        }
    }

    /// The D-Bus type code string for this signature element
    ///
    /// Converts the signature element back to its canonical D-Bus type code representation.
    /// This is used for message serialization and introspection data generation.
    public var rawValue: String {
        switch self {
        case .byte:
            return "y"
        case .bool:
            return "b"
        case .int16:
            return "n"
        case .uint16:
            return "q"
        case .int32:
            return "i"
        case .uint32:
            return "u"
        case .int64:
            return "x"
        case .uint64:
            return "t"
        case .double:
            return "d"
        case .string:
            return "s"
        case .objectPath:
            return "o"
        case .signature:
            return "g"
        case .variant:
            return "v"
        case .unixFD:
            return "h"
        case .array(let signatureElement):
            return "a\(signatureElement.rawValue)"
        case .dictionary(let keyElement, let valueElement):
            return "a{\(keyElement.rawValue)\(valueElement.rawValue)}"
        case .struct(let array):
            var stringValue = ""
            for element in array {
                stringValue.append(element.rawValue)
            }
            return "(\(stringValue))"
        }
    }
}
