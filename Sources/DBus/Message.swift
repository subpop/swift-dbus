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

/// D-Bus message type as defined in the specification
public enum DBusMessageType: UInt8, CaseIterable, Sendable {
    case methodCall = 1
    case methodReturn = 2
    case error = 3
    case signal = 4
}

/// D-Bus message flags as defined in the specification
public struct DBusMessageFlags: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// No reply is expected to this message
    public static let noReplyExpected = DBusMessageFlags(rawValue: 0x01)

    /// The bus must not launch an owner for the destination name
    public static let noAutoStart = DBusMessageFlags(rawValue: 0x02)

    /// This message may prompt the user for authorization
    public static let allowInteractiveAuthorization = DBusMessageFlags(rawValue: 0x04)
}

/// D-Bus header field codes as defined in the specification
public enum DBusHeaderField: UInt8, CaseIterable, Sendable {
    case path = 1
    case interface = 2
    case member = 3
    case errorName = 4
    case replySerial = 5
    case destination = 6
    case sender = 7
    case signature = 8
    case unixFDs = 9
}

/// Represents a D-Bus header field with its code and value
public struct DBusHeaderFieldEntry: Sendable {
    public let field: DBusHeaderField
    public let value: HeaderVariant

    public init(field: DBusHeaderField, value: HeaderVariant) {
        self.field = field
        self.value = value
    }
}

public enum Endianness: Sendable {
    case littleEndian
    case bigEndian
}

/// Represents a complete D-Bus message according to the specification
public struct Message: Sendable {
    /// Message endianness ('l' for little-endian, 'B' for big-endian)
    public let endianness: Endianness

    /// Type of the message
    public let messageType: DBusMessageType

    /// Message flags
    public let flags: DBusMessageFlags

    /// D-Bus protocol version (currently always 1)
    public let protocolVersion: UInt8

    /// Length of the message body in bytes
    public let bodyLength: UInt32

    /// Message serial number (must not be zero)
    public let serial: UInt32

    /// Array of header fields
    public let headerFields: [DBusHeaderFieldEntry]

    /// Message body data
    public let body: [UInt8]

    /// Message body signature (if any)
    public let bodySignature: Signature?

    // MARK: - Convenience Properties

    /// Object path from header fields
    public var path: ObjectPath? {
        return headerFields.first { $0.field == .path }?.value.objectPathValue
    }

    /// Interface name from header fields
    public var interface: String? {
        return headerFields.first { $0.field == .interface }?.value.stringValue
    }

    /// Member (method/signal) name from header fields
    public var member: String? {
        return headerFields.first { $0.field == .member }?.value.stringValue
    }

    /// Error name from header fields
    public var errorName: String? {
        return headerFields.first { $0.field == .errorName }?.value.stringValue
    }

    /// Reply serial from header fields
    public var replySerial: UInt32? {
        return headerFields.first { $0.field == .replySerial }?.value.uint32Value
    }

    /// Destination bus name from header fields
    public var destination: String? {
        return headerFields.first { $0.field == .destination }?.value.stringValue
    }

    /// Sender bus name from header fields
    public var sender: String? {
        return headerFields.first { $0.field == .sender }?.value.stringValue
    }

    // MARK: - Initializers

    /// Initialize a D-Bus message with all components
    ///
    /// Creates a new D-Bus message with the specified parameters. The message must have a non-zero serial
    /// and use protocol version 1 (the only currently supported version).
    ///
    /// - Parameters:
    ///   - endianness: Byte order for the message (default: little-endian)
    ///   - messageType: Type of D-Bus message (method call, return, error, or signal)
    ///   - flags: Message flags controlling behavior (default: no flags)
    ///   - protocolVersion: D-Bus protocol version (default: 1, only supported version)
    ///   - serial: Unique message serial number (must not be zero)
    ///   - headerFields: Array of header field entries containing message metadata
    ///   - body: Message body data as raw bytes
    ///   - bodySignature: Optional signature describing the body structure
    /// - Throws: `DBusMessageError.invalidSerial` if serial is zero,
    ///           `DBusMessageError.unsupportedProtocolVersion` if protocol version is not 1
    public init(
        endianness: Endianness = .littleEndian,
        messageType: DBusMessageType,
        flags: DBusMessageFlags = [],
        protocolVersion: UInt8 = 1,
        serial: UInt32,
        headerFields: [DBusHeaderFieldEntry] = [],
        body: [UInt8] = [],
        bodySignature: Signature? = nil
    ) throws {
        guard serial != 0 else {
            throw DBusMessageError.invalidSerial
        }

        guard protocolVersion == 1 else {
            throw DBusMessageError.unsupportedProtocolVersion(protocolVersion)
        }

        self.endianness = endianness
        self.messageType = messageType
        self.flags = flags
        self.protocolVersion = protocolVersion
        self.bodyLength = UInt32(body.count)
        self.serial = serial
        self.headerFields = headerFields
        self.body = body
        self.bodySignature = bodySignature
    }

