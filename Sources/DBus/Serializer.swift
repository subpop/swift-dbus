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

/// Alignment context for controlling when elements should be aligned
public enum AlignmentContext {
    case message  // Top-level message elements (apply alignment)
    case structContent  // Inside struct (no individual element alignment)
}

/// `Serializer` converts native Swift types into a format compatible with the D-Bus
/// wire format. No assumptions are made about how to encode native Swift types. A signature
/// must be given to a serializer upon initialization. This signature is used to ensure serialization
/// of the expected types is strictly adhered to. It is an error to serialize a value other than what
/// is expected next according to the signature.
public struct Serializer {
    var signature: Signature
    var endianness: Endianness

    private var alignment: Int = 0
    private var _data: [UInt8] = []
    private var currentIndex: Signature.Index
    private var alignmentContext: AlignmentContext

    /// The final, marshaled data. This property will be `nil` unless all fields defined in the
    /// serializer's signature have been serialized.
    public var data: [UInt8]? {
        guard currentIndex >= signature.endIndex else {
            return nil
        }
        return _data
    }

    /// Create a new `Serializer`, configured with the given `Signature`.
    public init(
        signature: Signature, alignmentContext: AlignmentContext = .message,
        endianness: Endianness = .littleEndian
    ) {
        self.signature = signature
        self.currentIndex = signature.startIndex
        self.alignmentContext = alignmentContext
        self.endianness = endianness
    }

    /// Get the current expected signature element
    public var currentSignatureElement: SignatureElement {
        signature[currentIndex]
    }

    /// Marshal `Bool` value into bytes.
    private func marshal(_ value: Bool) throws -> [UInt8] {
        let boolValue: UInt32 = value ? 1 : 0
        return try byteSize(boolValue)
    }

