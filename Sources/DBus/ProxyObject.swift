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

/// Represents a remote D-Bus object for type-safe method calls and signal handling
///
/// `ProxyObject` provides a high-level interface for interacting with remote D-Bus objects.
/// It encapsulates the service name, object path, and interface information needed to
/// communicate with a specific D-Bus object, and provides methods for calling remote
/// methods, accessing properties, and handling signals.
///
/// ## Key Features
///
/// - **Method Calls**: Call remote methods with automatic serialization/deserialization
/// - **Property Access**: Get/set properties using the org.freedesktop.DBus.Properties interface
/// - **Signal Handling**: Register handlers for D-Bus signals from the remote object
/// - **Type Safety**: Strong typing support with Swift's type system
/// - **Async/Await**: Full Swift concurrency support for all operations
///
/// ## Basic Usage
///
/// ```swift
/// // Create a proxy object
/// let proxy = connection.proxyObject(
///     serviceName: "org.freedesktop.NetworkManager",
///     objectPath: ObjectPath("/org/freedesktop/NetworkManager"),
///     interfaceName: "org.freedesktop.NetworkManager"
/// )
///
/// // Call a method
/// if let (signature, data) = try await proxy.call("GetDevices") {
///     let decoder = DBusDecoder()
///     let devices = try decoder.decode([ObjectPath].self, from: data, signature: signature)
///     print("Network devices: \(devices)")
/// }
///
/// // Get a property
/// if let (signature, data) = try await proxy.getProperty("Version") {
///     let decoder = DBusDecoder()
///     let version = try decoder.decode(String.self, from: data, signature: signature)
///     print("NetworkManager version: \(version)")
/// }
///
/// // Listen for signals
/// let subscription = try await proxy.onSignal("DeviceAdded") { message in
///     print("Device added: \(message)")
/// }
/// ```
///
/// ## D-Bus Object Model
///
/// D-Bus objects are identified by three components:
/// - **Service Name**: The bus name of the service (e.g., "org.freedesktop.NetworkManager")
/// - **Object Path**: The path identifying the specific object (e.g., "/org/freedesktop/NetworkManager")
/// - **Interface**: The interface containing the methods/properties (e.g., "org.freedesktop.NetworkManager")
///
/// ## Thread Safety
///
/// ProxyObject is implemented as a Swift actor, making it inherently thread-safe.
/// All method calls are async and properly synchronized with the underlying connection.
///
/// ## Signal Handling
///
/// ProxyObject supports D-Bus signal handling with automatic subscription management:
/// - `onSignal(_:handler:)` - Register a persistent signal handler
/// - `waitForSignal(_:timeout:)` - Wait for a single signal occurrence
/// - Automatic cleanup when proxy objects are deallocated
///
/// ## Error Handling
///
/// Methods can throw `DBusProxyError` for various failure conditions:
/// - `noReply` - Method call didn't receive a reply
/// - `dBusError` - Remote method returned a D-Bus error
/// - `invalidReply` - Received malformed reply message
/// - `encodingFailed` - Failed to encode method arguments
/// - `signalTimeout` - Signal wait operation timed out
///
/// ## Internal Implementation Notes
///
/// - Uses the underlying Connection for all network communication
/// - Maintains signal handlers in a dictionary keyed by signal name
/// - Handles message correlation and reply matching automatically
/// - Supports both raw byte arrays and typed method calls
public actor ProxyObject {

    // MARK: - Properties

    /// The D-Bus connection used for communication
    ///
    /// This connection is used for all method calls, property access, and signal
    /// registration. The connection must remain valid for the lifetime of the proxy object.
    let connection: Connection

    /// The service name (bus name) of the remote object
    ///
    /// This is the well-known name or unique name of the D-Bus service that owns
    /// the remote object. Examples: "org.freedesktop.NetworkManager", ":1.42"
    public let serviceName: String

    /// The object path of the remote object
    ///
    /// This uniquely identifies the object instance within the remote service.
    /// Object paths follow filesystem-like naming conventions.
    /// Examples: "/org/freedesktop/NetworkManager", "/org/freedesktop/NetworkManager/Devices/0"
    public let objectPath: ObjectPath

    /// The interface name of the remote object
    ///
    /// This specifies which interface's methods and properties this proxy will access.
    /// A single object can implement multiple interfaces.
    /// Examples: "org.freedesktop.NetworkManager", "org.freedesktop.DBus.Properties"
    public let interfaceName: String

    /// Signal handlers registered for this proxy object
    ///
    /// Internal dictionary mapping signal names to their handler functions.
    /// Handlers are called asynchronously when matching signals are received.
    private var signalHandlers: [String: (Message) async -> Void] = [:]

    // MARK: - Initialization

    /// Create a new proxy object for a remote D-Bus service
    ///
    /// This initializer is typically called via `Connection.proxyObject()` rather than directly.
    /// The proxy represents a specific interface on a specific object in a specific service.
    ///
    /// - Parameters:
    ///   - connection: The D-Bus connection to use for communication
    ///   - serviceName: The service name (bus name) of the remote object
    ///   - objectPath: The object path of the remote object
    ///   - interfaceName: The interface name of the remote object
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Usually created via Connection.proxyObject()
    /// let proxy = connection.proxyObject(
    ///     serviceName: "org.freedesktop.NetworkManager",
    ///     objectPath: ObjectPath("/org/freedesktop/NetworkManager"),
    ///     interfaceName: "org.freedesktop.NetworkManager"
    /// )
    /// ```
    init(
        connection: Connection,
        serviceName: String,
        objectPath: ObjectPath,
        interfaceName: String
    ) {
        self.connection = connection
        self.serviceName = serviceName
        self.objectPath = objectPath
        self.interfaceName = interfaceName
    }

    // MARK: - Signal Listening

    /// Listen for a specific signal from this remote object
    ///
    /// Registers a persistent handler for the specified signal. The handler will be called
    /// asynchronously whenever the signal is received from the remote object. The handler
    /// remains active until the returned subscription is cancelled or the proxy is deallocated.
    ///
    /// - Parameters:
    ///   - signal: The signal name to listen for
    ///   - handler: Closure to call when the signal is received
    /// - Returns: A signal subscription that can be cancelled
    /// - Throws: DBusProxyError if setting up the signal listener fails
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Listen for device changes in NetworkManager
    /// let subscription = try await networkProxy.onSignal("DeviceAdded") { message in
    ///     if let devicePath = message.path {
    ///         print("New device added: \(devicePath)")
    ///     }
    /// }
    ///
    /// // Listen for property changes
    /// let propSubscription = try await proxy.onSignal("PropertiesChanged") { message in
    ///     // Handle property change notification
    ///     print("Properties changed: \(message.body)")
    /// }
    ///
    /// // Cancel when no longer needed
    /// await subscription.cancel()
    /// ```
    ///
    /// ## Signal Matching
    ///
    /// The library automatically sets up D-Bus match rules to receive only signals from:
    /// - The specific object path of this proxy
    /// - The specific interface of this proxy
    /// - The specific signal name requested
    ///
    /// ## Memory Management
    ///
    /// The signal handler is stored strongly by the proxy object. To avoid memory leaks,
    /// ensure you either:
    /// - Cancel the subscription when no longer needed
    /// - Use weak references in the handler if capturing self
    public func onSignal(
        _ signal: String,
        handler: @escaping (Message) async -> Void
    ) async throws -> SignalSubscription {
        // Create match rule for this specific signal
        let matchRule =
            "type='signal',path='\(objectPath.rawValue)',interface='\(interfaceName)',member='\(signal)'"

        // Register the match rule with the bus
        try await connection.addMatch(rule: matchRule)

        // Store the handler
        let handlerKey = "\(interfaceName).\(signal)"
        signalHandlers[handlerKey] = handler

        // Register this proxy object as a signal handler with the connection
        await connection.registerSignalHandler(
            for: objectPath, interface: interfaceName, handler: handleSignal)

        // Return a subscription that can be used to cancel the listener
        return SignalSubscription(
            connection: connection,
            proxyObject: self,
            matchRule: matchRule,
            handlerKey: handlerKey
        )
    }

    /// Wait for a single occurrence of a specific signal
    ///
    /// This is a convenience method for waiting for a signal to occur exactly once.
    /// It sets up a temporary signal handler, waits for the signal, and then
    /// automatically cleans up the handler.
    ///
    /// - Parameters:
    ///   - signal: The signal name to wait for
    ///   - timeout: Optional timeout in seconds (nil for no timeout)
    /// - Returns: The received signal message
    /// - Throws: DBusProxyError if the signal setup fails or timeout occurs
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Wait for a specific event
    /// do {
    ///     let message = try await proxy.waitForSignal("ScanComplete", timeout: 30)
    ///     print("Scan completed: \(message)")
    /// } catch DBusProxyError.signalTimeout {
    ///     print("Scan did not complete within 30 seconds")
    /// }
    ///
    /// // Wait indefinitely
    /// let statusMessage = try await proxy.waitForSignal("StatusChanged")
    /// print("Status changed: \(statusMessage)")
    /// ```
    ///
    /// ## Timeout Behavior
    ///
    /// - If timeout is nil, waits indefinitely
    /// - If timeout is specified, throws `DBusProxyError.signalTimeout` after the specified interval
    /// - Timeout is specified in seconds as a Double
    ///
    /// ## Automatic Cleanup
    ///
    /// The temporary signal handler is automatically removed whether the signal
    /// is received or the operation times out, preventing resource leaks.
    public func waitForSignal(_ signal: String, timeout: Double? = nil) async throws -> Message {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                var subscription: SignalSubscription?

                do {
                    // Set up a one-time signal handler
                    subscription = try await onSignal(signal) { message in
                        // Cancel the subscription and resume the continuation
                        await subscription?.cancel()
                        continuation.resume(returning: message)
                    }

                    // Handle timeout if specified
                    if let timeoutInterval = timeout {
                        try await Task.sleep(for: .seconds(timeoutInterval))
                        await subscription?.cancel()
                        continuation.resume(throwing: DBusProxyError.signalTimeout)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Internal method called by the connection when a signal is received
    ///
    /// This method is called by the Connection actor when it receives a signal
    /// that matches the object path and interface of this proxy. It routes the
    /// signal to the appropriate registered handler based on the signal name.
    ///
    /// This is an internal method used by the Connection's signal routing system
    /// and should not be called directly by user code.
    ///
    /// - Parameter message: The received signal message to process
    ///
    /// ## Internal Implementation Notes
    ///
    /// - Validates that the message is actually a signal
    /// - Extracts interface and member (signal name) from the message
    /// - Looks up the appropriate handler using a composite key
    /// - Calls the handler asynchronously if found
    func handleSignal(_ message: Message) async {
        guard message.messageType == .signal,
            let messageInterface = message.interface,
            let messageSignal = message.member
        else {
            return
        }

        let handlerKey = "\(messageInterface).\(messageSignal)"
        if let handler = signalHandlers[handlerKey] {
            await handler(message)
        }
    }

    /// Remove a signal handler for internal cleanup
    ///
    /// Internal method used by SignalSubscription to clean up handlers when
    /// subscriptions are cancelled. This prevents memory leaks and ensures
    /// that cancelled handlers don't continue to receive signals.
    ///
    /// - Parameter key: The handler key to remove (format: "interface.signal")
    func removeSignalHandler(for key: String) {
        signalHandlers.removeValue(forKey: key)
    }

    // MARK: - Method Calling

    /// Call a method on the remote object with raw data
    ///
    /// This is the primary method calling interface that operates with raw byte arrays
    /// and signatures. It provides maximum flexibility and is used internally by
    /// higher-level typed method calling APIs.
    ///
    /// The method creates a D-Bus method call message, sends it via the connection,
    /// waits for a reply, and handles both successful returns and error responses.
    ///
    /// - Parameters:
    ///   - method: Name of the method to call
    ///   - interface: Interface name of the method (defaults to the proxy's interface)
    ///   - signature: Type signature of the method arguments, or nil for no arguments
    ///   - body: Serialized method arguments as raw bytes, or empty for no arguments
    /// - Returns: Tuple of (signature, data) for the method return, or nil if no return value
    /// - Throws: DBusProxyError for various failure conditions
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Call a method with no arguments
    /// if let (sig, data) = try await proxy.call("GetVersion") {
    ///     let decoder = DBusDecoder()
    ///     let version = try decoder.decode(String.self, from: data, signature: sig)
    ///     print("Version: \(version)")
    /// }
    ///
    /// // Call a method with arguments
    /// let encoder = DBusEncoder()
    /// let args = try encoder.encode("eth0", signature: Signature("s"))
    ///
    /// if let (sig, data) = try await proxy.call(
    ///     "GetDevice",
    ///     signature: Signature("s"),
    ///     body: args
    /// ) {
    ///     let devicePath = try DBusDecoder().decode(ObjectPath.self, from: data, signature: sig)
    ///     print("Device path: \(devicePath)")
    /// }
    ///
    /// // Call a method on a different interface
    /// if let (sig, data) = try await proxy.call(
    ///     "Introspect",
    ///     interface: "org.freedesktop.DBus.Introspectable"
    /// ) {
    ///     let xml = try DBusDecoder().decode(String.self, from: data, signature: sig)
    ///     print("Introspection XML: \(xml)")
    /// }
    /// ```
    ///
    /// ## Return Value Handling
    ///
    /// - Returns `nil` if the method has no return value (void method)
    /// - Returns `(signature, data)` tuple for methods with return values
    /// - The signature describes the type structure of the returned data
    /// - Use DBusDecoder to deserialize the data according to the signature
    ///
    /// ## Error Conditions
    ///
    /// - `DBusProxyError.dBusError`: Remote method returned a D-Bus error
    /// - `DBusProxyError.invalidReply`: Received unexpected reply type
    /// - `DBusProxyError.noReply`: Method call timed out or connection failed
    /// - `ConnectionError`: Various connection-level failures
    ///
    /// ## Interface Override
    ///
    /// The `interface` parameter allows calling methods on different interfaces
    /// than the proxy's default interface. This is useful for:
    /// - Calling standard D-Bus interfaces (Properties, Introspectable, Peer)
    /// - Objects that implement multiple interfaces
    /// - Accessing methods from parent interfaces
    public func call(
        _ method: String, interface: String? = nil, signature: Signature?, body: [UInt8]
    ) async throws -> (
        Signature, [UInt8]
    )? {
        let message = try await connection.createMethodCall(
            path: objectPath,
            interface: interface ?? interfaceName,
            member: method,
            destination: serviceName,
            body: body,
            bodySignature: signature
        )

        // Send message using the connection and wait for a reply.
        guard let reply = try await connection.send(message: message) else {
            return nil
        }

        // Handle error replies
        if reply.messageType == .error {
            let error = DBusError(from: reply)
            throw DBusProxyError.dBusError(error)
        }

        // Handle method return
        guard reply.messageType == .methodReturn else {
            throw DBusProxyError.invalidReply
        }

        guard let replySignature = reply.bodySignature else {
            return nil
        }

        return (replySignature, reply.body)
    }

    /// Call a method on the remote object.
    /// - Parameters:
    ///   - method: Name of the method to call
    ///   - interface: Interface name of the method being called. Defaults to
    ///     the object's interface.
    ///   - signature: Signature of the arguments, or nil if the method has no
    ///     arguments.
    ///   - body: Body of the message, or nil if the method has no arguments.
    /// - Returns: The raw data of the method return and a type signature, or
    ///   nil if the method has no return value.
    @available(*, deprecated, message: "Use call(method:signature:body:) instead.")
    public func callMethod<T: Sendable & Decodable>(
        _ method: String,
        interface: String,
        signature: Signature? = nil,
        arguments: [(any Sendable & Encodable)]? = nil
    ) async throws -> T? {
        // Encode arguments if provided
        var body: [UInt8] = []
        var bodySignature: Signature?

        if let signature = signature, let arguments = arguments {
            var serializer = Serializer(signature: signature, alignmentContext: .message)
            for argument in arguments {
                try encodeArgument(argument, to: &serializer)
            }
            body = serializer.data ?? []
            bodySignature = signature
        }

        // Create method call message.
        let message = try await connection.createMethodCall(
            path: objectPath,
            interface: interface,
            member: method,
            destination: serviceName,
            body: body,
            bodySignature: bodySignature
        )

        // Send message using the connection and wait for a reply.
        guard let reply = try await connection.send(message: message) else {
            return nil
        }

        // Handle error replies
        if reply.messageType == .error {
            let error = DBusError(from: reply)
            throw DBusProxyError.dBusError(error)
        }

        // Handle method return
        guard reply.messageType == .methodReturn else {
            throw DBusProxyError.invalidReply
        }

        // Decode return value into the specified type
        guard !reply.body.isEmpty else {
            return nil
        }

        guard let replySignature = reply.bodySignature else {
            throw DBusProxyError.missingSignature
        }

        // Decode the return message body into a typed value.
        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: reply.endianness)
        let result = try decoder.decode(T.self, from: reply.body, signature: replySignature)
        return result
    }

    // MARK: - Property Access

    /// Get a property value from the remote object
    ///
    /// Retrieves a property value using the standard org.freedesktop.DBus.Properties.Get
    /// method. D-Bus properties are always returned as variants, so the signature will
    /// always be 'v' (variant). You'll need to extract the actual value from within
    /// the variant structure.
    ///
    /// - Parameters:
    ///   - propertyName: The name of the property to retrieve
    /// - Returns: Tuple of (signature, data) where signature is always 'v', or nil if property not found
    /// - Throws: DBusProxyError if the property access fails
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Get a simple property
    /// if let (sig, data) = try await proxy.getProperty("Version") {
    ///     // Signature will be 'v' (variant)
    ///     let decoder = DBusDecoder()
    ///     let variant = try decoder.decode(Variant.self, from: data, signature: sig)
    ///
    ///     if case .string(let version) = variant.value {
    ///         print("Version: \(version)")
    ///     }
    /// }
    ///
    /// // Get a complex property
    /// if let (sig, data) = try await proxy.getProperty("Devices") {
    ///     let decoder = DBusDecoder()
    ///     let variant = try decoder.decode(Variant.self, from: data, signature: sig)
    ///
    ///     if case .array(let deviceValues) = variant.value {
    ///         let devices = deviceValues.compactMap { value in
    ///             if case .objectPath(let path) = value {
    ///                 return path
    ///             }
    ///             return nil
    ///         }
    ///         print("Devices: \(devices)")
    ///     }
    /// }
    /// ```
    ///
    /// ## D-Bus Properties Protocol
    ///
    /// This method calls `org.freedesktop.DBus.Properties.Get(interface, property)`
    /// which is the standard way to access properties in D-Bus. The property name
    /// must match exactly what's defined in the object's interface.
    ///
    /// ## Variant Handling
    ///
    /// Since D-Bus properties are always wrapped in variants for type safety:
    /// 1. The returned signature is always 'v' (variant)
    /// 2. Decode the data as a Variant type
    /// 3. Extract the actual value from the variant's value field
    /// 4. Use pattern matching to handle different variant value types
    ///
    /// ## Error Conditions
    ///
    /// - Property doesn't exist on the interface
    /// - Permission denied to read the property
    /// - Object doesn't implement org.freedesktop.DBus.Properties
    /// - Network or serialization failures
    public func getProperty(_ propertyName: String) async throws -> (Signature, [UInt8])? {
        // Serialize the method arguments.
        var serializer = Serializer(
            signature: Signature(elements: [.string, .string]),
            alignmentContext: .message,
            endianness: .littleEndian)
        try serializer.serialize(interfaceName)
        try serializer.serialize(propertyName)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        // Call the method.
        let result: (Signature, [UInt8])? = try await call(
            "Get",
            interface: "org.freedesktop.DBus.Properties",
            signature: serializer.signature,
            body: body
        )

        // Ensure the signature is always a variant.
        assert(result?.0 == Signature(elements: [.variant]))

        return result
    }

    /// Get a property from the remote object by calling the
    /// org.freedesktop.DBus.Properties.Get method.
    /// - Parameters:
    ///   - property: The property name
    /// - Returns: The deserialized property value, or nil if the property is not
    ///   found.
    @available(*, deprecated, message: "Use getProperty(_:) instead.")
    public func getProperty<T: Sendable & Decodable>(_ property: String) async throws -> T? {
        return try await callMethod(
            "Get",
            interface: "org.freedesktop.DBus.Properties",
            signature: Signature(elements: [.string, .string]),
            arguments: [interfaceName, property]
        ) as T?
    }

    /// Set a property value on the remote object
    ///
    /// Sets a property value using the standard org.freedesktop.DBus.Properties.Set
    /// method. The value must be provided as a Variant containing both the value
    /// and its type signature information.
    ///
    /// - Parameters:
    ///   - propertyName: The name of the property to set
    ///   - value: The new property value wrapped in a Variant
    /// - Throws: DBusProxyError if the property setting fails
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Set a string property
    /// let stringValue = Variant(
    ///     value: .string("New Value"),
    ///     signature: Signature("s")
    /// )
    /// try await proxy.setProperty("DisplayName", value: stringValue)
    ///
    /// // Set an integer property
    /// let intValue = Variant(
    ///     value: .int32(42),
    ///     signature: Signature("i")
    /// )
    /// try await proxy.setProperty("Volume", value: intValue)
    ///
    /// // Set a boolean property
    /// let boolValue = Variant(
    ///     value: .bool(true),
    ///     signature: Signature("b")
    /// )
    /// try await proxy.setProperty("Enabled", value: boolValue)
    /// ```
    ///
    /// ## Variant Creation Helper
    ///
    /// For convenience, you can create variants from Swift values:
    ///
    /// ```swift
    /// // Using the Variant initializer with Swift values
    /// try await proxy.setProperty("Name", value: try Variant("John", signature: Signature("s")))
    /// try await proxy.setProperty("Age", value: try Variant(Int32(25), signature: Signature("i")))
    /// ```
    ///
    /// ## D-Bus Properties Protocol
    ///
    /// This method calls `org.freedesktop.DBus.Properties.Set(interface, property, value)`
    /// which is the standard way to modify properties in D-Bus.
    ///
    /// ## Permission Requirements
    ///
    /// - The property must be writable (not read-only)
    /// - You must have appropriate permissions to modify the property
    /// - The object must implement org.freedesktop.DBus.Properties interface
    ///
    /// ## Error Conditions
    ///
    /// - Property doesn't exist or is read-only
    /// - Permission denied to write the property
    /// - Type mismatch between provided value and expected property type
    /// - Object doesn't implement org.freedesktop.DBus.Properties
    public func setProperty(_ propertyName: String, value: Variant) async throws {
        var serializer = Serializer(
            signature: Signature(elements: [.string, .string, .variant]),
            alignmentContext: .message,
            endianness: .littleEndian
        )
        try serializer.serialize(interfaceName)
        try serializer.serialize(propertyName)
        try serializer.serialize(value)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        // Call the method, discarding the return value as Set doesn't return
        // anything.
        let _ = try await call(
            "Set",
            interface: "org.freedesktop.DBus.Properties",
            signature: serializer.signature,
            body: body
        )
    }

    /// Set a property on the remote object
    /// - Parameters:
    ///   - property: The property name
    ///   - value: The new property value
    /// - Throws: DBusProxyError if the property setting fails
    @available(*, deprecated, message: "Use setProperty(_:value:) instead.")
    public func setProperty<T: Sendable & Encodable>(
        _ property: String, value: T
    ) async throws {
        // Create a DBusVariant with the appropriate signature
        let variantValue = try VariantValue(value)
        let valueSignature = try getSignatureForValue(value)
        let variant = Variant(value: variantValue, signature: valueSignature)

        // The Set method typically doesn't return a value, but we need to specify a type
        // for the generic callMethod. We'll ignore the return value.
        let _: String? = try await callMethod(
            "Set",
            interface: "org.freedesktop.DBus.Properties",
            signature: Signature(elements: [.string, .string, .variant]),
            arguments: [interfaceName, property, variant]
        )
    }

    /// Get all properties from the remote object
    ///
    /// Retrieves all properties for the interface using the standard
    /// org.freedesktop.DBus.Properties.GetAll method. This returns a dictionary
    /// mapping property names to their variant values.
    ///
    /// - Returns: Tuple of (signature, data) containing a dictionary of all properties, or nil if none found
    /// - Throws: DBusProxyError if the property access fails
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// if let (sig, data) = try await proxy.getAllProperties() {
    ///     let decoder = DBusDecoder()
    ///
    ///     // The signature will be "a{sv}" - array of string-to-variant dictionary entries
    ///     let properties = try decoder.decode([String: Variant].self, from: data, signature: sig)
    ///
    ///     for (name, variant) in properties {
    ///         print("Property \(name):")
    ///
    ///         switch variant.value {
    ///         case .string(let str):
    ///             print("  String: \(str)")
    ///         case .int32(let int):
    ///             print("  Integer: \(int)")
    ///         case .bool(let bool):
    ///             print("  Boolean: \(bool)")
    ///         case .array(let array):
    ///             print("  Array with \(array.count) items")
    ///         default:
    ///             print("  Other type: \(variant.signature)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Efficient Property Access
    ///
    /// Use this method when you need to access multiple properties at once,
    /// as it's more efficient than making individual getProperty() calls:
    ///
    /// ```swift
    /// // Efficient - single D-Bus call
    /// let allProps = try await proxy.getAllProperties()
    ///
    /// // Less efficient - multiple D-Bus calls
    /// let prop1 = try await proxy.getProperty("Property1")
    /// let prop2 = try await proxy.getProperty("Property2")
    /// let prop3 = try await proxy.getProperty("Property3")
    /// ```
    ///
    /// ## D-Bus Properties Protocol
    ///
    /// This method calls `org.freedesktop.DBus.Properties.GetAll(interface)`
    /// which returns all readable properties for the specified interface.
    ///
    /// ## Return Format
    ///
    /// The returned data represents a dictionary with signature "a{sv}":
    /// - `a` = array
    /// - `{sv}` = dictionary entry mapping string key to variant value
    /// - Keys are property names (strings)
    /// - Values are property values (variants containing actual typed data)
    public func getAllProperties() async throws -> (Signature, [UInt8])? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]),
            alignmentContext: .message,
            endianness: .littleEndian)
        try serializer.serialize(interfaceName)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        // Call the method.
        return try await call(
            "GetAll",
            interface: "org.freedesktop.DBus.Properties",
            signature: serializer.signature,
            body: body
        )
    }

    /// Get all properties from the remote object
    /// - Parameter propertyInterface: Optional interface name (defaults to the object's interface)
    /// - Returns: A dictionary mapping property names to their values
    /// - Throws: DBusProxyError if the property access fails
    @available(*, deprecated, message: "Use getAllProperties() instead.")
    public func getAllProperties() async throws -> [String: Variant]? {
        return try await callMethod(
            "GetAll",
            interface: "org.freedesktop.DBus.Properties",
            signature: Signature(elements: [.string]),
            arguments: [interfaceName]
        ) as [String: Variant]?
    }

    // MARK: - Introspection

    /// Get introspection data for the remote object
    /// - Returns: XML introspection data
    /// - Throws: DBusProxyError if introspection fails
    public func introspect() async throws -> (Signature, [UInt8])? {
        return try await call(
            "Introspect",
            interface: "org.freedesktop.DBus.Introspectable",
            signature: nil,
            body: []
        )
    }

    // MARK: - Private Helper Methods

    /// Get the signature element for a specific argument
    /// - Parameter argument: The argument to analyze
    /// - Returns: The signature element string
    /// - Throws: DBusProxyError if the type is not supported
    @available(*, deprecated, message: "Use DBusVariantValue.signature instead.")
    private func signatureElement(for argument: any Sendable & Encodable) throws -> String {
        switch argument {
        case is Bool:
            return "b"
        case is UInt8:
            return "y"
        case is Int16:
            return "n"
        case is UInt16:
            return "q"
        case is Int32:
            return "i"
        case is UInt32:
            return "u"
        case is Int64:
            return "x"
        case is UInt64:
            return "t"
        case is Double:
            return "d"
        case is String:
            return "s"
        case is ObjectPath:
            return "o"
        case is Signature:
            return "g"
        case is Variant:
            return "v"
        default:
            throw DBusProxyError.unsupportedType
        }
    }

    /// Encode a single argument to the serializer
    /// - Parameters:
    ///   - argument: The argument to encode
    ///   - serializer: The serializer to encode to
    /// - Throws: DBusProxyError if encoding fails
    @available(*, deprecated, message: "Use DBusVariantValue.signature instead.")
    private func encodeArgument(
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
            throw DBusProxyError.unsupportedType
        }
    }

    /// Get the signature for a value to be used in a DBusVariant
    /// - Parameter value: The value to get the signature for
    /// - Returns: The signature for the value
    /// - Throws: DBusProxyError if the type is not supported
    @available(*, deprecated, message: "Use DBusVariantValue.signature instead.")
    private func getSignatureForValue(_ value: any Sendable & Encodable) throws -> Signature {
        let signatureString = try signatureElement(for: value)
        guard let signature = Signature(rawValue: signatureString) else {
            throw DBusProxyError.signatureInferenceFailure
        }
        return signature
    }
}