    // MARK: - Convenience Initializers

    /// Create a method call message
    ///
    /// Creates a D-Bus method call message with the required path and member fields.
    /// Method calls are used to invoke methods on remote D-Bus objects.
    ///
    /// - Parameters:
    ///   - path: Object path identifying the target object
    ///   - interface: Optional interface name (recommended for disambiguation)
    ///   - member: Name of the method to call
    ///   - destination: Optional destination bus name
    ///   - serial: Unique message serial number
    ///   - body: Optional message body containing method arguments
    ///   - bodySignature: Optional signature describing the body structure
    ///   - flags: Message flags (default: no flags)
    /// - Returns: A new method call message
    /// - Throws: `DBusMessageError` if message construction fails
    public static func methodCall(
        path: ObjectPath,
        interface: String? = nil,
        member: String,
        destination: String? = nil,
        serial: UInt32,
        body: [UInt8] = [],
        bodySignature: Signature? = nil,
        flags: DBusMessageFlags = []
    ) throws -> Message {
        var headerFields: [DBusHeaderFieldEntry] = [
            DBusHeaderFieldEntry(
                field: .path, value: try HeaderVariant(path, signature: "o")),
            DBusHeaderFieldEntry(
                field: .member, value: try HeaderVariant(member, signature: "s")),
        ]

        if let interface = interface {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .interface,
                    value: try HeaderVariant(interface, signature: "s")))
        }

        if let destination = destination {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .destination,
                    value: try HeaderVariant(destination, signature: "s")))
        }

        if let bodySignature = bodySignature {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .signature,
                    value: try HeaderVariant(bodySignature, signature: "g")))
        }

        return try Message(
            messageType: .methodCall,
            flags: flags,
            serial: serial,
            headerFields: headerFields,
            body: body,
            bodySignature: bodySignature
        )
    }

    /// Create a method return message
    ///
    /// Creates a D-Bus method return message in response to a method call.
    /// Method returns contain the result of a successful method invocation.
    ///
    /// - Parameters:
    ///   - replySerial: Serial number of the method call this is responding to
    ///   - destination: Optional destination bus name (usually the original sender)
    ///   - serial: Unique serial number for this return message
    ///   - body: Optional message body containing return values
    ///   - bodySignature: Optional signature describing the return value structure
    /// - Returns: A new method return message
    /// - Throws: `DBusMessageError` if message construction fails
    public static func methodReturn(
        replySerial: UInt32,
        destination: String? = nil,
        serial: UInt32,
        body: [UInt8] = [],
        bodySignature: Signature? = nil
    ) throws -> Message {
        var headerFields: [DBusHeaderFieldEntry] = [
            DBusHeaderFieldEntry(
                field: .replySerial,
                value: try HeaderVariant(replySerial, signature: "u"))
        ]

        if let destination = destination {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .destination,
                    value: try HeaderVariant(destination, signature: "s")))
        }

        if let bodySignature = bodySignature {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .signature,
                    value: try HeaderVariant(bodySignature, signature: "g")))
        }

        return try Message(
            messageType: .methodReturn,
            serial: serial,
            headerFields: headerFields,
            body: body,
            bodySignature: bodySignature
        )
    }

    /// Create an error message
    ///
    /// Creates a D-Bus error message in response to a failed method call.
    /// Error messages indicate that a method call could not be completed successfully.
    ///
    /// - Parameters:
    ///   - errorName: Well-known error name identifying the type of error
    ///   - replySerial: Serial number of the method call that failed
    ///   - destination: Optional destination bus name (usually the original sender)
    ///   - serial: Unique serial number for this error message
    ///   - body: Optional message body containing error details
    ///   - bodySignature: Optional signature describing the error detail structure
    /// - Returns: A new error message
    /// - Throws: `DBusMessageError` if message construction fails
    public static func error(
        errorName: String,
        replySerial: UInt32,
        destination: String? = nil,
        serial: UInt32,
        body: [UInt8] = [],
        bodySignature: Signature? = nil
    ) throws -> Message {
        var headerFields: [DBusHeaderFieldEntry] = [
            DBusHeaderFieldEntry(
                field: .errorName, value: try HeaderVariant(errorName, signature: "s")),
            DBusHeaderFieldEntry(
                field: .replySerial,
                value: try HeaderVariant(replySerial, signature: "u")),
        ]

        if let destination = destination {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .destination,
                    value: try HeaderVariant(destination, signature: "s")))
        }

        if let bodySignature = bodySignature {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .signature,
                    value: try HeaderVariant(bodySignature, signature: "g")))
        }

        return try Message(
            messageType: .error,
            serial: serial,
            headerFields: headerFields,
            body: body,
            bodySignature: bodySignature
        )
    }

    /// Create a signal message
    ///
    /// Creates a D-Bus signal message for broadcasting events or notifications.
    /// Signals are one-way messages that don't expect a response.
    ///
    /// - Parameters:
    ///   - path: Object path of the object emitting the signal
    ///   - interface: Interface name that defines the signal
    ///   - member: Name of the signal being emitted
    ///   - destination: Optional destination bus name (usually omitted for broadcasts)
    ///   - serial: Unique message serial number
    ///   - body: Optional message body containing signal data
    ///   - bodySignature: Optional signature describing the signal data structure
    /// - Returns: A new signal message
    /// - Throws: `DBusMessageError` if message construction fails
    public static func signal(
        path: ObjectPath,
        interface: String,
        member: String,
        destination: String? = nil,
        serial: UInt32,
        body: [UInt8] = [],
        bodySignature: Signature? = nil
    ) throws -> Message {
        var headerFields: [DBusHeaderFieldEntry] = [
            DBusHeaderFieldEntry(
                field: .path, value: try HeaderVariant(path, signature: "o")),
            DBusHeaderFieldEntry(
                field: .interface, value: try HeaderVariant(interface, signature: "s")),
            DBusHeaderFieldEntry(
                field: .member, value: try HeaderVariant(member, signature: "s")),
        ]

        if let destination = destination {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .destination,
                    value: try HeaderVariant(destination, signature: "s")))
        }

        if let bodySignature = bodySignature {
            headerFields.append(
                DBusHeaderFieldEntry(
                    field: .signature,
                    value: try HeaderVariant(bodySignature, signature: "g")))
        }

        return try Message(
            messageType: .signal,
            serial: serial,
            headerFields: headerFields,
            body: body,
            bodySignature: bodySignature
        )
    }
}

