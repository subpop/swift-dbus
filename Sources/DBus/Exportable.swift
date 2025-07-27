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
import XMLCoder

// MARK: - Errors

/// Comprehensive error types for the Exportable object system
///
/// These errors cover various failure scenarios when working with exported D-Bus objects,
/// from interface validation to method call handling and signal emission.
///
/// ## Error Categories
///
/// - **Interface/Method Validation**: `invalidInterface`, `invalidMethod`, `invalidProperty`, `invalidSignal`
/// - **Object Management**: `objectNotExported`, `propertyNotFound`
/// - **Runtime Operations**: `methodCallFailed`, `signalEmissionFailed`
/// - **Message Processing**: `invalidMessage`
///
/// ## Usage in Error Handling
///
/// ```swift
/// do {
///     try await connection.export(myService, at: ObjectPath("/com/example/Service"))
/// } catch ExportableError.invalidInterface(let interface) {
///     print("Invalid interface: \(interface)")
/// } catch ExportableError.objectNotExported(let path) {
///     print("Object not found at path: \(path)")
/// }
/// ```
public enum ExportableError: Error, Equatable {
    /// The specified interface name is invalid or not found
    ///
    /// This error occurs when trying to access an interface that doesn't exist
    /// on the exported object or when the interface name is malformed.
    ///
    /// - Parameter String: The invalid interface name
    case invalidInterface(String)

    /// The specified method name is invalid or not found in the interface
    ///
    /// This error occurs when a D-Bus method call targets a method that doesn't
    /// exist in the specified interface or when the method name is malformed.
    ///
    /// - Parameter String: The invalid method name
    case invalidMethod(String)

    /// No object is exported at the specified object path
    ///
    /// This error occurs when trying to access an exported object that has been
    /// unexported or was never exported at the given path.
    ///
    /// - Parameter ObjectPath: The path where no object was found
    case objectNotExported(ObjectPath)

    /// Failed to emit a D-Bus signal
    ///
    /// This error occurs when signal emission fails due to network issues,
    /// serialization problems, or connection failures.
    ///
    /// - Parameter String: Description of the signal emission failure
    case signalEmissionFailed(String)

    /// The specified property was not found in the interface
    ///
    /// This error occurs when trying to get or set a property that doesn't
    /// exist in the object's interface definition.
    ///
    /// - Parameter String: The property name that was not found
    case propertyNotFound(String)

    /// A method call on the exported object failed
    ///
    /// This error occurs when the exported object's method implementation
    /// throws an error or fails to execute properly.
    ///
    /// - Parameter String: Description of the method call failure
    case methodCallFailed(String)

    /// The received D-Bus message is invalid or malformed
    ///
    /// This error occurs when processing a D-Bus message that doesn't conform
    /// to expected format or contains invalid data.
    ///
    /// - Parameter Message: The invalid message that caused the error
    case invalidMessage(Message)

    /// The specified property definition is invalid
    ///
    /// This error occurs when a property definition in an interface is malformed
    /// or conflicts with D-Bus property specifications.
    ///
    /// - Parameter String: The invalid property name or description
    case invalidProperty(String)

    /// The specified signal definition is invalid
    ///
    /// This error occurs when a signal definition in an interface is malformed
    /// or conflicts with D-Bus signal specifications.
    ///
    /// - Parameter String: The invalid signal name or description
    case invalidSignal(String)

    /// Equatable conformance for comparing ExportableError instances
    ///
    /// Enables equality comparison between different error instances, useful for
    /// testing and error handling logic.
    public static func == (lhs: ExportableError, rhs: ExportableError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidInterface(let lhsStr), .invalidInterface(let rhsStr)):
            return lhsStr == rhsStr
        case (.invalidMethod(let lhsStr), .invalidMethod(let rhsStr)):
            return lhsStr == rhsStr
        case (.objectNotExported(let lhsPath), .objectNotExported(let rhsPath)):
            return lhsPath == rhsPath
        case (.signalEmissionFailed(let lhsStr), .signalEmissionFailed(let rhsStr)):
            return lhsStr == rhsStr
        case (.propertyNotFound(let lhsStr), .propertyNotFound(let rhsStr)):
            return lhsStr == rhsStr
        case (.methodCallFailed(let lhsStr), .methodCallFailed(let rhsStr)):
            return lhsStr == rhsStr
        case (.invalidMessage(let lhsMsg), .invalidMessage(let rhsMsg)):
            return lhsMsg.serial == rhsMsg.serial && lhsMsg.messageType == rhsMsg.messageType
        case (.invalidProperty(let lhsStr), .invalidProperty(let rhsStr)):
            return lhsStr == rhsStr
        case (.invalidSignal(let lhsStr), .invalidSignal(let rhsStr)):
            return lhsStr == rhsStr
        default:
            return false
        }
    }
}