// MARK: - Error Types

/// Comprehensive D-Bus error information extracted from error messages
///
/// This struct provides detailed information about D-Bus errors, including the error name,
/// message, and additional context. It automatically attempts to decode common error patterns
/// from the D-Bus message body.
///
/// ## Usage Examples
///
/// ```swift
/// do {
///     let result = try await proxy.call("SomeMethod", signature: nil, body: [])
/// } catch DBusProxyError.dBusError(let dbusError) {
///     // Access basic error information
///     print("Error: \(dbusError.errorName)")
///     print("Message: \(dbusError.errorMessage ?? "No message")")
///
///     // Use convenience properties
///     print("Short name: \(dbusError.shortErrorName)")
///     print("Is standard error: \(dbusError.isStandardDBusError)")
///
///     // Get detailed information
///     print("Full details:\n\(dbusError.detailedDescription)")
///
///     // Check for specific errors
///     if dbusError.matches("ServiceUnknown") {
///         print("Service is not available")
///     }
///
///     // Decode custom error body
///     if let errorCode: Int32 = dbusError.decodeBody(Int32.self) {
///         print("Error code: \(errorCode)")
///     }
/// }
/// ```
///
/// ## Common D-Bus Error Names
///
/// - `org.freedesktop.DBus.Error.ServiceUnknown` - Service not available
/// - `org.freedesktop.DBus.Error.NoReply` - Method call timed out
/// - `org.freedesktop.DBus.Error.AccessDenied` - Permission denied
/// - `org.freedesktop.DBus.Error.InvalidArgs` - Invalid method arguments
/// - `org.freedesktop.DBus.Error.UnknownMethod` - Method not found
/// - `org.freedesktop.DBus.Error.UnknownObject` - Object not found
/// - `org.freedesktop.DBus.Error.UnknownInterface` - Interface not found
public struct DBusError: Error, Sendable {
    /// The D-Bus error name (e.g., "org.freedesktop.DBus.Error.ServiceUnknown")
    public let errorName: String