// MARK: - Serialization

extension Message {
    /// Serialize the message to D-Bus wire format
    ///
    /// Converts the message to the binary wire format used by D-Bus for transmission
    /// over the message bus. The serialized format includes the fixed header, variable
    /// header fields, and message body with proper alignment and endianness.
    ///
    /// - Returns: Byte array containing the serialized message
    /// - Throws: `DBusMessageError.messageTooLarge` if the message exceeds 128 MiB,
    ///           `DBusMessageError.serializationFailed` if serialization fails
    public func serialize() throws -> [UInt8] {
        var result: [UInt8] = []

        // Serialize fixed header (12 bytes)
        result.append(endianness == .littleEndian ? UInt8(ascii: "l") : UInt8(ascii: "B"))
        result.append(messageType.rawValue)
        result.append(flags.rawValue)
        result.append(protocolVersion)

        // Body length (4 bytes, respecting endianness)
        let bodyLengthBytes: [UInt8]
        if endianness == .littleEndian {
            bodyLengthBytes = withUnsafeBytes(of: bodyLength.littleEndian) { Array($0) }
        } else {
            bodyLengthBytes = withUnsafeBytes(of: bodyLength.bigEndian) { Array($0) }
        }
        result.append(contentsOf: bodyLengthBytes)

        // Serial (4 bytes, respecting endianness)
        let serialBytes: [UInt8]
        if endianness == .littleEndian {
            serialBytes = withUnsafeBytes(of: serial.littleEndian) { Array($0) }
        } else {
            serialBytes = withUnsafeBytes(of: serial.bigEndian) { Array($0) }
        }
        result.append(contentsOf: serialBytes)

        // Serialize header fields array
        let headerFieldsData = try serializeHeaderFields()
        result.append(contentsOf: headerFieldsData)

        // Pad header to 8-byte boundary
        let paddingNeeded = (8 - (result.count % 8)) % 8
        result.append(contentsOf: Array(repeating: 0, count: paddingNeeded))

        // Combine header and body
        result.append(contentsOf: body)

        // Validate maximum message size (128 MiB)
        guard result.count <= 134_217_728 else {
            throw DBusMessageError.messageTooLarge
        }

        return result
    }