// MARK: - Method Call and Return Structures

/// Represents a D-Bus method call with all necessary context
///
/// This structure encapsulates all the information needed to represent a D-Bus method
/// call, including the target interface, method name, arguments, and signature information.
/// It's used internally by the exportable object system to handle incoming method calls.
///
/// ## Usage Context
///
/// This is primarily used internally by the exportable object system and is not
/// typically created directly by user code. It represents the parsed and validated
/// information from an incoming D-Bus method call message.
///
/// ## Example Structure
///
/// ```swift
/// let methodCall = MethodCall(
///     interface: "com.example.Calculator",
///     member: "Add",
///     path: ObjectPath("/com/example/Calculator"),
///     destination: "com.example.MyApp",
///     arguments: [Int32(5), Int32(3)],
///     signature: Signature("ii"),
///     replySignature: Signature("i")
/// )
/// ```
public struct MethodCall: Sendable {
    /// The D-Bus interface the method belongs to
    ///
    /// This identifies which interface contains the method being called.
    /// Example: "com.example.Calculator"
    public let interface: String

    /// The name of the method being called
    ///
    /// This is the specific method name within the interface.
    /// Example: "Add", "GetProperty", "Shutdown"
    public let member: String

    /// The object path where the method should be invoked
    ///
    /// This specifies which exported object instance should handle the call.
    /// Example: ObjectPath("/com/example/Calculator")
    public let path: ObjectPath

    /// The destination service name for the method call
    ///
    /// This is typically the well-known name or unique name of the service
    /// that should receive the method call.
    public let destination: String

    /// The arguments to pass to the method
    ///
    /// An array of encodable values that will be serialized as method arguments.
    /// The types must match the method's signature.
    public let arguments: [(any Sendable & Encodable)?]

    /// The D-Bus signature of the method arguments
    ///
    /// This describes the types of the arguments being passed to the method.
    /// Example: Signature("ii") for two integers
    public let signature: Signature

    /// The expected D-Bus signature of the method's return value
    ///
    /// This describes what types the method is expected to return, or nil
    /// if the method returns no value.
    public let replySignature: Signature?

    /// Creates a new method call representation
    ///
    /// - Parameters:
    ///   - interface: The D-Bus interface name
    ///   - member: The method name
    ///   - path: The target object path
    ///   - destination: The destination service name
    ///   - arguments: The method arguments
    ///   - signature: The argument signature
    ///   - replySignature: The expected return signature (nil for void methods)
    public init(
        interface: String,
        member: String,
        path: ObjectPath,
        destination: String,
        arguments: [(any Sendable & Encodable)?],
        signature: Signature,
        replySignature: Signature?
    ) {
        self.interface = interface
        self.member = member
        self.path = path
        self.destination = destination
        self.arguments = arguments
        self.signature = signature
        self.replySignature = replySignature
    }
}

/// Represents the return value from a D-Bus method call
///
/// This structure encapsulates the result of a successful D-Bus method execution,
/// including both the return signature and the actual return values. It's used
/// internally by the exportable object system to construct method return messages.
///
/// ## Usage Context
///
/// Created by exported object implementations when returning values from method calls.
/// The exportable object system uses this to construct the proper D-Bus method return message.
///
/// ## Example Usage
///
/// ```swift
/// // Return a single integer
/// let result = MethodReturn(
///     signature: Signature("i"),
///     arguments: [Int32(42)]
/// )
///
/// // Return multiple values
/// let multiResult = MethodReturn(
///     signature: Signature("si"),
///     arguments: ["Hello", Int32(123)]
/// )
///
/// // Return no value (void method)
/// let voidResult = MethodReturn(
///     signature: Signature(""),
///     arguments: []
/// )
/// ```
public struct MethodReturn: Sendable {
    /// The D-Bus signature of the return values
    ///
    /// This describes the types of the values being returned.
    /// Use an empty signature for void methods.
    public let signature: Signature

    /// The return values from the method
    ///
    /// An array of encodable values that will be serialized as the method's
    /// return values. The types must match the signature.
    public let arguments: [(any Sendable & Encodable)?]

    /// Creates a new method return representation
    ///
    /// - Parameters:
    ///   - signature: The D-Bus signature of the return values
    ///   - arguments: The actual return values
    public init(signature: Signature, arguments: [(any Sendable & Encodable)?]) {
        self.signature = signature
        self.arguments = arguments
    }
}

// MARK: - Interface Components