    /// The error message/description from the message body (if any)
    public let errorMessage: String?

    /// The raw error body data
    public let errorBody: [UInt8]

    /// The signature of the error body (if any)
    public let errorBodySignature: Signature?

    /// The sender of the error message
    public let sender: String?

    /// The serial number of the original message that caused this error
    public let replySerial: UInt32?

    /// The endianness of the error message
    public let endianness: Endianness

    /// Additional error details decoded from the body (if possible)
    public let additionalDetails: [String]

    // MARK: - Convenience Properties

    /// Returns a user-friendly description of the error
    public var localizedDescription: String {
        if let message = errorMessage {
            return "\(errorName): \(message)"
        } else {
            return errorName
        }
    }

    /// Returns the short error name without the full D-Bus prefix
    public var shortErrorName: String {
        // Convert "org.freedesktop.DBus.Error.ServiceUnknown" to "ServiceUnknown"
        if let lastComponent = errorName.split(separator: ".").last {
            return String(lastComponent)
        }
        return errorName
    }

    /// Returns true if this is a well-known D-Bus error
    public var isStandardDBusError: Bool {
        return errorName.hasPrefix("org.freedesktop.DBus.Error.")
    }

    /// Returns all available error information as a formatted string
    public var detailedDescription: String {
        var parts: [String] = []

        parts.append("Error Name: \(errorName)")

        if let message = errorMessage {
            parts.append("Message: \(message)")
        }

        if !additionalDetails.isEmpty {
            parts.append("Additional Details: \(additionalDetails.joined(separator: ", "))")
        }

        if let sender = sender {
            parts.append("Sender: \(sender)")
        }

        if let replySerial = replySerial {
            parts.append("Reply Serial: \(replySerial)")
        }

        if let signature = errorBodySignature {
            parts.append("Body Signature: \(signature.rawValue)")
        }

        if !errorBody.isEmpty {
            parts.append("Body Size: \(errorBody.count) bytes")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Convenience Methods

    /// Attempts to decode the error body as a specific type
    /// - Parameter type: The type to decode as
    /// - Returns: The decoded value or nil if decoding fails
    public func decodeBody<T: Decodable>(_ type: T.Type) -> T? {
        guard !errorBody.isEmpty, let signature = errorBodySignature else {
            return nil
        }

        do {
            let decoder = DBusDecoder()
            decoder.options = DBusDecoder.Options(endianness: endianness)
            return try decoder.decode(type, from: errorBody, signature: signature)
        } catch {
            return nil
        }
    }

    /// Checks if this error matches a specific D-Bus error name
    /// - Parameter name: The error name to check (can be full or short name)
    /// - Returns: True if the error matches
    public func matches(_ name: String) -> Bool {
        return errorName == name || shortErrorName == name
    }

    internal init(from message: Message) {
        self.errorName = message.errorName ?? "Unknown error"
        self.errorBody = message.body
        self.errorBodySignature = message.bodySignature
        self.sender = message.sender
        self.replySerial = message.replySerial
        self.endianness = message.endianness

        // Try to extract error message from body
        var extractedMessage: String?
        var extractedDetails: [String] = []

        if !message.body.isEmpty, let signature = message.bodySignature {
            do {
                let decoder = DBusDecoder()
                decoder.options = DBusDecoder.Options(endianness: message.endianness)

                // Common D-Bus error patterns:
                // - Single string message: "s"
                // - Multiple string details: "as" or multiple "s" arguments
                if signature.rawValue == "s" {
                    extractedMessage = try decoder.decode(
                        String.self, from: message.body, signature: signature)
                } else if signature.rawValue == "as" {
                    let messages = try decoder.decode(
                        [String].self, from: message.body, signature: signature)
                    if let first = messages.first {
                        extractedMessage = first
                        extractedDetails = Array(messages.dropFirst())
                    }
                } else {
                    // Try to decode as string anyway for other signatures
                    // This handles cases where the signature might be more complex
                    // but still contains a string message
                    var deserializer = Deserializer(
                        data: message.body,
                        signature: signature,
                        endianness: message.endianness
                    )
                    if let firstValue = try? deserializer.unserialize() as String {
                        extractedMessage = firstValue
                    }
                }
            } catch {
                // If decoding fails, we'll leave the message as nil
                // The raw body is still available for custom parsing
            }
        }

        self.errorMessage = extractedMessage
        self.additionalDetails = extractedDetails
    }
}

/// Errors that can occur when working with proxy objects
public enum DBusProxyError: Error, Sendable {
    case noReply
    case dBusError(DBusError)
    case invalidReply
    case noReturnValue
    case missingSignature
    case propertyTypeError
    case signatureInferenceFailure
    case unsupportedType
    case encodingFailed
    case signalTimeout

    // Legacy case for backwards compatibility
    @available(*, deprecated, message: "Use dBusError(DBusError) instead")
    case methodCallFailed(String)
}

/// Represents a subscription to a D-Bus signal that can be cancelled
public actor SignalSubscription {
    private let connection: Connection
    private weak var proxyObject: ProxyObject?
    private let matchRule: String
    private let handlerKey: String
    private var isActive: Bool = true

    init(connection: Connection, proxyObject: ProxyObject, matchRule: String, handlerKey: String) {
        self.connection = connection
        self.proxyObject = proxyObject
        self.matchRule = matchRule
        self.handlerKey = handlerKey
    }

    /// Cancel the signal subscription
    public func cancel() async {
        guard isActive else { return }
        isActive = false

        // Remove the match rule from the bus
        try? await connection.removeMatch(rule: matchRule)

        // Remove the handler from the proxy object
        await proxyObject?.removeSignalHandler(for: handlerKey)
    }

    deinit {
        if isActive {
            Task { [weak self] in
                await self?.cancel()
            }
        }
    }
}

// MARK: - Convenience Extensions

extension Connection {
    /// Create a proxy object for a remote D-Bus service
    /// - Parameters:
    ///   - serviceName: The service name (bus name) of the remote object
    ///   - objectPath: The object path of the remote object
    ///   - interfaceName: The interface name of the remote object
    /// - Returns: A new proxy object
    public nonisolated func proxyObject(
        serviceName: String,
        objectPath: ObjectPath,
        interfaceName: String
    ) -> ProxyObject {
        return ProxyObject(
            connection: self,
            serviceName: serviceName,
            objectPath: objectPath,
            interfaceName: interfaceName
        )
    }

    // MARK: - org.freedesktop.DBus interface

    /// Call the Hello method on the org.freedesktop.DBus interface.
    /// - Returns: The bus ID of the connection, or nil if the method call fails.
    func hello() async throws -> String? {
        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "Hello", interface: "org.freedesktop.DBus", signature: nil as Signature?, body: [])
        else {
            throw DBusProxyError.noReply
        }

        // Assume little endianness for now. TODO: Can we use the same
        // endianness as the original message?
        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        let result = try deserializer.unserialize() as String?
        return result
    }

    /// Call the RequestName method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to request
    ///   - flags: The flags to use for the request
    /// - Returns: The reply flags, or nil if the method call fails.
    public func requestName(name: String, flags: DBusRequestNameFlags) async throws
        -> DBusRequestNameReplyFlags?
    {
        var serializer = Serializer(
            signature: Signature(elements: [.string, .uint32]), alignmentContext: .message)
        try serializer.serialize(name)
        try serializer.serialize(flags.rawValue)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }
        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "RequestName", interface: "org.freedesktop.DBus", signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        let result = try deserializer.unserialize() as UInt32
        return DBusRequestNameReplyFlags(rawValue: result)
    }