    /// Serialize the header fields array into D-Bus wire format
    ///
    /// Converts the message's header fields into a properly formatted array structure
    /// as required by D-Bus specification. Header fields are serialized as:
    /// Array of STRUCT(BYTE field_code, VARIANT value)
    ///
    /// Each STRUCT is 8-byte aligned and contains:
    /// - BYTE field_code (1 byte)
    /// - VARIANT (signature + aligned value)
    ///
    /// - Returns: Byte array containing the serialized header fields array
    /// - Throws: `DBusMessageError.serializationFailed` if any field cannot be serialized
    private func serializeHeaderFields() throws -> [UInt8] {
        var result: [UInt8] = []

        // Calculate total size of header fields
        var fieldsData: [UInt8] = []

        // Sort header fields by field code to ensure consistent ordering
        // Some D-Bus implementations expect fields in ascending order
        let sortedFields = headerFields.sorted { $0.field.rawValue < $1.field.rawValue }

        for field in sortedFields {
            // Start of new STRUCT - align to 8-byte boundary
            let structPadding = (8 - (fieldsData.count % 8)) % 8
            fieldsData.append(contentsOf: Array(repeating: 0, count: structPadding))

            // STRUCT content: (BYTE field_code, VARIANT value)

            // 1. Field code (1 byte)
            fieldsData.append(field.field.rawValue)

            // 2. VARIANT: signature (1 byte length + string + null) + aligned value
            let sigBytes = field.value.signature.rawValue.utf8
            fieldsData.append(UInt8(sigBytes.count))
            fieldsData.append(contentsOf: sigBytes)
            fieldsData.append(0)  // null terminator

            // Calculate alignment for the variant value within this STRUCT
            // We need to account for the current position within the message
            let currentMessageOffset = 16 + 4 + fieldsData.count  // fixed header + array length + current position
            let alignment = getAlignment(for: field.value.signature)
            let valuePadding = (alignment - (currentMessageOffset % alignment)) % alignment
            fieldsData.append(contentsOf: Array(repeating: 0, count: valuePadding))

            // Serialize the variant value
            let valueData = try serializeVariantValue(
                field.value.value.anyValue, signature: field.value.signature)
            fieldsData.append(contentsOf: valueData)
        }

        // Array length (4 bytes, respecting endianness)
        let arrayLength = UInt32(fieldsData.count)
        let lengthBytes: [UInt8]
        if endianness == .littleEndian {
            lengthBytes = withUnsafeBytes(of: arrayLength.littleEndian) { Array($0) }
        } else {
            lengthBytes = withUnsafeBytes(of: arrayLength.bigEndian) { Array($0) }
        }
        result.append(contentsOf: lengthBytes)

        // Array data
        result.append(contentsOf: fieldsData)

        return result
    }

    /// Serialize a header variant into D-Bus wire format
    ///
    /// Converts a header variant (signature + value) into the D-Bus wire format. The serialized
    /// format includes the signature length, signature string, null terminator, and the
    /// serialized value. Alignment is handled by the caller.
    ///
    /// - Parameter variant: The header variant to serialize
    /// - Returns: Byte array containing the serialized variant
    /// - Throws: `DBusMessageError.serializationFailed` if the variant cannot be serialized
    private func serializeVariant(_ variant: HeaderVariant) throws -> [UInt8] {
        var result: [UInt8] = []

        // Signature length and data
        let sigBytes = variant.signature.rawValue.utf8
        result.append(UInt8(sigBytes.count))
        result.append(contentsOf: sigBytes)
        result.append(0)  // null terminator

        // Serialize the value based on signature (no alignment here - handled by caller)
        let valueData = try serializeVariantValue(
            variant.value.anyValue, signature: variant.signature)
        result.append(contentsOf: valueData)

        return result
    }