/// Direction of a D-Bus method argument
///
/// D-Bus method arguments can be input parameters (provided by the caller)
/// or output parameters (returned by the method). This enum specifies the
/// direction for introspection and validation purposes.
///
/// ## Usage in Interface Definitions
///
/// ```swift
/// let method = Method(
///     name: "Calculate",
///     arguments: [
///         Argument(name: "operand1", signature: Signature("i"), direction: .in),
///         Argument(name: "operand2", signature: Signature("i"), direction: .in),
///         Argument(name: "result", signature: Signature("i"), direction: .out)
///     ]
/// )
/// ```
public enum ArgumentDirection: String, Sendable, Encodable {
    /// Input argument (provided by the caller)
    case `in`
    /// Output argument (returned by the method)
    case out
}

/// Represents a D-Bus method argument definition
///
/// This structure defines a single argument for a D-Bus method, including its
/// name, type signature, direction, and any annotations. It's used in interface
/// definitions for introspection and validation.
///
/// ## Usage in Method Definitions
///
/// Arguments are used to define the input and output parameters of D-Bus methods:
///
/// ```swift
/// let arguments = [
///     Argument(name: "input", signature: Signature("s"), direction: .in),
///     Argument(name: "count", signature: Signature("i"), direction: .in),
///     Argument(name: "result", signature: Signature("as"), direction: .out)
/// ]
/// ```
///
/// ## Annotations
///
/// Arguments can include D-Bus annotations for additional metadata:
///
/// ```swift
/// let annotatedArg = Argument(
///     name: "data",
///     signature: Signature("ay"),
///     direction: .in,
///     annotations: [
///         Annotation(name: "org.freedesktop.DBus.Property.EmitsChangedSignal", value: "true")
///     ]
/// )
/// ```
public struct Argument: Sendable, Encodable {
    /// The name of the argument
    ///
    /// Used for introspection and documentation. Should be descriptive
    /// and follow D-Bus naming conventions.
    public let name: String

    /// The D-Bus type signature of the argument
    ///
    /// Specifies the data type of this argument using D-Bus type notation.
    public let signature: Signature

    /// Whether this is an input or output argument
    ///
    /// Input arguments are provided by the caller, output arguments are
    /// returned by the method.
    public let direction: ArgumentDirection

    /// D-Bus annotations for this argument
    ///
    /// Additional metadata that can be used by D-Bus tools and implementations
    /// for enhanced functionality or documentation.
    public let annotations: [Annotation]

    /// Creates a new argument definition
    ///
    /// - Parameters:
    ///   - name: The argument name
    ///   - signature: The argument's D-Bus type signature
    ///   - direction: Whether this is an input or output argument
    ///   - annotations: Optional D-Bus annotations
    public init(
        name: String, signature: Signature, direction: ArgumentDirection,
        annotations: [Annotation] = []
    ) {
        self.name = name
        self.signature = signature
        self.direction = direction
        self.annotations = annotations
    }
}

/// Method definition with signatures
///
/// This structure defines a complete D-Bus method including its name, arguments,
/// and any annotations. It's used in interface definitions to specify what
/// methods are available on an exported object.
///
/// ## Usage in Interface Definitions
///
/// ```swift
/// let addMethod = Method(
///     name: "Add",
///     arguments: [
///         Argument(name: "a", signature: Signature("i"), direction: .in),
///         Argument(name: "b", signature: Signature("i"), direction: .in),
///         Argument(name: "result", signature: Signature("i"), direction: .out)
///     ]
/// )
///
/// let interface = Interface(
///     name: "com.example.Calculator",
///     methods: ["Add": addMethod]
/// )
/// ```
///
/// ## Method Annotations
///
/// Methods can include D-Bus annotations for additional functionality:
///
/// ```swift
/// let deprecatedMethod = Method(
///     name: "OldMethod",
///     arguments: [],
///     annotations: [
///         Annotation(name: "org.freedesktop.DBus.Deprecated", value: "true")
///     ]
/// )
/// ```
public struct Method: Sendable, Encodable {
    /// The name of the method
    ///
    /// This is the method name that clients will use when calling the method.
    /// Should follow D-Bus naming conventions (PascalCase).
    public let name: String

    /// The method's argument definitions
    ///
    /// An array of Argument structures defining both input and output parameters.
    /// The order matters for the D-Bus wire protocol.
    public let arguments: [Argument]

    /// D-Bus annotations for this method
    ///
    /// Additional metadata for D-Bus tools and enhanced functionality.
    public let annotations: [Annotation]