    /// Call the ReleaseName method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to release
    /// - Returns: The reply flags, or nil if the method call fails.
    public func releaseName(name: String) async throws -> DBusReleaseNameReplyFlags? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(name)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "ReleaseName", interface: "org.freedesktop.DBus", signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        let result = try deserializer.unserialize() as UInt32
        return DBusReleaseNameReplyFlags(rawValue: result)
    }

    /// Call the ListQueuedOwners method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to list the queued owners for
    /// - Returns: A list of queued owner names, or nil if the method call fails.
    public func listQueuedOwners(name: String) async throws -> [String]? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(name)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "ListQueuedOwners", interface: "org.freedesktop.DBus",
                signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as [String]
    }

    /// Call the ListNames method on the org.freedesktop.DBus interface.
    /// - Returns: A list of service names, or nil if the method call fails.
    public func listNames() async throws -> [String]? {
        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "ListNames", interface: "org.freedesktop.DBus", signature: nil as Signature?,
                body: [])
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as [String]
    }

    /// Call the ListActivatableNames method on the org.freedesktop.DBus interface.
    /// - Returns: A list of activatable service names, or nil if the method call fails.
    public func listActivatableNames() async throws -> [String]? {
        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "ListActivatableNames",
                interface: "org.freedesktop.DBus",
                signature: nil as Signature?,
                body: [])
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as [String]
    }

    /// Call the NameHasOwner method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to check
    /// - Returns: True if the name has an owner, false otherwise, or nil if the method call fails.
    public func nameHasOwner(name: String) async throws -> Bool? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(name)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "NameHasOwner", interface: "org.freedesktop.DBus", signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as Bool
    }

    // TODO: Add support for nameOwnerChanged signal.
    // TODO: Add support for nameLost signal.
    // TODO: Add support for nameAcquired signal.
    // TODO: Add support for activatableServicesChanged signal.

    /// Call the StartServiceByName method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name of the service to start
    /// - Returns: The reply flags, or nil if the method call fails.
    public func startServiceByName(name: String) async throws -> DBusStartServiceByNameReplyFlags? {
        // This method takes two arguments, but flags is unused, so
        // implementations assume it's 0.
        var serializer = Serializer(
            signature: Signature(elements: [.string, .uint32]), alignmentContext: .message)
        try serializer.serialize(name)
        try serializer.serialize(UInt32(0))

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }
        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "StartServiceByName", interface: "org.freedesktop.DBus",
                signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        let result = try deserializer.unserialize() as UInt32
        return DBusStartServiceByNameReplyFlags(rawValue: result)
    }

    /// Call the UpdateActivationEnvironment method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - environment: The environment to update
    /// - Throws: DBusProxyError if the method call fails.
    public func updateActivationEnvironment(environment: [String: String]) async throws {
        var serializer = Serializer(
            signature: Signature(elements: [.dictionary(.string, .string)]),
            alignmentContext: .message)
        try serializer.serialize(environment)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        // This method doesn't return anything, so we can just call it and
        // discard the result.
        let _ = try await proxyObject(
            serviceName: "org.freedesktop.DBus",
            objectPath: ObjectPath("/org/freedesktop/DBus"),
            interfaceName: "org.freedesktop.DBus"
        ).call(
            "UpdateActivationEnvironment", interface: "org.freedesktop.DBus",
            signature: serializer.signature,
            body: body)
    }

    /// Call the GetNameOwner method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to get the owner for
    /// - Returns: The owner of the name, or nil if the method call fails.
    public func getNameOwner(name: String) async throws -> String? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(name)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }
        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "GetNameOwner", interface: "org.freedesktop.DBus", signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as String?
    }

    /// Call the GetConnectionUnixOwner method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to get the connection Unix owner for
    /// - Returns: The connection Unix owner, or nil if the method call fails.
    public func getConnectionUnixOwner(name: String) async throws -> UInt32? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(name)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "GetConnectionUnixOwner", interface: "org.freedesktop.DBus",
                signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as UInt32?
    }

    /// Call the GetConnectionUnixProcessID method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to get the connection Unix process ID for
    /// - Returns: The connection Unix process ID, or nil if the method call fails.
    public func getConnectionUnixProcessID(name: String) async throws -> UInt32? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(name)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "GetConnectionUnixProcessID", interface: "org.freedesktop.DBus",
                signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as UInt32?
    }

    /// Call the GetConnectionCredentials method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - name: The name to get the connection credentials for
    /// - Returns: The connection credentials, or nil if the method call fails.
    public func getConnectionCredentials(name: String) async throws -> [String: Variant]? {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(name)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "GetConnectionCredentials", interface: "org.freedesktop.DBus",
                signature: serializer.signature,
                body: body)
        else {
            throw DBusProxyError.noReply
        }

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .littleEndian)
        return try decoder.decode([String: Variant].self, from: data, signature: signature)
    }

    /// Call the AddMatch method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - rule: The match rule to add
    /// - Throws: DBusProxyError if the method call fails.
    public func addMatch(rule: String) async throws {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(rule)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        // This method doesn't return anything, so we can just call it and
        // discard the result.
        let _ = try await proxyObject(
            serviceName: "org.freedesktop.DBus",
            objectPath: ObjectPath("/org/freedesktop/DBus"),
            interfaceName: "org.freedesktop.DBus"
        ).call(
            "AddMatch", interface: "org.freedesktop.DBus",
            signature: serializer.signature,
            body: body)
    }

    /// Call the RemoveMatch method on the org.freedesktop.DBus interface.
    /// - Parameters:
    ///   - rule: The match rule to remove
    /// - Throws: DBusProxyError if the method call fails.
    public func removeMatch(rule: String) async throws {
        var serializer = Serializer(
            signature: Signature(elements: [.string]), alignmentContext: .message)
        try serializer.serialize(rule)

        guard let body = serializer.data else {
            throw DBusProxyError.encodingFailed
        }

        // This method doesn't return anything, so we can just call it and
        // discard the result.
        let _ = try await proxyObject(
            serviceName: "org.freedesktop.DBus",
            objectPath: ObjectPath("/org/freedesktop/DBus"),
            interfaceName: "org.freedesktop.DBus"
        ).call(
            "RemoveMatch", interface: "org.freedesktop.DBus",
            signature: serializer.signature,
            body: body)
    }

    /// Call the GetID method on the org.freedesktop.DBus interface.
    /// - Returns: The bus ID of the connection, or nil if the method call fails.
    public func getID() async throws -> String? {
        guard
            let (signature, data) = try await proxyObject(
                serviceName: "org.freedesktop.DBus",
                objectPath: ObjectPath("/org/freedesktop/DBus"),
                interfaceName: "org.freedesktop.DBus"
            ).call(
                "GetId", interface: "org.freedesktop.DBus", signature: nil as Signature?, body: [])
        else {
            throw DBusProxyError.noReply
        }

        var deserializer = Deserializer(
            data: data, signature: signature, endianness: .littleEndian)
        return try deserializer.unserialize() as String?
    }
}

/// Flags used by the org.freedesktop.DBus.RequestName method.
public enum DBusRequestNameFlags: UInt32, Sendable, Encodable {
    case allowReplacement = 1
    case replaceExisting = 2
    case doNotQueue = 4
}

/// Flags returned by the org.freedesktop.DBus.RequestName method.
public enum DBusRequestNameReplyFlags: UInt32, Sendable, Decodable {
    case primaryOwner = 1
    case inQueue = 2
    case alreadyOwner = 3
    case nonexistent = 4
}

/// Flags returned by the org.freedesktop.DBus.ReleaseName method.
public enum DBusReleaseNameReplyFlags: UInt32, Sendable, Decodable {
    case released = 1
    case nonexistent = 2
    case notOwner = 3
}

public enum DBusStartServiceByNameReplyFlags: UInt32, Sendable, Decodable {
    case success = 1
    case alreadyRunning = 2
}