    /// Serialize a variant value based on its signature
    ///
    /// Converts a value to its D-Bus wire format representation based on the provided
    /// signature. Currently supports basic types: strings (s), object paths (o),
    /// unsigned 32-bit integers (u), and signatures (g).
    ///
    /// - Parameters:
    ///   - value: The value to serialize
    ///   - signature: The D-Bus signature describing the value type
    /// - Returns: Byte array containing the serialized value
    /// - Throws: `DBusMessageError.serializationFailed` if the value cannot be serialized
    private func serializeVariantValue(_ value: Any, signature: Signature) throws -> [UInt8] {
        // Simple implementation for common types
        switch signature.rawValue {
        case "s":  // string
            if let str = value as? String {
                var result: [UInt8] = []
                let strBytes = str.utf8
                let lengthBytes: [UInt8]
                if endianness == .littleEndian {
                    lengthBytes = withUnsafeBytes(of: UInt32(strBytes.count).littleEndian) {
                        Array($0)
                    }
                } else {
                    lengthBytes = withUnsafeBytes(of: UInt32(strBytes.count).bigEndian) {
                        Array($0)
                    }
                }
                result.append(contentsOf: lengthBytes)
                result.append(contentsOf: strBytes)
                result.append(0)  // null terminator
                return result
            }
        case "o":  // object path
            if let path = value as? ObjectPath {
                let pathStr = path.fullPath
                var result: [UInt8] = []
                let strBytes = pathStr.utf8
                let lengthBytes: [UInt8]
                if endianness == .littleEndian {
                    lengthBytes = withUnsafeBytes(of: UInt32(strBytes.count).littleEndian) {
                        Array($0)
                    }
                } else {
                    lengthBytes = withUnsafeBytes(of: UInt32(strBytes.count).bigEndian) {
                        Array($0)
                    }
                }
                result.append(contentsOf: lengthBytes)
                result.append(contentsOf: strBytes)
                result.append(0)  // null terminator
                return result
            }
        case "u":  // uint32
            if let num = value as? UInt32 {
                if endianness == .littleEndian {
                    return withUnsafeBytes(of: num.littleEndian) { Array($0) }
                } else {
                    return withUnsafeBytes(of: num.bigEndian) { Array($0) }
                }
            }
        case "g":  // signature
            if let sig = value as? Signature {
                var result: [UInt8] = []
                let sigBytes = sig.rawValue.utf8
                result.append(UInt8(sigBytes.count))
                result.append(contentsOf: sigBytes)
                result.append(0)  // null terminator
                return result
            }
        default:
            break
        }

        throw DBusMessageError.serializationFailed
    }

    /// Get the alignment requirements for a D-Bus type signature
    ///
    /// Returns the byte alignment required for the given D-Bus type signature.
    /// This is used to ensure proper padding in the serialized message format.
    ///
    /// - Parameter signature: The D-Bus type signature
    /// - Returns: Alignment requirement in bytes (1, 2, 4, or 8)
    private func getAlignment(for signature: Signature) -> Int {
        // Return alignment requirements for different types
        switch signature.rawValue {
        case "y", "g": return 1
        case "n", "q": return 2
        case "b", "i", "u", "s", "o": return 4
        case "x", "t", "d": return 8
        default: return 1
        }
    }
}

// MARK: - Deserialization

extension Message {
    /// Deserialize a D-Bus message from wire format
    ///
    /// Parses a D-Bus message from its binary wire format representation. The method
    /// extracts the fixed header, variable header fields, and message body while
    /// respecting the message's endianness and alignment requirements.
    ///
    /// - Parameter data: Byte array containing the serialized message
    /// - Returns: A parsed D-Bus message
    /// - Throws: Various `DBusMessageError` cases for invalid format, endianness,
    ///           message type, protocol version, serial, or body length
    public static func deserialize(from data: [UInt8]) throws -> Message {
        guard data.count >= 16 else {
            throw DBusMessageError.invalidMessageFormat
        }

        var index = 0

        // Determine endianness
        let endiannessChar = data[0]
        let endianness: Endianness
        switch endiannessChar {
        case UInt8(ascii: "l"):
            endianness = .littleEndian
        case UInt8(ascii: "B"):
            endianness = .bigEndian
        default:
            throw DBusMessageError.invalidEndianness
        }
        index += 1

        // Parse fixed header
        let messageTypeRaw = data[index]
        index += 1

        let flagsRaw = data[index]
        index += 1

        let protocolVersion = data[index]
        index += 1

        // Body length (4 bytes)
        guard index + 4 <= data.count else {
            throw DBusMessageError.invalidMessageFormat
        }
        let bodyLength: UInt32
        if endianness == .littleEndian {
            bodyLength =
                UInt32(data[index]) | (UInt32(data[index + 1]) << 8)
                | (UInt32(data[index + 2]) << 16) | (UInt32(data[index + 3]) << 24)
        } else {
            bodyLength =
                (UInt32(data[index]) << 24) | (UInt32(data[index + 1]) << 16)
                | (UInt32(data[index + 2]) << 8) | UInt32(data[index + 3])
        }
        index += 4

        // Serial (4 bytes)
        guard index + 4 <= data.count else {
            throw DBusMessageError.invalidMessageFormat
        }
        let serial: UInt32
        if endianness == .littleEndian {
            serial =
                UInt32(data[index]) | (UInt32(data[index + 1]) << 8)
                | (UInt32(data[index + 2]) << 16) | (UInt32(data[index + 3]) << 24)
        } else {
            serial =
                (UInt32(data[index]) << 24) | (UInt32(data[index + 1]) << 16)
                | (UInt32(data[index + 2]) << 8) | UInt32(data[index + 3])
        }
        index += 4

        // Validate values
        guard let messageType = DBusMessageType(rawValue: messageTypeRaw) else {
            throw DBusMessageError.invalidMessageType(messageTypeRaw)
        }

        guard protocolVersion == 1 else {
            throw DBusMessageError.unsupportedProtocolVersion(protocolVersion)
        }

        guard serial != 0 else {
            throw DBusMessageError.invalidSerial
        }

        let flags = DBusMessageFlags(rawValue: flagsRaw)

        // Parse header fields array
        guard index + 4 <= data.count else {
            throw DBusMessageError.invalidMessageFormat
        }
        let headerFieldsLength: UInt32
        if endianness == .littleEndian {
            headerFieldsLength =
                UInt32(data[index]) | (UInt32(data[index + 1]) << 8)
                | (UInt32(data[index + 2]) << 16) | (UInt32(data[index + 3]) << 24)
        } else {
            headerFieldsLength =
                (UInt32(data[index]) << 24) | (UInt32(data[index + 1]) << 16)
                | (UInt32(data[index + 2]) << 8) | UInt32(data[index + 3])
        }
        index += 4

        let headerFieldsEndIndex = index + Int(headerFieldsLength)
        guard headerFieldsEndIndex <= data.count else {
            throw DBusMessageError.invalidMessageFormat
        }

        let headerFields = try parseHeaderFields(
            from: Array(data[index..<headerFieldsEndIndex]), endianness: endianness)
        index = headerFieldsEndIndex

        // Pad to 8-byte boundary
        let paddingNeeded = (8 - (index % 8)) % 8
        index += paddingNeeded

        // Extract body
        let bodyEndIndex = index + Int(bodyLength)
        guard bodyEndIndex <= data.count else {
            throw DBusMessageError.invalidBodyLength
        }

        let body = Array(data[index..<bodyEndIndex])

        // Extract body signature if present
        let bodySignature =
            headerFields.first { $0.field == .signature }?.value.signatureValue

        return try Message(
            endianness: endianness,
            messageType: messageType,
            flags: flags,
            protocolVersion: protocolVersion,
            serial: serial,
            headerFields: headerFields,
            body: body,
            bodySignature: bodySignature
        )
    }