    /// Encode `value` as a `Bool`.
    public mutating func serialize(_ value: Bool) throws {
        guard signature[currentIndex] == .bool else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Bool.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `UInt8` value into bytes.
    private func marshal(_ value: UInt8) throws -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: try byteSize(value))
        return data
    }

    /// Encode `value` as a `UInt8`.
    public mutating func serialize(_ value: UInt8) throws {
        guard signature[currentIndex] == .byte else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: UInt8.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `UInt16` value into bytes.
    private func marshal(_ value: UInt16) throws -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: try byteSize(value))
        return data
    }

    /// Encode `value` as a `UInt16`.
    public mutating func serialize(_ value: UInt16) throws {
        guard signature[currentIndex] == .uint16 else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: UInt16.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `UInt32` value into bytes.
    private func marshal(_ value: UInt32) throws -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: try byteSize(value))
        return data
    }

    /// Encode `value` as a `UInt32`.
    public mutating func serialize(_ value: UInt32) throws {
        guard signature[currentIndex] == .uint32 else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: UInt32.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `UInt64` value into bytes.
    private func marshal(_ value: UInt64) throws -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: try byteSize(value))
        return data
    }

    /// Encode `value` as a `UInt64`.
    public mutating func serialize(_ value: UInt64) throws {
        guard signature[currentIndex] == .uint64 else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: UInt64.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `Int16` value into bytes.
    private func marshal(_ value: Int16) throws -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: try byteSize(value))
        return data
    }

    /// Encode `value` as a `Int16`.
    public mutating func serialize(_ value: Int16) throws {
        guard signature[currentIndex] == .int16 else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Int16.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `Int32` value into bytes.
    private func marshal(_ value: Int32) throws -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: try byteSize(value))
        return data
    }

    /// Encode `value` as a `Int32`.
    public mutating func serialize(_ value: Int32) throws {
        guard signature[currentIndex] == .int32 else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Int32.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `Int64` value into bytes.
    private func marshal(_ value: Int64) throws -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: try byteSize(value))
        return data
    }

    /// Encode `value` as a `Int64`.
    public mutating func serialize(_ value: Int64) throws {
        guard signature[currentIndex] == .int64 else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Int64.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `Double` value into bytes.
    private func marshal(_ value: Double) throws -> [UInt8] {
        var data: [UInt8] = []
        // Serialize Double directly with proper endianness
        let bitPattern = value.bitPattern
        if endianness == .littleEndian {
            data.append(contentsOf: withUnsafeBytes(of: bitPattern.littleEndian) { Array($0) })
        } else {
            data.append(contentsOf: withUnsafeBytes(of: bitPattern.bigEndian) { Array($0) })
        }
        return data
    }

    /// Encode `value` as a `Double`.
    public mutating func serialize(_ value: Double) throws {
        guard signature[currentIndex] == .double else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Double.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `String` value into bytes.
    private func marshal(_ value: String) throws -> [UInt8] {
        var data: [UInt8] = []
        let length = value.utf8.count
        data.append(contentsOf: try byteSize(UInt32(length)))
        data.append(contentsOf: value.utf8)
        data.append(0x00)
        return data
    }

    /// Encode `value` as a `String`.
    public mutating func serialize(_ value: String) throws {
        guard signature[currentIndex] == .string else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: String.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `ObjectPath` value into bytes.
    private func marshal(_ value: ObjectPath) throws -> [UInt8] {
        return try marshal(value.fullPath)
    }

    /// Encode `value` as a `ObjectPath`.
    public mutating func serialize(_ value: ObjectPath) throws {
        guard signature[currentIndex] == .objectPath else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: ObjectPath.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `Signature` value into bytes.
    private func marshal(_ value: Signature) throws -> [UInt8] {
        var data: [UInt8] = []
        let length = value.rawValue.utf8.count
        data.append(contentsOf: try byteSize(UInt8(length)))
        data.append(contentsOf: value.rawValue.utf8)
        data.append(0x00)
        return data
    }

    /// Encode `value` as a `Signature`.
    public mutating func serialize(_ value: Signature) throws {
        guard signature[currentIndex] == .signature else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Signature.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `DBusVariant` value into bytes.
    private func marshal(_ value: Variant) throws -> [UInt8] {
        var data: [UInt8] = []

        // D-Bus variant format: signature (1 byte length + string + null) + aligned value
        let sigBytes = value.signature.rawValue.utf8
        data.append(UInt8(sigBytes.count))
        data.append(contentsOf: sigBytes)
        data.append(0x00)  // null terminator

        // Apply alignment for the value based on its signature
        let alignment = value.signature.element?.alignment ?? 1
        let currentSize = data.count
        let paddingNeeded = (alignment - (currentSize % alignment)) % alignment
        data.append(contentsOf: Array(repeating: 0, count: paddingNeeded))

        // Now marshal the actual value based on its type
        switch value.value {
        case .byte(let v):
            data.append(contentsOf: try marshal(v))
        case .bool(let v):
            data.append(contentsOf: try marshal(v))
        case .int16(let v):
            data.append(contentsOf: try marshal(v))
        case .uint16(let v):
            data.append(contentsOf: try marshal(v))
        case .int32(let v):
            data.append(contentsOf: try marshal(v))
        case .uint32(let v):
            data.append(contentsOf: try marshal(v))
        case .int64(let v):
            data.append(contentsOf: try marshal(v))
        case .uint64(let v):
            data.append(contentsOf: try marshal(v))
        case .double(let v):
            data.append(contentsOf: try marshal(v))
        case .string(let v):
            data.append(contentsOf: try marshal(v))
        case .objectPath(let v):
            data.append(contentsOf: try marshal(v))
        case .signature(let v):
            data.append(contentsOf: try marshal(v))
        case .array(let elements):
            data.append(contentsOf: try marshalVariantArray(elements, signature: value.signature))
        case .dictionary(let dict):
            data.append(contentsOf: try marshalVariantDictionary(dict, signature: value.signature))
        case .`struct`(let elements):
            data.append(contentsOf: try marshalVariantStruct(elements, signature: value.signature))
        }

        return data
    }

    /// Encode `value` as a `DBusVariant`.
    public mutating func serialize(_ value: Variant) throws {
        guard signature[currentIndex] == .variant else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Variant.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }
        _data.append(contentsOf: try marshal(value))
    }

    /// Marshal `T` value into bytes.
    private func marshal<T>(_ value: T) throws -> [UInt8] {
        switch value {
        case let v as Bool: return try marshal(v)
        case let v as UInt8: return try marshal(v)
        case let v as UInt16: return try marshal(v)
        case let v as UInt32: return try marshal(v)
        case let v as UInt64: return try marshal(v)
        case let v as Int16: return try marshal(v)
        case let v as Int32: return try marshal(v)
        case let v as Int64: return try marshal(v)
        case let v as Double: return try marshal(v)
        case let v as String: return try marshal(v)
        case let v as ObjectPath: return try marshal(v)
        case let v as Signature: return try marshal(v)
        case let v as Variant: return try marshal(v)
        default:
            throw SerializerError.cannotMarshalType(type: T.self)
        }
    }

    /// Encode `value` as an array of type `T`.
    mutating func serialize<T>(_ value: [T]) throws {
        guard case .array(let arrayElement) = signature[currentIndex],
            arrayElement == SignatureElement(T.self)
        else {
            throw
                SerializerError
                .signatureElementMismatch(gotElement: signature[currentIndex], forType: [T].self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }

        var array: [UInt8] = []
        for (index, element) in value.enumerated() {
            array.append(contentsOf: try marshal(element))

            // Apply padding for string and ObjectPath elements to maintain 4-byte alignment
            // (except for the last element)
            if index < value.count - 1 {
                switch signature[currentIndex] {
                case .array(.string), .array(.objectPath):
                    let padding = (4 - (array.count % 4)) % 4
                    array.append(contentsOf: Array(repeating: 0, count: padding))
                default:
                    break
                }
            }
        }

        let length = array.count

        _data.append(contentsOf: try byteSize(UInt32(length)))
        _data.append(contentsOf: array)
    }

    /// Encode `value` as a dictionary of (`K`, `V`).
    mutating func serialize<K: Hashable, V>(_ value: [K: V]) throws {
        guard case .dictionary(let keyElement, let valueElement) = signature[currentIndex],
            keyElement == SignatureElement(K.self), valueElement == SignatureElement(V.self)
        else {
            throw
                SerializerError
                .signatureElementMismatch(
                    gotElement: signature[currentIndex],
                    forType: Dictionary<K, V>.self)
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }

        // Build dictionary entries data first to calculate the correct length
        var dictData: [UInt8] = []
        for (k, v) in value {
            // Dictionary entries are aligned to 8-byte boundaries
            let padding = (8 - (dictData.count % 8)) % 8
            dictData.append(contentsOf: Array(repeating: 0, count: padding))

            dictData.append(contentsOf: try marshal(k))
            dictData.append(contentsOf: try marshal(v))
        }

        // Write the length as UInt32 (following the array format for dictionaries)
        _data.append(contentsOf: try byteSize(UInt32(dictData.count)))

        // Apply 8-byte alignment after length field for dictionary entries (as per D-Bus spec)
        let paddingNeeded = (8 - (_data.count % 8)) % 8
        _data.append(contentsOf: Array(repeating: 0, count: paddingNeeded))

        _data.append(contentsOf: dictData)
    }

    /// Encode a value using another serializer. If the signature is not a STRUCT container,
    /// an error is thrown. The "subserializer" is initialized with the STRUCT container
    /// elements. For example, if the serializer's signature is `(ux)`, the nested serializer's
    /// signature will be `ux`. The caller may then serialize the contents of the struct
    /// accordingly, using the provided serializer.
    mutating func serialize(_ f: (inout Serializer) throws -> Void) throws {
        guard case .struct(let structElements) = signature[currentIndex] else {
            throw
                SerializerError
                .cannotMarshalElement(gotElement: signature[currentIndex])
        }
        defer { currentIndex += 1 }

        if alignmentContext == .message {
            pad(to: signature[currentIndex].alignment)
        }

        var serializer = Serializer(
            signature: Signature(elements: structElements),
            alignmentContext: .structContent,
            endianness: endianness)
        try f(&serializer)
        _data.append(contentsOf: serializer.data!)
    }

    /// Separate the given fixed-width integer value into bytes by shifting the value one byte
    /// at a time and store the least significant bits each time.
    private func byteSize<T: FixedWidthInteger>(_ value: T) throws -> [UInt8] {
        if endianness == .littleEndian {
            return withUnsafeBytes(of: value.littleEndian) { Array($0) }
        } else {
            return withUnsafeBytes(of: value.bigEndian) { Array($0) }
        }
    }

    /// Appends a number of NULL bytes to `_data` to align the buffer to a given alignment.
    ///
    /// Parameters:
    /// - alignment: Boundary within the sequence to align to a factor of
    ///
    /// Returns: A number of elements to advance to align
    private mutating func pad(to alignment: Int) {
        if _data.count % alignment != 0 {
            let newIndex = (_data.count + alignment - 1) & ~(alignment - 1)
            let padding = newIndex - _data.count
            for _ in 0..<padding {
                _data.append(0x00)
            }
        }
    }

    /// Marshal a variant array into D-Bus format
    private func marshalVariantArray(_ elements: [VariantValue], signature: Signature) throws
        -> [UInt8]
    {
        guard let signatureElement = signature.element,
            case .array(let arrayElement) = signatureElement
        else {
            throw SerializerError.cannotMarshalType(type: [VariantValue].self)
        }

        var arrayData: [UInt8] = []

        // Marshal each element
        for (index, element) in elements.enumerated() {
            // Marshal the element using its signature
            let elementSignature = Signature(elements: [arrayElement])
            let elementData = try marshalVariantValue(element, signature: elementSignature)
            arrayData.append(contentsOf: elementData)

            // Add padding for string elements to maintain 4-byte alignment (except for the last element)
            if arrayElement == .string && index < elements.count - 1 {
                let padding = (4 - (arrayData.count % 4)) % 4
                arrayData.append(contentsOf: Array(repeating: 0, count: padding))
            }
        }

        // Create the final array data with length prefix
        var result: [UInt8] = []

        // Array length (4 bytes)
        let arrayLength = UInt32(arrayData.count)
        let lengthBytes: [UInt8]
        if endianness == .littleEndian {
            lengthBytes = withUnsafeBytes(of: arrayLength.littleEndian) { Array($0) }
        } else {
            lengthBytes = withUnsafeBytes(of: arrayLength.bigEndian) { Array($0) }
        }
        result.append(contentsOf: lengthBytes)

        // Add alignment padding for the first element based on its alignment requirements
        // According to D-Bus spec, arrays must pad to the element's alignment boundary
        let alignment = arrayElement.alignment
        let paddingNeeded = (alignment - (result.count % alignment)) % alignment
        result.append(contentsOf: Array(repeating: 0, count: paddingNeeded))

        // Array data
        result.append(contentsOf: arrayData)

        return result
    }

    /// Marshal a variant dictionary into D-Bus format
    private func marshalVariantDictionary(_ dict: [String: VariantValue], signature: Signature)
        throws -> [UInt8]
    {
        guard let signatureElement = signature.element,
            case .dictionary(let keyElement, let valueElement) = signatureElement
        else {
            throw SerializerError.cannotMarshalType(type: [String: VariantValue].self)
        }

        var dictData: [UInt8] = []

        // Marshal each key-value pair
        for (key, value) in dict {
            // Apply 8-byte alignment for each dictionary entry
            let entryPadding = (8 - (dictData.count % 8)) % 8
            dictData.append(contentsOf: Array(repeating: 0, count: entryPadding))

            // Marshal key
            let keySignature = Signature(elements: [keyElement])
            let keyData = try marshalVariantValue(.string(key), signature: keySignature)
            dictData.append(contentsOf: keyData)

            // Marshal value
            let valueSignature = Signature(elements: [valueElement])
            let valueData = try marshalVariantValue(value, signature: valueSignature)
            dictData.append(contentsOf: valueData)
        }

        // Create the final dictionary data with length prefix
        var result: [UInt8] = []

        // Dictionary length (4 bytes)
        let dictLength = UInt32(dictData.count)
        let lengthBytes: [UInt8]
        if endianness == .littleEndian {
            lengthBytes = withUnsafeBytes(of: dictLength.littleEndian) { Array($0) }
        } else {
            lengthBytes = withUnsafeBytes(of: dictLength.bigEndian) { Array($0) }
        }
        result.append(contentsOf: lengthBytes)

        // Apply 8-byte alignment after length field (as per D-Bus spec)
        let paddingNeeded = (8 - (result.count % 8)) % 8
        result.append(contentsOf: Array(repeating: 0, count: paddingNeeded))

        // Dictionary data
        result.append(contentsOf: dictData)

        return result
    }

    /// Marshal a variant struct into D-Bus format
    private func marshalVariantStruct(_ elements: [VariantValue], signature: Signature) throws
        -> [UInt8]
    {
        guard let signatureElement = signature.element,
            case .struct(let structElements) = signatureElement
        else {
            throw SerializerError.cannotMarshalType(type: [VariantValue].self)
        }

        guard elements.count == structElements.count else {
            throw SerializerError.cannotMarshalType(type: [VariantValue].self)
        }

        var structData: [UInt8] = []

        // Apply 8-byte alignment for struct
        let structPadding = (8 - (structData.count % 8)) % 8
        structData.append(contentsOf: Array(repeating: 0, count: structPadding))

        // Marshal each element
        for (index, element) in elements.enumerated() {
            let elementSignatureElement = structElements[index]

            // Apply alignment for each element
            let alignment = elementSignatureElement.alignment
            let paddingNeeded = (alignment - (structData.count % alignment)) % alignment
            structData.append(contentsOf: Array(repeating: 0, count: paddingNeeded))

            // Marshal the element using its signature
            let elementSignature = Signature(elements: [elementSignatureElement])
            let elementData = try marshalVariantValue(element, signature: elementSignature)
            structData.append(contentsOf: elementData)
        }

        return structData
    }

    /// Marshal a variant value based on its type and signature
    private func marshalVariantValue(_ value: VariantValue, signature: Signature) throws
        -> [UInt8]
    {
        switch value {
        case .byte(let v):
            return try marshal(v)
        case .bool(let v):
            return try marshal(v)
        case .int16(let v):
            return try marshal(v)
        case .uint16(let v):
            return try marshal(v)
        case .int32(let v):
            return try marshal(v)
        case .uint32(let v):
            return try marshal(v)
        case .int64(let v):
            return try marshal(v)
        case .uint64(let v):
            return try marshal(v)
        case .double(let v):
            return try marshal(v)
        case .string(let v):
            return try marshal(v)
        case .objectPath(let v):
            return try marshal(v)
        case .signature(let v):
            return try marshal(v)
        case .array(let elements):
            return try marshalVariantArray(elements, signature: signature)
        case .dictionary(let dict):
            return try marshalVariantDictionary(dict, signature: signature)
        case .`struct`(let elements):
            return try marshalVariantStruct(elements, signature: signature)
        }
    }
}

enum SerializerError: Error {
    case signatureElementMismatch(gotElement: SignatureElement, forType: Any.Type)
    case invalidValue(forType: Any.Type)
    case cannotMarshalType(type: Any.Type)
    case cannotMarshalElement(gotElement: SignatureElement)
}