    /// Creates a new method definition
    ///
    /// - Parameters:
    ///   - name: The method name
    ///   - arguments: The method's argument definitions
    ///   - annotations: Optional D-Bus annotations
    public init(name: String, arguments: [Argument], annotations: [Annotation] = []) {
        self.name = name
        self.arguments = arguments
        self.annotations = annotations
    }

    /// Input arguments for the method
    public var inputArguments: [Argument] {
        return arguments.filter { $0.direction == .in }
    }

    /// Output arguments for the method
    public var outputArguments: [Argument] {
        return arguments.filter { $0.direction == .out }
    }

    /// Input signature for the method
    public var inputSignature: Signature {
        let signatures = inputArguments.map { $0.signature.rawValue }
        return Signature(rawValue: signatures.joined()) ?? Signature(elements: [])
    }

    /// Output signature for the method
    public var outputSignature: Signature {
        let signatures = outputArguments.map { $0.signature.rawValue }
        return Signature(rawValue: signatures.joined()) ?? Signature(elements: [])
    }
}

/// Property definition
public struct Property: Sendable, Encodable {
    public let name: String
    public let signature: Signature
    public let access: PropertyAccess
    public let annotations: [Annotation]

    public enum PropertyAccess: String, Sendable, Encodable {
        case read
        case write
        case readwrite
    }

    public init(
        name: String, signature: Signature, access: PropertyAccess, annotations: [Annotation] = []
    ) {
        self.name = name
        self.signature = signature
        self.access = access
        self.annotations = annotations
    }
}

/// Signal definition
public struct Signal: Sendable, Encodable {
    public let name: String
    public let signature: Signature
    public let annotations: [Annotation]

    public init(name: String, signature: Signature, annotations: [Annotation] = []) {
        self.name = name
        self.signature = signature
        self.annotations = annotations
    }
}

/// Annotation definition for D-Bus interfaces, methods, properties, and signals
public struct Annotation: Sendable, Encodable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// Enhanced interface definition with method signatures and signal definitions
public struct Interface: Sendable, Encodable {
    public let name: String
    public let methods: [String: Method]
    public let properties: [String: Property]
    public let signals: [String: Signal]
    public let annotations: [Annotation]

    public init(
        name: String, methods: [String: Method] = [:], properties: [String: Property] = [:],
        signals: [String: Signal] = [:], annotations: [Annotation] = []
    ) {
        self.name = name
        self.methods = methods
        self.properties = properties
        self.signals = signals
        self.annotations = annotations
    }

    /// Check if the interface has a specific method
    public func hasMethod(_ name: String) -> Bool {
        return methods[name] != nil
    }

    /// Check if the interface has a specific property
    public func hasProperty(_ name: String) -> Bool {
        return properties[name] != nil
    }

    /// Check if the interface has a specific signal
    public func hasSignal(_ name: String) -> Bool {
        return signals[name] != nil
    }
}

// MARK: - Exportable Protocol

/// A protocol for objects that can be exported by a Connection.
public protocol Exportable: AnyObject, Sendable {
    /// Call a method on the object. The arguments are not decoded because
    /// the caller does not know the strong types expected by the method.
    /// Therefor the callee must decode the arguments internally. It is
    /// expected to return a tuple containing the signature of the result and
    /// the raw result.
    ///
    /// - Parameters:
    ///   - interface: The interface the method belongs to.
    ///   - method: The name of the method to call.
    ///   - signature: The signature of the method.
    ///   - arguments: The raw arguments for the method.
    /// - Returns: A tuple containing the signature of the result and the raw result.
    func call(interface: String, method: String, signature: Signature, arguments: [UInt8])
        async throws -> (Signature, [UInt8])

    func getProperty(interface: String, name: String) async throws -> (Signature, [UInt8])

    func setProperty(interface: String, name: String, variant: Variant) async throws

    var interfaces: [String: Interface] { get set }
}

// MARK: - Protocol for Type Erasure

/// Protocol to allow type erasure for exported objects
public protocol ExportableObjectProtocol: Actor {
    func handleMethodCall(message: Message) async throws -> Message?
    func getIntrospectionData() throws -> String
    func setExportContext(connection: Connection, path: ObjectPath) async
    func removeExportContext() async
}

// MARK: - Exportable Object Wrapper