    /// Parse header fields from serialized D-Bus data
    ///
    /// Extracts header field entries from the header fields array section of a D-Bus message.
    /// Each field consists of a field code followed by a variant containing the field value.
    /// Unknown field codes are skipped to maintain forward compatibility.
    ///
    /// - Parameters:
    ///   - data: Byte array containing the header fields data
    ///   - endianness: Byte order for parsing multi-byte values
    /// - Returns: Array of parsed header field entries
    /// - Throws: `DBusMessageError.invalidMessageFormat` for malformed data
    private static func parseHeaderFields(from data: [UInt8], endianness: Endianness) throws
        -> [DBusHeaderFieldEntry]
    {
        var fields: [DBusHeaderFieldEntry] = []
        var index = 0

        while index < data.count {
            // Skip any padding bytes (0x00) at the current position
            while index < data.count && data[index] == 0 {
                index += 1
            }

            guard index < data.count else {
                break
            }

            // Field code (1 byte)
            let fieldCode = data[index]
            index += 1

            guard let field = DBusHeaderField(rawValue: fieldCode) else {
                // Skip unknown field - we need to parse the variant to skip it properly
                // For now, just break to avoid infinite loop
                break
            }

            // Parse variant
            let (variant, bytesRead) = try parseVariant(
                from: data, startingAt: index, endianness: endianness)
            index += bytesRead

            fields.append(DBusHeaderFieldEntry(field: field, value: variant))

            // Align to 8-byte boundary for next field
            let totalOffset = 16 + index  // 16 is the fixed header size
            let padding = (8 - (totalOffset % 8)) % 8
            index += padding
        }

        return fields
    }

