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

/// Represents a D-Bus object path, which uniquely identifies an object instance exported by a D-Bus service.
///
/// Object paths in D-Bus are similar to file system paths, using forward slashes to separate path components.
/// They must start with a forward slash and can contain only ASCII letters, numbers, and underscores.
///
/// ## Usage Examples
///
/// ```swift
/// // Create an object path for a typical D-Bus service
/// let path = try ObjectPath("/org/freedesktop/NetworkManager")
///
/// // Create a path with multiple components
/// let devicePath = try ObjectPath("/org/freedesktop/NetworkManager/Devices/0")
///
/// // Use with a proxy object
/// let proxy = connection.proxyObject(
///     serviceName: "org.freedesktop.NetworkManager",
///     objectPath: path,
///     interfaceName: "org.freedesktop.NetworkManager"
/// )
/// ```
///
/// ## Path Rules
///
/// - Must begin with a forward slash (`/`)
/// - Components separated by forward slashes
/// - Can contain only ASCII letters (A-Z, a-z), numbers (0-9), and underscores (_)
/// - No empty components (e.g., `//` is invalid)
/// - Root path `/` is valid
///
/// ## Internal Implementation Notes
///
/// The internal representation stores path components as an array of strings without the leading slash,
/// making it efficient to work with individual path segments. The `fullPath` computed property
/// reconstructs the complete path string when needed.
public struct ObjectPath: Sendable {
    /// Internal storage of path components without leading slash
    /// For "/org/freedesktop/Example", this would be ["org", "freedesktop", "Example"]
    private let components: [String]

    /// The complete object path string with leading slash
    ///
    /// This computed property reconstructs the full path from the internal components array.
    /// For internal use by serialization and display methods.
    var fullPath: String {
        "/" + components.joined(separator: "/")
    }

    /// Internal initializer from pre-validated components
    ///
    /// This initializer is used internally when path components are already known to be valid,
    /// avoiding redundant validation. Used by parsers and other internal APIs.
    ///
    /// - Parameter components: Array of valid path components (without leading slash)
    init(components: [String]) {
        self.components = components
    }

    /// Creates an object path from a string representation
    ///
    /// Validates that the provided string conforms to D-Bus object path rules:
    /// - Starts with forward slash
    /// - Contains only valid characters (ASCII letters, numbers, underscores)
    /// - Has no empty path components
    ///
    /// - Parameter value: The object path string (e.g., "/org/freedesktop/Example")
    /// - Throws: `ObjectPathError.invalidValue` if the path format is invalid
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Valid paths
    /// let root = try ObjectPath("/")
    /// let service = try ObjectPath("/org/freedesktop/NetworkManager")
    /// let device = try ObjectPath("/org/freedesktop/NetworkManager/Devices/eth0")
    ///
    /// // Invalid paths (will throw)
    /// let invalid1 = try ObjectPath("missing/leading/slash")  // Error: must start with /
    /// let invalid2 = try ObjectPath("/path/with spaces")      // Error: invalid characters
    /// let invalid3 = try ObjectPath("/path//double/slash")    // Error: empty component
    /// ```
    public init(_ value: String) throws {
        guard value.starts(with: "/") else {
            throw ObjectPathError.invalidValue(
                path: value, message: "object path must begin with '/'")
        }

        let regex = try Regex("[A-Za-z0-9_]+")

        var components: [String] = []
        for segment in value.components(separatedBy: "/") {
            guard segment != "" else {
                continue
            }
            guard segment.contains(regex) else {
                throw ObjectPathError.invalidValue(
                    path: value,
                    message: "object path must contain only the ASCII characters [A-Z][a-z][0-9]_")
            }

            components.append(segment)
        }
        self.components = components
    }
}

extension ObjectPath: Equatable {}

extension ObjectPath: Hashable {
    /// Computes hash based on the full path string
    ///
    /// This allows ObjectPath instances to be used as dictionary keys and in sets.
    /// The hash is computed from the reconstructed full path for consistency.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fullPath)
    }
}

extension ObjectPath: CustomStringConvertible {
    /// Returns the full object path string for display purposes
    ///
    /// This provides a human-readable representation of the object path,
    /// suitable for debugging and logging.
    public var description: String {
        fullPath
    }
}

extension ObjectPath: RawRepresentable {
    /// The raw string representation of the object path
    ///
    /// Provides access to the underlying path string, enabling easy conversion
    /// to and from string representations for serialization and API boundaries.
    public var rawValue: String {
        fullPath
    }

    /// Creates an ObjectPath from a raw string value
    ///
    /// This failable initializer provides a safe way to create ObjectPath instances
    /// from potentially invalid strings, returning nil if validation fails.
    ///
    /// - Parameter rawValue: The raw object path string
    /// - Returns: An ObjectPath instance, or nil if the string is invalid
    ///
    /// ```swift
    /// let validPath = ObjectPath(rawValue: "/org/example/Service")   // Returns ObjectPath
    /// let invalidPath = ObjectPath(rawValue: "invalid path")         // Returns nil
    /// ```
    public init?(rawValue: String) {
        do {
            self = try ObjectPath(rawValue)
        } catch {
            return nil
        }
    }
}

extension ObjectPath: Encodable {
    /// Encodes the object path as its string representation
    ///
    /// Supports Swift's Encodable protocol for JSON and other serialization formats.
    /// The object path is encoded as its full string value.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
}

extension ObjectPath: Decodable {
    /// Decodes an object path from its string representation
    ///
    /// Supports Swift's Decodable protocol for JSON and other deserialization formats.
    /// Validates the decoded string to ensure it's a valid object path.
    ///
    /// - Throws: `DecodingError` if the decoded string is not a valid object path
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = try container.decode(ObjectPath.self)
    }
}

/// Errors that can occur when creating or working with object paths
///
/// These errors provide detailed information about object path validation failures,
/// helping developers identify and fix invalid path strings.
public enum ObjectPathError: Error {
    /// The provided path string is invalid
    ///
    /// - Parameters:
    ///   - path: The invalid path string that was provided
    ///   - message: A detailed description of why the path is invalid
    ///
    /// Common validation failures include:
    /// - Missing leading slash
    /// - Invalid characters (anything other than A-Z, a-z, 0-9, _)
    /// - Empty path components (consecutive slashes)
    case invalidValue(path: String, message: String)
}