/// A wrapper for an Exportable object that handles method calls and maintains object state.
public actor ExportableObject<T: Exportable>: ExportableObjectProtocol {
    /// The object being exported.
    private let object: T

    /// The path of the object being exported.
    private var objectPath: ObjectPath?

    /// The connection being used to export the object.
    private weak var connection: Connection?

    public init(object: T) {
        self.object = object

        // Implement the org.freedesktop.DBus.Introspectable interface
        let introspectableInterface = Interface(
            name: "org.freedesktop.DBus.Introspectable",
            methods: [
                "Introspect": Method(
                    name: "Introspect",
                    arguments: [
                        Argument(name: "xml_data", signature: Signature("s"), direction: .out)
                    ]
                )
            ]
        )
        self.object.interfaces[introspectableInterface.name] = introspectableInterface

        // Implement the org.freedesktop.DBus.Peer interface
        let peerInterface = Interface(
            name: "org.freedesktop.DBus.Peer",
            methods: [
                "Ping": Method(
                    name: "Ping",
                    arguments: []
                ),
                "GetMachineId": Method(
                    name: "GetMachineId",
                    arguments: [
                        Argument(name: "machine_uuid", signature: Signature("s"), direction: .out)
                    ]
                ),
            ]
        )
        self.object.interfaces[peerInterface.name] = peerInterface

        // Implement the org.freedesktop.DBus.Properties interface
        let propertiesInterface = Interface(
            name: "org.freedesktop.DBus.Properties",
            methods: [
                "Get": Method(
                    name: "Get",
                    arguments: [
                        Argument(name: "interface_name", signature: Signature("s"), direction: .in),
                        Argument(name: "property_name", signature: Signature("s"), direction: .in),
                        Argument(name: "value", signature: Signature("v"), direction: .out),
                    ]
                ),
                "Set": Method(
                    name: "Set",
                    arguments: [
                        Argument(name: "interface_name", signature: Signature("s"), direction: .in),
                        Argument(name: "property_name", signature: Signature("s"), direction: .in),
                        Argument(name: "value", signature: Signature("v"), direction: .in),
                    ]
                ),
                "GetAll": Method(
                    name: "GetAll",
                    arguments: [
                        Argument(name: "interface_name", signature: Signature("s"), direction: .in),
                        Argument(name: "props", signature: Signature("a{sv}"), direction: .out),
                    ]
                ),
            ],
            signals: [
                "PropertiesChanged": Signal(
                    name: "PropertiesChanged",
                    signature: Signature("sa{sv}as")
                )
            ]
        )
        self.object.interfaces[propertiesInterface.name] = propertiesInterface
    }

    /// Set the connection and object path when the object is exported
    public func setExportContext(connection: Connection, path: ObjectPath) async {
        self.connection = connection
        self.objectPath = path
    }

    /// Remove the export context when the object is unexported
    public func removeExportContext() async {
        self.connection = nil
        self.objectPath = nil
    }

    /// Handle a D-Bus method call message
    public func handleMethodCall(message: Message) async throws -> Message? {
        guard let connection = connection else {
            throw ExportableError.methodCallFailed("No connection available")
        }

        /// Verify the message is a method call
        guard message.messageType == .methodCall else {
            throw ExportableError.invalidMessage(message)
        }

        /// Verify the message has an interface
        guard let interfaceName = message.interface else {
            throw ExportableError.invalidMessage(message)
        }

        /// Verify the message has a member
        guard let methodName = message.member else {
            throw ExportableError.invalidMessage(message)
        }

        // Handle standard D-Bus interfaces directly
        let result: (Signature, [UInt8])

        switch interfaceName {
        case "org.freedesktop.DBus.Introspectable":
            switch methodName {
            case "Introspect":
                // Handle introspection directly
                let introspectionData = try getIntrospectionData()
                let encoder = DBusEncoder()
                let data = try encoder.encode(introspectionData, signature: "s")
                result = (Signature("s"), data)
            default:
                throw ExportableError.invalidMethod(methodName)
            }

        case "org.freedesktop.DBus.Peer":
            switch methodName {
            case "Ping":
                // Ping does not return any data
                result = (Signature(""), [])
            case "GetMachineId":
                // Return a machine ID
                let machineId = getMachineId()
                let encoder = DBusEncoder()
                let data = try encoder.encode(machineId, signature: "s")
                result = (Signature("s"), data)
            default:
                throw ExportableError.invalidMethod(methodName)
            }

        case "org.freedesktop.DBus.Properties":
            switch methodName {
            case "Get":
                // Get(interface: String, property: String) -> Variant
                var deserializer = Deserializer(
                    data: message.body, signature: message.bodySignature ?? Signature("ss"),
                    endianness: .littleEndian, alignmentContext: .message)
                let propInterface: String = try deserializer.unserialize()
                let propName: String = try deserializer.unserialize()

                let propResult = try await object.getProperty(
                    interface: propInterface, name: propName)

                // Create variant from the property result
                let variant = try createVariant(from: propResult.1, signature: propResult.0)
                let encoder = DBusEncoder()
                let variantData = try encoder.encode(variant, signature: "v")
                result = (Signature("v"), variantData)

            case "Set":
                // Set(interface: String, property: String, value: Variant) -> void
                var deserializer = Deserializer(
                    data: message.body, signature: message.bodySignature ?? Signature("ssv"),
                    endianness: .littleEndian, alignmentContext: .message)
                let propInterface: String = try deserializer.unserialize()
                let propName: String = try deserializer.unserialize()
                let variant: Variant = try deserializer.unserialize()

                try await object.setProperty(
                    interface: propInterface, name: propName, variant: variant)
                result = (Signature(""), [])

            case "GetAll":
                // GetAll(interface: String) -> Dictionary<String, Variant>
                var deserializer = Deserializer(
                    data: message.body, signature: message.bodySignature ?? Signature("s"),
                    endianness: .littleEndian, alignmentContext: .message)
                let interfaceName: String = try deserializer.unserialize()

                // Collect all properties from the specified interface
                var propertiesDict: [String: Variant] = [:]

                if let interface = object.interfaces[interfaceName] {
                    // Get all properties for this interface
                    for (propertyName, _) in interface.properties {
                        do {
                            let (signature, data) = try await object.getProperty(
                                interface: interfaceName, name: propertyName)
                            let variant = try createVariant(from: data, signature: signature)
                            propertiesDict[propertyName] = variant
                        } catch {
                            // Skip properties that can't be retrieved
                            continue
                        }
                    }
                }

                let encoder = DBusEncoder()
                let dictData = try encoder.encode(propertiesDict, signature: "a{sv}")
                result = (Signature("a{sv}"), dictData)

            default:
                throw ExportableError.invalidMethod(methodName)
            }

        default:
            // Handle custom interfaces by delegating to the object
            guard let interface = object.interfaces[interfaceName] else {
                throw ExportableError.invalidInterface(interfaceName)
            }

            /// Verify the method exists
            guard let method = interface.methods[methodName] else {
                throw ExportableError.invalidMethod(methodName)
            }

            // Verify the message has the correct signature for the method
            if let signature = message.bodySignature {
                guard signature == method.inputSignature else {
                    throw ExportableError.invalidMessage(message)
                }
            }

            // Call the object's method handler
            result = try await object.call(
                interface: interface.name,
                method: method.name,
                signature: method.inputSignature,
                arguments: message.body
            )

            // Verify the result signature matches the method's output signature
            guard result.0 == method.outputSignature else {
                throw ExportableError.methodCallFailed("Result signature mismatch")
            }
        }

        // Convert the result to a Message
        let responseMessage = try Message.methodReturn(
            replySerial: message.serial,
            destination: message.sender,
            serial: await connection.nextSerial(),
            body: result.1,
            bodySignature: result.0
        )

        return responseMessage
    }

    /// Create a variant from raw data and signature
    private func createVariant(from data: [UInt8], signature: Signature) throws -> Variant {
        // For simplicity, we'll create a string variant for now
        // In a real implementation, this would decode based on the signature
        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian,
            alignmentContext: .structContent)

        switch signature.rawValue {
        case "s":
            let stringValue: String = try deserializer.unserialize()
            return Variant(value: .string(stringValue), signature: signature)
        case "i":
            let intValue: Int32 = try deserializer.unserialize()
            return Variant(value: .int32(intValue), signature: signature)
        case "b":
            let boolValue: Bool = try deserializer.unserialize()
            return Variant(value: .bool(boolValue), signature: signature)
        default:
            // Default to string for unknown types
            let stringValue = String(data: Data(data), encoding: .utf8) ?? ""
            return Variant(value: .string(stringValue), signature: Signature("s"))
        }
    }

    /// Generate a machine ID. In a real implementation, this might read from /etc/machine-id
    /// or use a platform-specific mechanism. For now, we'll generate a simple UUID-based ID.
    private func getMachineId() -> String {
        // Generate a consistent machine ID based on hostname or use a default
        if let hostname = ProcessInfo.processInfo.hostName.data(using: .utf8) {
            let hash = hostname.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                var result: UInt64 = 0
                for byte in bytes {
                    result = result &* 31 &+ UInt64(byte)
                }
                return result
            }
            return String(format: "%016x%016x", hash, hash)  // 32 character hex string
        }
        return "0123456789abcdef0123456789abcdef"  // fallback
    }

    // MARK: - Introspection Support

    /// Introspection node structure for D-Bus XML
    private struct IntrospectionNode: Sendable, Encodable {
        let interface: [IntrospectionInterface]

        private enum CodingKeys: String, CodingKey {
            case interface
        }
    }

    /// Introspection interface structure
    private struct IntrospectionInterface: Sendable, Encodable, DynamicNodeEncoding {
        let name: String
        let method: [IntrospectionMethod]
        let property: [IntrospectionProperty]
        let signal: [IntrospectionSignal]
        let annotation: [IntrospectionAnnotation]

        init(interface: Interface) {
            self.name = interface.name
            self.method = interface.methods.values.map { IntrospectionMethod(method: $0) }
            self.property = interface.properties.values.map { IntrospectionProperty(property: $0) }
            self.signal = interface.signals.values.map { IntrospectionSignal(signal: $0) }
            self.annotation = interface.annotations.map { IntrospectionAnnotation(annotation: $0) }
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key.stringValue {
            case "name":
                return .attribute
            default:
                return .element
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case method
            case property
            case signal
            case annotation
        }
    }

    /// Introspection method structure
    private struct IntrospectionMethod: Sendable, Encodable, DynamicNodeEncoding {
        let name: String
        let arg: [IntrospectionArgument]
        let annotation: [IntrospectionAnnotation]

        init(method: Method) {
            self.name = method.name
            self.arg = method.arguments.map { IntrospectionArgument(argument: $0) }
            self.annotation = method.annotations.map { IntrospectionAnnotation(annotation: $0) }
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key.stringValue {
            case "name":
                return .attribute
            default:
                return .element
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case arg
            case annotation
        }
    }

    /// Introspection argument structure
    private struct IntrospectionArgument: Sendable, Encodable, DynamicNodeEncoding {
        let name: String
        let type: String
        let direction: String
        let annotation: [IntrospectionAnnotation]

        init(argument: Argument) {
            self.name = argument.name
            self.type = argument.signature.rawValue
            self.direction = argument.direction.rawValue
            self.annotation = argument.annotations.map { IntrospectionAnnotation(annotation: $0) }
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key.stringValue {
            case "name", "type", "direction":
                return .attribute
            default:
                return .element
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case direction
            case annotation
        }
    }

    /// Introspection property structure
    private struct IntrospectionProperty: Sendable, Encodable, DynamicNodeEncoding {
        let name: String
        let type: String
        let access: String
        let annotation: [IntrospectionAnnotation]

        init(property: Property) {
            self.name = property.name
            self.type = property.signature.rawValue
            self.access = property.access.rawValue
            self.annotation = property.annotations.map { IntrospectionAnnotation(annotation: $0) }
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key.stringValue {
            case "name", "type", "access":
                return .attribute
            default:
                return .element
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case access
            case annotation
        }
    }

    /// Introspection signal structure
    private struct IntrospectionSignal: Sendable, Encodable, DynamicNodeEncoding {
        let name: String
        let arg: [IntrospectionSignalArgument]
        let annotation: [IntrospectionAnnotation]

        init(signal: Signal) {
            self.name = signal.name
            // For now, signals don't have detailed argument information in our Signal struct
            // so we create empty arg array. This could be enhanced later.
            self.arg = []
            self.annotation = signal.annotations.map { IntrospectionAnnotation(annotation: $0) }
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key.stringValue {
            case "name":
                return .attribute
            default:
                return .element
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case arg
            case annotation
        }
    }

    /// Introspection signal argument structure
    private struct IntrospectionSignalArgument: Sendable, Encodable, DynamicNodeEncoding {
        let name: String
        let type: String
        let annotation: [IntrospectionAnnotation]

        init(name: String, type: String, annotations: [Annotation] = []) {
            self.name = name
            self.type = type
            self.annotation = annotations.map { IntrospectionAnnotation(annotation: $0) }
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key.stringValue {
            case "name", "type":
                return .attribute
            default:
                return .element
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case annotation
        }
    }

    /// Introspection annotation structure
    private struct IntrospectionAnnotation: Sendable, Encodable, DynamicNodeEncoding {
        let name: String
        let value: String

        init(annotation: Annotation) {
            self.name = annotation.name
            self.value = annotation.value
        }

        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key.stringValue {
            case "name", "value":
                return .attribute
            default:
                return .element
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case value
        }
    }

    /// Get introspection data for the object
    public func getIntrospectionData() throws -> String {
        let interfaces = object.interfaces.values.map { IntrospectionInterface(interface: $0) }
        let node = IntrospectionNode(interface: interfaces)

        let encoder = XMLEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(node, withRootKey: "node")
        var xmlString = String(data: data, encoding: .utf8) ?? ""

        // Add the proper XML declaration and DOCTYPE
        let xmlDeclaration = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        let docType =
            "<!DOCTYPE node PUBLIC \"-//freedesktop//DTD D-BUS Object Introspection 1.0//EN\" \"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd\">\n"

        if xmlString.hasPrefix("<?xml") {
            // Replace the existing XML declaration
            if let firstNewline = xmlString.firstIndex(of: "\n") {
                xmlString = String(xmlString[xmlString.index(after: firstNewline)...])
            }
        }

        // Ensure we don't have self-closing <node /> tags - replace with <node></node>
        xmlString = xmlString.replacingOccurrences(of: "<node />", with: "<node></node>")

        return xmlDeclaration + docType + xmlString
    }

    // MARK: - Signal Emission

    /// Emit a D-Bus signal from this exported object (no arguments version)
    /// - Parameters:
    ///   - interface: The interface name the signal belongs to
    ///   - signal: The signal name
    /// - Throws: ExportableError if the object is not exported or signal emission fails
    public func emitSignal(interface: String, signal: String) async throws {
        try await emitSignal(
            interface: interface, signal: signal, body: [], signature: Signature(""))
    }

    /// Emit a D-Bus signal with pre-encoded body data
    /// - Parameters:
    ///   - interface: The interface name the signal belongs to
    ///   - signal: The signal name
    ///   - body: Pre-encoded signal body data
    ///   - signature: The signature of the body data
    /// - Throws: ExportableError if the object is not exported or signal emission fails
    public func emitSignal(
        interface: String,
        signal: String,
        body: [UInt8],
        signature: Signature
    ) async throws {
        guard let connection = connection, let objectPath = objectPath else {
            throw ExportableError.objectNotExported(try ObjectPath("/"))
        }

        // Verify the interface exists and has this signal
        guard let interfaceDefinition = object.interfaces[interface] else {
            throw ExportableError.invalidInterface(interface)
        }

        guard interfaceDefinition.signals[signal] != nil else {
            throw ExportableError.invalidSignal(signal)
        }

        // Create and send the signal message
        let message = try Message.signal(
            path: objectPath,
            interface: interface,
            member: signal,
            serial: await connection.nextSerial(),
            body: body,
            bodySignature: signature.rawValue.isEmpty ? nil : signature
        )

        _ = try await connection.send(message: message)
    }

    /// Helper method to serialize arguments for signals
    private func serializeArgument(
        _ argument: any Sendable & Encodable, to serializer: inout Serializer
    ) throws {
        switch argument {
        case let value as Bool:
            try serializer.serialize(value)
        case let value as UInt8:
            try serializer.serialize(value)
        case let value as Int16:
            try serializer.serialize(value)
        case let value as UInt16:
            try serializer.serialize(value)
        case let value as Int32:
            try serializer.serialize(value)
        case let value as UInt32:
            try serializer.serialize(value)
        case let value as Int64:
            try serializer.serialize(value)
        case let value as UInt64:
            try serializer.serialize(value)
        case let value as Double:
            try serializer.serialize(value)
        case let value as String:
            try serializer.serialize(value)
        case let value as ObjectPath:
            try serializer.serialize(value)
        case let value as Signature:
            try serializer.serialize(value)
        case let value as Variant:
            try serializer.serialize(value)
        default:
            throw ExportableError.signalEmissionFailed(
                "Unsupported argument type: \(type(of: argument))")
        }
    }
}

// MARK: - Object Manager

/// Exportable object manager that handles multiple exported objects
public actor ExportableObjectManager {
    private var exportedObjects: [ObjectPath: any ExportableObjectProtocol] = [:]
    private weak var connection: Connection?

    public init(connection: Connection) {
        self.connection = connection
    }

    /// Export an object at a specific path
    public func export<T: Exportable>(_ object: T, at path: ObjectPath) async throws {
        guard let connection = connection else {
            throw ExportableError.objectNotExported(path)
        }

        let exportableObject = ExportableObject(object: object)
        await exportableObject.setExportContext(connection: connection, path: path)

        exportedObjects[path] = exportableObject
    }

    /// Unexport an object from a specific path
    public func unexport(at path: ObjectPath) async {
        if let exportableObject = exportedObjects.removeValue(forKey: path) {
            await exportableObject.removeExportContext()
        }
    }

    /// Handle incoming method calls
    public func handleMethodCall(_ message: Message) async throws -> Message? {
        guard let path = message.path,
            let exportableObject = exportedObjects[path]
        else {
            return nil
        }

        // Handle the method call
        let result = try await exportableObject.handleMethodCall(message: message)

        return result
    }

    /// Get the exported object at a specific path
    public func object(at path: ObjectPath) -> (any ExportableObjectProtocol)? {
        return exportedObjects[path]
    }
}