    /// Parse a variant from serialized D-Bus data
    ///
    /// Extracts a variant (signature + value) from D-Bus wire format. The method parses
    /// the signature length, signature string, and then the aligned value data based
    /// on the signature's alignment requirements.
    ///
    /// - Parameters:
    ///   - data: Byte array containing the variant data
    ///   - startIndex: Starting position in the data array
    ///   - endianness: Byte order for parsing multi-byte values
    /// - Returns: Tuple containing the parsed variant and number of bytes consumed
    /// - Throws: `DBusMessageError.invalidMessageFormat` for malformed data
    private static func parseVariant(
        from data: [UInt8], startingAt startIndex: Int, endianness: Endianness
    ) throws -> (
        HeaderVariant, Int
    ) {
        var index = startIndex

        // Parse signature
        guard index < data.count else {
            throw DBusMessageError.invalidMessageFormat
        }

        let sigLength = Int(data[index])
        index += 1

        guard index + sigLength + 1 <= data.count else {
            throw DBusMessageError.invalidMessageFormat
        }

        let sigBytes = data[index..<index + sigLength]
        let sigString = String(bytes: sigBytes, encoding: .utf8) ?? ""
        index += sigLength + 1  // +1 for null terminator

        guard let signature = Signature(rawValue: sigString) else {
            throw DBusMessageError.invalidMessageFormat
        }

        // Align to value boundary
        let alignment = getStaticAlignment(for: signature)
        let padding = (alignment - (index % alignment)) % alignment
        index += padding

        // Parse value
        let (value, valueBytes) = try parseVariantValue(
            from: data, startingAt: index, signature: signature, endianness: endianness)
        index += valueBytes

        let headerValue = try HeaderValue(value)
        let variant = HeaderVariant(value: headerValue, signature: signature)
        return (variant, index - startIndex)
    }

    /// Parse a variant value from serialized D-Bus data based on its signature
    ///
    /// Extracts a typed value from D-Bus wire format according to the provided signature.
    /// Currently supports basic types: strings (s), object paths (o), unsigned 32-bit
    /// integers (u), and signatures (g).
    ///
    /// - Parameters:
    ///   - data: Byte array containing the value data
    ///   - startIndex: Starting position in the data array
    ///   - signature: D-Bus signature describing the value type
    ///   - endianness: Byte order for parsing multi-byte values
    /// - Returns: Tuple containing the parsed value and number of bytes consumed
    /// - Throws: `DBusMessageError.invalidMessageFormat` for malformed data or unsupported types
    private static func parseVariantValue(
        from data: [UInt8], startingAt startIndex: Int, signature: Signature, endianness: Endianness
    ) throws -> (Any, Int) {
        var index = startIndex

        switch signature.rawValue {
        case "s":  // string
            guard index + 4 <= data.count else {
                throw DBusMessageError.invalidMessageFormat
            }
            let length: UInt32
            if endianness == .littleEndian {
                length =
                    UInt32(data[index]) | (UInt32(data[index + 1]) << 8)
                    | (UInt32(data[index + 2]) << 16) | (UInt32(data[index + 3]) << 24)
            } else {
                length =
                    (UInt32(data[index]) << 24) | (UInt32(data[index + 1]) << 16)
                    | (UInt32(data[index + 2]) << 8) | UInt32(data[index + 3])
            }
            index += 4

            guard index + Int(length) + 1 <= data.count else {
                throw DBusMessageError.invalidMessageFormat
            }

            let stringBytes = data[index..<index + Int(length)]
            let string = String(bytes: stringBytes, encoding: .utf8) ?? ""
            index += Int(length) + 1  // +1 for null terminator

            return (string, index - startIndex)

        case "o":  // object path
            guard index + 4 <= data.count else {
                throw DBusMessageError.invalidMessageFormat
            }
            let length: UInt32
            if endianness == .littleEndian {
                length =
                    UInt32(data[index]) | (UInt32(data[index + 1]) << 8)
                    | (UInt32(data[index + 2]) << 16) | (UInt32(data[index + 3]) << 24)
            } else {
                length =
                    (UInt32(data[index]) << 24) | (UInt32(data[index + 1]) << 16)
                    | (UInt32(data[index + 2]) << 8) | UInt32(data[index + 3])
            }
            index += 4

            guard index + Int(length) + 1 <= data.count else {
                throw DBusMessageError.invalidMessageFormat
            }

            let pathBytes = data[index..<index + Int(length)]
            let pathString = String(bytes: pathBytes, encoding: .utf8) ?? ""
            index += Int(length) + 1  // +1 for null terminator

            let path = try ObjectPath(pathString)
            return (path, index - startIndex)

        case "u":  // uint32
            guard index + 4 <= data.count else {
                throw DBusMessageError.invalidMessageFormat
            }
            let value: UInt32
            if endianness == .littleEndian {
                value =
                    UInt32(data[index]) | (UInt32(data[index + 1]) << 8)
                    | (UInt32(data[index + 2]) << 16) | (UInt32(data[index + 3]) << 24)
            } else {
                value =
                    (UInt32(data[index]) << 24) | (UInt32(data[index + 1]) << 16)
                    | (UInt32(data[index + 2]) << 8) | UInt32(data[index + 3])
            }
            index += 4

            return (value, index - startIndex)

        case "g":  // signature
            guard index < data.count else {
                throw DBusMessageError.invalidMessageFormat
            }
            let length = Int(data[index])
            index += 1

            guard index + length + 1 <= data.count else {
                throw DBusMessageError.invalidMessageFormat
            }

            let sigBytes = data[index..<index + length]
            let sigString = String(bytes: sigBytes, encoding: .utf8) ?? ""
            index += length + 1  // +1 for null terminator

            guard let sig = Signature(rawValue: sigString) else {
                throw DBusMessageError.invalidMessageFormat
            }

            return (sig, index - startIndex)

        default:
            throw DBusMessageError.invalidMessageFormat
        }
    }

