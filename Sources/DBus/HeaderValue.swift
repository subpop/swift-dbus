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

/// Represents possible values that can be stored in D-Bus header fields
public enum HeaderValue: Equatable, Sendable {
    case string(String)
    case objectPath(ObjectPath)
    case uint32(UInt32)
    case signature(Signature)
    case byte(UInt8)
    case bool(Bool)
    case int16(Int16)
    case uint16(UInt16)
    case int32(Int32)
    case int64(Int64)
    case uint64(UInt64)
    case double(Double)

    /// Get the underlying value as Any for serialization compatibility
    public var anyValue: Any {
        switch self {
        case .string(let value): return value
        case .objectPath(let value): return value
        case .uint32(let value): return value
        case .signature(let value): return value
        case .byte(let value): return value
        case .bool(let value): return value
        case .int16(let value): return value
        case .uint16(let value): return value
        case .int32(let value): return value
        case .int64(let value): return value
        case .uint64(let value): return value
        case .double(let value): return value
        }
    }

    /// Initialize from a typed value
    public init<T>(_ value: T) throws {
        switch value {
        case let v as String: self = .string(v)
        case let v as ObjectPath: self = .objectPath(v)
        case let v as UInt32: self = .uint32(v)
        case let v as Signature: self = .signature(v)
        case let v as UInt8: self = .byte(v)
        case let v as Bool: self = .bool(v)
        case let v as Int16: self = .int16(v)
        case let v as UInt16: self = .uint16(v)
        case let v as Int32: self = .int32(v)
        case let v as Int64: self = .int64(v)
        case let v as UInt64: self = .uint64(v)
        case let v as Double: self = .double(v)
        default:
            throw HeaderValueError.unsupportedType(type: T.self)
        }
    }
}

public enum HeaderValueError: Error {
    case unsupportedType(type: Any.Type)
}

/// A specialized variant type for D-Bus header fields that provides type safety
/// and proper equality comparison without type erasure
public struct HeaderVariant: Equatable, Sendable {
    public let value: HeaderValue
    public let signature: Signature

    public init(value: HeaderValue, signature: Signature) {
        self.value = value
        self.signature = signature
    }

    /// Convenience initializer that creates both value and signature from a typed value
    public init<T>(_ typedValue: T, signature: String) throws {
        self.value = try HeaderValue(typedValue)
        self.signature = Signature(rawValue: signature) ?? Signature(elements: [])
    }

    /// Convenience initializer that creates both value and signature from a typed value
    public init<T>(_ typedValue: T, signature: Signature) throws {
        self.value = try HeaderValue(typedValue)
        self.signature = signature
    }
}

/// Extension to provide convenient accessors for common types
extension HeaderVariant {
    /// Get the value as a String if it's a string type
    public var stringValue: String? {
        if case .string(let value) = self.value {
            return value
        }
        return nil
    }

    /// Get the value as an ObjectPath if it's an object path type
    public var objectPathValue: ObjectPath? {
        if case .objectPath(let value) = self.value {
            return value
        }
        return nil
    }

    /// Get the value as a UInt32 if it's a uint32 type
    public var uint32Value: UInt32? {
        if case .uint32(let value) = self.value {
            return value
        }
        return nil
    }

    /// Get the value as a Signature if it's a signature type
    public var signatureValue: Signature? {
        if case .signature(let value) = self.value {
            return value
        }
        return nil
    }
}