    /// Get the static alignment requirements for a D-Bus type signature
    ///
    /// Returns the byte alignment required for the given D-Bus type signature when
    /// parsing values from serialized data. This is used to ensure proper alignment
    /// when reading values from the wire format.
    ///
    /// - Parameter signature: The D-Bus type signature
    /// - Returns: Alignment requirement in bytes (1, 2, 4, or 8)
    private static func getStaticAlignment(for signature: Signature) -> Int {
        // Return alignment requirements for different types
        switch signature.rawValue {
        case "y", "g": return 1
        case "n", "q": return 2
        case "b", "i", "u", "s", "o": return 4
        case "x", "t", "d": return 8
        default: return 1
        }
    }
}

// MARK: - Validation

extension Message {
    /// Validate message according to D-Bus specification
    ///
    /// Performs comprehensive validation of the message structure and content according
    /// to the D-Bus specification. Checks serial number, protocol version, body length
    /// consistency, required header fields for each message type, and message size limits.
    ///
    /// - Throws: Various `DBusMessageError` cases for validation failures including
    ///           invalid serial, unsupported protocol version, body length mismatch,
    ///           missing required header fields, or message too large
    public func validate() throws {
        // Check serial
        guard serial != 0 else {
            throw DBusMessageError.invalidSerial
        }

        // Check protocol version
        guard protocolVersion == 1 else {
            throw DBusMessageError.unsupportedProtocolVersion(protocolVersion)
        }

        // Check body length
        guard bodyLength == UInt32(body.count) else {
            throw DBusMessageError.invalidBodyLength
        }

        // Validate required header fields for each message type
        try validateRequiredHeaderFields()

        // Check maximum message size
        let estimatedSize = body.count + (headerFields.count * 32) + 64  // rough estimate
        guard estimatedSize <= 134_217_728 else {
            throw DBusMessageError.messageTooLarge
        }
    }

    /// Validate that required header fields are present for the message type
    ///
    /// Checks that all mandatory header fields are present based on the message type:
    /// - Method calls require path and member
    /// - Method returns require replySerial
    /// - Errors require errorName and replySerial
    /// - Signals require path, interface, and member
    ///
    /// - Throws: `DBusMessageError.missingRequiredHeaderField` if a required field is missing
    private func validateRequiredHeaderFields() throws {
        switch messageType {
        case .methodCall:
            guard path != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.path)
            }
            guard member != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.member)
            }

        case .methodReturn:
            guard replySerial != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.replySerial)
            }

        case .error:
            guard errorName != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.errorName)
            }
            guard replySerial != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.replySerial)
            }

        case .signal:
            guard path != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.path)
            }
            guard interface != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.interface)
            }
            guard member != nil else {
                throw DBusMessageError.missingRequiredHeaderField(.member)
            }
        }
    }
}

// MARK: - Errors

public enum DBusMessageError: Error, Equatable {
    case invalidSerial
    case unsupportedProtocolVersion(UInt8)
    case invalidMessageFormat
    case invalidEndianness
    case invalidMessageType(UInt8)
    case invalidBodyLength
    case messageTooLarge
    case serializationFailed
    case missingRequiredHeaderField(DBusHeaderField)
}

// MARK: - Equatable

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.endianness == rhs.endianness && lhs.messageType == rhs.messageType
            && lhs.flags == rhs.flags && lhs.protocolVersion == rhs.protocolVersion
            && lhs.bodyLength == rhs.bodyLength && lhs.serial == rhs.serial
            && lhs.headerFields.count == rhs.headerFields.count && lhs.body == rhs.body
            && lhs.bodySignature == rhs.bodySignature
    }
}

extension DBusHeaderFieldEntry: Equatable {
    public static func == (lhs: DBusHeaderFieldEntry, rhs: DBusHeaderFieldEntry) -> Bool {
        return lhs.field == rhs.field && lhs.value == rhs.value
    }
}
