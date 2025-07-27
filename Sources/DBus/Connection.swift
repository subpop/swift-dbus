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
import NIO
import NIOPosix

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

/// Represents the different types of buses supported by D-Bus.
///
/// D-Bus provides different buses for different purposes:
/// - System bus: For system-wide services like network management and hardware access
/// - Session bus: For user-specific services within a desktop session
/// - Custom address: For connecting to specific D-Bus daemons
///
/// ## Usage Examples
///
/// ```swift
/// // Connect to common bus types
/// try await connection.connect(to: .system)
/// try await connection.connect(to: .session)
///
/// // Connect to custom address
/// try await connection.connect(to: .address("unix:path=/tmp/my-dbus-socket"))
/// ```
public enum BusType {
    /// The system-wide D-Bus message bus
    ///
    /// Used for system services like NetworkManager, systemd, and hardware management.
    /// Typically requires appropriate permissions to access.
    case system

    /// The user session D-Bus message bus
    ///
    /// Used for user-specific services within a desktop session like application
    /// settings, desktop notifications, and user services.
    case session

    /// A custom D-Bus address
    ///
    /// Allows connecting to a specific D-Bus daemon using a custom address string.
    /// The address format follows D-Bus specification (e.g., "unix:path=/path/to/socket").
    case address(String)
}

/// Connection state for tracking the D-Bus connection lifecycle
///
/// The connection goes through several states during its lifecycle:
/// 1. `.disconnected` - Initial state, no connection established
/// 2. `.connecting` - Attempting to establish network connection
/// 3. `.authenticating` - Performing D-Bus authentication handshake
/// 4. `.connected` - Fully connected and ready for message exchange
/// 5. `.error(ConnectionError)` - Connection failed with specific error
///
/// ## Usage
///
/// ```swift
/// let connection = Connection()
///
/// // Check connection state
/// switch connection.connectionState {
/// case .disconnected:
///     print("Not connected")
/// case .connecting:
///     print("Connecting...")
/// case .authenticating:
///     print("Authenticating...")
/// case .connected:
///     print("Ready to use")
/// case .error(let error):
///     print("Connection failed: \(error)")
/// }
/// ```
public enum ConnectionState: Sendable {
    /// Connection is not established
    case disconnected
    /// Currently establishing network connection
    case connecting
    /// Performing D-Bus authentication
    case authenticating
    /// Fully connected and operational
    case connected
    /// Connection failed with error
    case error(ConnectionError)
}

/// Comprehensive error types for D-Bus connection operations
///
/// These errors provide detailed information about what went wrong during
/// connection establishment, authentication, or message operations, helping
/// developers diagnose and handle different failure scenarios.
///
/// ## Common Error Scenarios
///
/// - **Connection Setup**: `invalidAddress`, `connectionFailed`, `unsupportedTransport`
/// - **Authentication**: `authenticationFailed`, `invalidAuthResponse`
/// - **Environment**: `environmentVariableNotSet` (for session/system bus detection)
/// - **Runtime**: `connectionClosed`, `timeout`, `messageSerializationFailed`
///
/// ## Error Handling Example
///
/// ```swift
/// do {
///     try await connection.connect(to: .session)
/// } catch ConnectionError.environmentVariableNotSet(let variable) {
///     print("Please set \(variable) environment variable")
/// } catch ConnectionError.authenticationFailed(let reason) {
///     print("Authentication failed: \(reason)")
/// } catch ConnectionError.connectionFailed(let reason) {
///     print("Connection failed: \(reason)")
/// }
/// ```
public enum ConnectionError: Error, Equatable {
    /// The provided D-Bus address string is malformed
    case invalidAddress(String)
    /// Required environment variable is not set (e.g., DBUS_SESSION_BUS_ADDRESS)
    case environmentVariableNotSet(String)
    /// Failed to establish network connection to D-Bus daemon
    case connectionFailed(String)
    /// D-Bus authentication handshake failed
    case authenticationFailed(String)
    /// Low-level socket or network error
    case socketError(String)
    /// Failed to serialize outgoing D-Bus message
    case messageSerializationFailed
    /// Failed to deserialize incoming D-Bus message
    case messageDeserializationFailed
    /// Connection was closed unexpectedly
    case connectionClosed
    /// Operation timed out
    case timeout
    /// The requested transport method is not supported
    case unsupportedTransport(String)
    /// Received invalid response during authentication
    case invalidAuthResponse(String)
}

// MARK: - Channel Handler

/// Internal channel handler for processing D-Bus network traffic
///
/// This handler integrates with SwiftNIO's channel pipeline to process both
/// authentication data during connection setup and D-Bus messages during
/// normal operation. It's marked as @unchecked Sendable because it only
/// holds a reference to the actor-isolated Connection.
///
/// ## Internal Implementation Notes
///
/// - Forwards all incoming data to the Connection actor for processing
/// - Handles both authentication and normal message traffic
/// - Provides error handling integration with NIO's error system
/// - Uses weak reference patterns where appropriate to avoid retain cycles
private final class DBusChannelHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private let connection: Connection

    init(connection: Connection) {
        self.connection = connection
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)
        connection.handleIncomingData(buffer)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        connection.handleChannelError(error)
    }
}

/// Primary interface for D-Bus communication in Swift
///
/// `Connection` is the main entry point for all D-Bus operations in this library.
/// It manages the network connection, authentication, message routing, and provides
/// high-level APIs for both consuming remote services and exporting local objects.
///
/// ## Key Features
///
/// - **Async/Await Support**: All operations use Swift's modern concurrency
/// - **Connection Management**: Automatic connection handling with state tracking
/// - **Authentication**: SASL EXTERNAL and ANONYMOUS authentication support
/// - **Message Routing**: Automatic routing of method calls, replies, and signals
/// - **Object Export**: Export Swift objects as D-Bus services
/// - **Proxy Objects**: Type-safe access to remote D-Bus objects
/// - **Error Handling**: Comprehensive error reporting and recovery
///
/// ## Basic Usage
///
/// ```swift
/// // Connect to D-Bus
/// let connection = try await Connection.sessionBusConnection()
///
/// // Call a remote method
/// let proxy = connection.proxyObject(
///     serviceName: "org.freedesktop.NetworkManager",
///     objectPath: ObjectPath("/org/freedesktop/NetworkManager"),
///     interfaceName: "org.freedesktop.NetworkManager"
/// )
///
/// if let (signature, data) = try await proxy.call("GetDevices") {
///     // Process the response data
/// }
///
/// // Export a local object
/// class MyService: Exportable {
///     var interfaces: [String: Interface] = [:]
///
///     func call(interface: String, method: String, signature: Signature, arguments: [UInt8]) async throws -> (Signature, [UInt8]) {
///         // Handle method calls
///     }
///
///     // ... other Exportable methods
/// }
///
/// let service = MyService()
/// try await connection.export(service, at: ObjectPath("/com/example/MyService"))
/// ```
///
/// ## Connection Lifecycle
///
/// 1. **Creation**: Create Connection instance
/// 2. **Connection**: Establish network connection to D-Bus daemon
/// 3. **Authentication**: Perform SASL authentication handshake
/// 4. **Operation**: Send/receive messages, export objects, use proxy objects
/// 5. **Cleanup**: Disconnect and cleanup resources
///
/// ## Thread Safety
///
/// Connection is implemented as a Swift actor, making it inherently thread-safe.
/// All public methods are async and will properly synchronize access to internal state.
///
/// ## Internal Architecture Notes
///
/// - Uses SwiftNIO for high-performance networking
/// - Maintains separate buffers for authentication and message data
/// - Implements D-Bus wire protocol serialization/deserialization
/// - Provides automatic serial number management for message correlation
/// - Supports both signal handlers and exported object method routing
public actor Connection {

    // MARK: - Properties

    /// Current connection state (internal)
    ///
    /// Tracks the connection through its lifecycle from disconnected to connected.
    /// Updates are synchronized through the actor system.
    private var state: ConnectionState = .disconnected

    /// NIO channel for network communication (internal)
    ///
    /// The underlying SwiftNIO channel that handles the actual network
    /// communication with the D-Bus daemon. Nil when not connected.
    private var channel: Channel?

    /// Buffer for accumulating incoming data (internal)
    ///
    /// D-Bus messages may arrive in fragments over the network. This buffer
    /// accumulates data until complete messages can be extracted and processed.
    private var incomingBuffer = ByteBuffer()

    /// Authentication manager for D-Bus SASL authentication (internal)
    ///
    /// Handles the D-Bus authentication handshake during connection establishment.
    /// Cleared after successful authentication to free resources.
    private var authenticationManager: DBusAuthenticationManager?

    /// Manager for exported objects on this connection (internal)
    ///
    /// Handles routing of incoming method calls to exported Swift objects
    /// and manages the object registry for introspection and method dispatch.
    private var objectManager: ExportableObjectManager?

    /// Counter for outgoing message serial numbers (internal)
    ///
    /// D-Bus requires each message to have a unique serial number for correlation
    /// of method calls with their replies. This counter ensures uniqueness.
    private var messageSerial: UInt32 = 1

    /// Pending method call continuations keyed by serial number (internal)
    ///
    /// When a method call is sent that expects a reply, we store a continuation
    /// here so we can resume it when the corresponding reply arrives.
    private var pendingReplies: [UInt32: CheckedContinuation<Message, Error>] = [:]

    /// The D-Bus address string for this connection (internal)
    ///
    /// Stores the address used to connect, useful for debugging and reconnection.
    private var busAddress: String?

    /// The unique bus ID assigned by the D-Bus daemon (internal)
    ///
    /// Every connection gets a unique ID from the D-Bus daemon, received
    /// via the Hello method during connection establishment.
    private var busID: String?

    /// Signal handlers registered for specific object paths and interfaces (internal)
    ///
    /// Allows registration of handlers for D-Bus signals, enabling reactive
    /// programming patterns for D-Bus events.
    private var signalHandlers: [SignalHandlerKey: (Message) async -> Void] = [:]

    /// Internal key structure for signal handler registration
    ///
    /// Used to uniquely identify signal handlers by object path and interface,
    /// enabling efficient signal routing and handler management.
    private struct SignalHandlerKey: Hashable {
        let objectPath: ObjectPath
        let interface: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(objectPath.rawValue)
            hasher.combine(interface)
        }

        static func == (lhs: SignalHandlerKey, rhs: SignalHandlerKey) -> Bool {
            return lhs.objectPath == rhs.objectPath && lhs.interface == rhs.interface
        }
    }

    // MARK: - Initialization

    /// Creates a new D-Bus connection instance
    ///
    /// The connection starts in a disconnected state. Call `connect(to:)` or use
    /// one of the static factory methods to establish an actual connection.
    ///
    /// ```swift
    /// let connection = Connection()
    /// try await connection.connect(to: .session)
    /// ```
    public init() {}

    // MARK: - Singleton Management

    /// Shared singleton instance for convenient access to org.freedesktop.DBus methods
    ///
    /// This singleton is useful for one-off D-Bus operations or when you need
    /// a shared connection instance across your application. For most use cases,
    /// prefer using the dedicated session or system bus singletons.
    public static let shared = Connection()

    /// Private singleton for session bus access
    ///
    /// Used internally by `sessionBusConnection()` to provide a shared connection
    /// to the session bus, avoiding the overhead of multiple connections.
    private static let sessionBus = Connection()

    /// Private singleton for system bus access
    ///
    /// Used internally by `systemBusConnection()` to provide a shared connection
    /// to the system bus, avoiding the overhead of multiple connections.
    private static let systemBus = Connection()

    /// Get a singleton connection to the session bus
    ///
    /// Returns a shared Connection instance connected to the D-Bus session bus.
    /// The session bus is used for user-specific services like desktop applications,
    /// notifications, and user preferences. This method is ideal for desktop applications
    /// and user-facing services.
    ///
    /// The connection is established on first call and reused for subsequent calls,
    /// making it efficient for applications that need session bus access from multiple
    /// locations.
    ///
    /// - Parameters:
    ///   - authenticationType: The authentication mechanism to use (default: .external)
    /// - Returns: A shared Connection connected to the session bus
    /// - Throws: ConnectionError if connection fails
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Basic session bus access
    /// let connection = try await Connection.sessionBusConnection()
    ///
    /// // Access desktop notifications
    /// let notifyProxy = connection.proxyObject(
    ///     serviceName: "org.freedesktop.Notifications",
    ///     objectPath: ObjectPath("/org/freedesktop/Notifications"),
    ///     interfaceName: "org.freedesktop.Notifications"
    /// )
    ///
    /// // Request a well-known name for your service
    /// try await connection.requestName("com.example.MyApp")
    /// ```
    ///
    /// ## Environment Requirements
    ///
    /// Requires the `DBUS_SESSION_BUS_ADDRESS` environment variable to be set,
    /// which is typically handled automatically by desktop environments.
    public static func sessionBusConnection(authenticationType: DBusAuthenticationType = .external)
        async throws -> Connection
    {
        if !(await sessionBus.isConnected) {
            try await sessionBus.connect(
                to: BusType.session, authenticationType: authenticationType)
        }
        return sessionBus
    }

    /// Get a singleton connection to the system bus
    ///
    /// Returns a shared Connection instance connected to the D-Bus system bus.
    /// The system bus is used for system-wide services like network management,
    /// hardware control, and system services. Access typically requires appropriate
    /// permissions or running as root.
    ///
    /// The connection is established on first call and reused for subsequent calls,
    /// making it efficient for system services that need system bus access from
    /// multiple locations.
    ///
    /// - Parameters:
    ///   - authenticationType: The authentication mechanism to use (default: .external)
    /// - Returns: A shared Connection connected to the system bus
    /// - Throws: ConnectionError if connection fails
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Basic system bus access
    /// let connection = try await Connection.systemBusConnection()
    ///
    /// // Access NetworkManager
    /// let nmProxy = connection.proxyObject(
    ///     serviceName: "org.freedesktop.NetworkManager",
    ///     objectPath: ObjectPath("/org/freedesktop/NetworkManager"),
    ///     interfaceName: "org.freedesktop.NetworkManager"
    /// )
    ///
    /// // Get network devices
    /// if let (sig, data) = try await nmProxy.call("GetDevices") {
    ///     // Process device list
    /// }
    /// ```
    ///
    /// ## Permissions
    ///
    /// System bus access may require:
    /// - Running as root or with appropriate capabilities
    /// - Policy configuration in D-Bus system policy files
    /// - Group membership (e.g., netdev, wheel)
    public static func systemBusConnection(authenticationType: DBusAuthenticationType = .external)
        async throws -> Connection
    {
        if !(await systemBus.isConnected) {
            try await systemBus.connect(
                to: BusType.system, authenticationType: authenticationType)
        }
        return systemBus
    }

    // MARK: - Connection State

    /// Whether the connection is currently connected and ready to send messages
    ///
    /// This is a convenience property that returns true only when the connection
    /// is in the `.connected` state. Use this for quick connection checks before
    /// performing D-Bus operations.
    ///
    /// ```swift
    /// if connection.isConnected {
    ///     // Safe to send messages
    ///     let result = try await proxy.call("SomeMethod")
    /// } else {
    ///     // Need to connect first
    ///     try await connection.connect(to: .session)
    /// }
    /// ```
    ///
    /// For more detailed state information, use `connectionState` instead.
    public var isConnected: Bool {
        if case .connected = state {
            return true
        }
        return false
    }

    /// Current detailed connection state
    ///
    /// Provides complete information about the connection's current state,
    /// including error details when the connection has failed. Use this
    /// for detailed state tracking and error handling.
    ///
    /// ```swift
    /// switch connection.connectionState {
    /// case .disconnected:
    ///     print("Ready to connect")
    /// case .connecting:
    ///     print("Establishing connection...")
    /// case .authenticating:
    ///     print("Performing authentication...")
    /// case .connected:
    ///     print("Ready for operations")
    /// case .error(let error):
    ///     print("Connection failed: \(error)")
    ///     // Handle specific error types
    /// }
    /// ```
    public var connectionState: ConnectionState {
        return state
    }

    // MARK: - Connection Management

    /// Connect to a D-Bus daemon
    ///
    /// Establishes a connection to a D-Bus daemon, performing the complete connection
    /// handshake including network connection establishment and SASL authentication.
    /// This is the primary method for connecting to D-Bus buses.
    ///
    /// The connection process involves several steps:
    /// 1. Resolve the bus address (from environment variables or defaults)
    /// 2. Establish the network connection (typically Unix domain socket)
    /// 3. Perform SASL authentication handshake
    /// 4. Send the Hello message to get a unique bus ID
    /// 5. Set up message routing and object management
    ///
    /// This method is idempotent - calling it on an already connected connection
    /// will return immediately without error.
    ///
    /// - Parameters:
    ///   - busType: The type of bus to connect to (system, session, or specific address)
    ///   - authenticationType: The authentication mechanism to use (default: .external)
    /// - Throws: `ConnectionError` if the connection fails at any step
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// let connection = Connection()
    ///
    /// // Connect to session bus (most common)
    /// try await connection.connect(to: .session)
    ///
    /// // Connect to system bus (requires permissions)
    /// try await connection.connect(to: .system)
    ///
    /// // Connect to custom address
    /// try await connection.connect(to: .address("unix:path=/tmp/my-dbus"))
    ///
    /// // Use different authentication
    /// try await connection.connect(to: .session, authenticationType: .anonymous)
    /// ```
    ///
    /// ## Error Handling
    ///
    /// Common errors include:
    /// - `environmentVariableNotSet`: Session/system bus address not configured
    /// - `connectionFailed`: Network connection could not be established
    /// - `authenticationFailed`: SASL authentication rejected
    /// - `invalidAddress`: Malformed bus address string
    ///
    /// ## Authentication Types
    ///
    /// - `.external`: Uses Unix credentials (default, most secure)
    /// - `.anonymous`: No authentication (useful for testing)
    public func connect(
        to busType: BusType, authenticationType: DBusAuthenticationType = .external
    ) async throws {
        guard case .disconnected = state else {
            return  // Already connected or connecting
        }

        state = .connecting
        authenticationManager = DBusAuthenticationManager(
            authenticationType: authenticationType, dataHandler: DBusAuthDataHandler())

        do {
            let address = try resolveAddress(for: busType)
            busAddress = address

            let parsedAddress = try parseAddress(address)
            let channel = try await createChannelAndConnect(to: parsedAddress)

            self.channel = channel

            // Perform authentication
            state = .authenticating
            try await authenticationManager?.performAuthentication(on: channel)

            // Connection successful
            state = .connected
            authenticationManager = nil  // Clear the handler after authentication
            objectManager = ExportableObjectManager(connection: self)
            self.busID = try await hello()
        } catch {
            state = .error(
                error as? ConnectionError ?? .connectionFailed(error.localizedDescription))
            authenticationManager = nil  // Clean up auth handler on error
            throw error
        }
    }

    /// Connect to a specific D-Bus address
    ///
    /// A convenience method for connecting directly to a D-Bus daemon using a
    /// specific address string. This is equivalent to calling `connect(to: .address(address))`.
    ///
    /// Use this when you have a specific D-Bus address from configuration,
    /// testing scenarios, or when connecting to non-standard D-Bus daemons.
    ///
    /// - Parameters:
    ///   - address: The D-Bus address string (e.g., "unix:path=/var/run/dbus/system_bus_socket")
    ///   - authenticationType: The authentication mechanism to use (default: .external)
    /// - Throws: `ConnectionError` if the connection fails
    ///
    /// ## Address Format
    ///
    /// D-Bus addresses follow the format: `transport:key1=value1,key2=value2`
    ///
    /// Common formats:
    /// - `unix:path=/path/to/socket` - Unix domain socket
    /// - `unix:abstract=/abstract/path` - Abstract Unix socket (Linux only)
    /// - `tcp:host=hostname,port=1234` - TCP connection (rare)
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Connect to system bus directly
    /// try await connection.open(address: "unix:path=/var/run/dbus/system_bus_socket")
    ///
    /// // Connect to custom daemon
    /// try await connection.open(address: "unix:path=/tmp/my-custom-dbus")
    ///
    /// // Test with anonymous auth
    /// try await connection.open(
    ///     address: "unix:path=/tmp/test-bus",
    ///     authenticationType: .anonymous
    /// )
    /// ```
    public func open(address: String, authenticationType: DBusAuthenticationType = .external)
        async throws
    {
        try await connect(to: BusType.address(address), authenticationType: authenticationType)
    }

    /// Disconnect from the D-Bus daemon
    ///
    /// Cleanly shuts down the D-Bus connection, canceling all pending operations
    /// and releasing resources. This method is safe to call multiple times and
    /// on already disconnected connections.
    ///
    /// The disconnection process:
    /// 1. Cancels all pending method call replies with `connectionClosed` error
    /// 2. Closes the network connection
    /// 3. Cleans up internal state and resources
    /// 4. Removes all signal handlers and exported objects
    ///
    /// After calling disconnect, the connection can be reused by calling
    /// `connect(to:)` again.
    ///
    /// ```swift
    /// // Clean shutdown
    /// await connection.disconnect()
    ///
    /// // Connection can be reused
    /// try await connection.connect(to: .session)
    /// ```
    ///
    /// ## Automatic Cleanup
    ///
    /// - All pending method calls will receive `ConnectionError.connectionClosed`
    /// - Exported objects are automatically unexported
    /// - Signal handlers are cleared
    /// - Authentication state is reset
    public func disconnect() async {
        // Cancel all pending replies
        for (_, continuation) in pendingReplies {
            continuation.resume(throwing: ConnectionError.connectionClosed)
        }
        pendingReplies.removeAll()

        if let channel = channel {
            channel.close(promise: nil)
        }
        channel = nil

        state = .disconnected
        busAddress = nil
        authenticationManager = nil
        busID = nil
        objectManager = nil
        signalHandlers.removeAll()
    }

    // MARK: - Message Sending

    /// Send a D-Bus message and optionally wait for a reply
    ///
    /// This is the low-level method for sending D-Bus messages. Most users should
    /// use higher-level APIs like ProxyObject.call() or the exported object system
    /// instead of calling this directly.
    ///
    /// The method handles both fire-and-forget messages (like signals) and
    /// request-response patterns (like method calls). For method calls that
    /// expect replies, it automatically manages correlation using serial numbers.
    ///
    /// - Parameter message: The message to send
    /// - Returns: Reply message if the message expects a reply, nil otherwise
    /// - Throws: `ConnectionError` if sending fails or connection is not established
    ///
    /// ## Message Types and Return Behavior
    ///
    /// - **Method calls with replies**: Returns the method return or error message
    /// - **Method calls with `.noReplyExpected` flag**: Returns nil immediately
    /// - **Signals**: Returns nil immediately (signals never have replies)
    /// - **Method returns/errors**: Returns nil immediately (these are replies)
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Send a method call and wait for reply
    /// let methodCall = try connection.createMethodCall(
    ///     path: ObjectPath("/org/freedesktop/DBus"),
    ///     interface: "org.freedesktop.DBus",
    ///     member: "ListNames"
    /// )
    ///
    /// if let reply = try await connection.send(message: methodCall) {
    ///     if reply.messageType == .methodReturn {
    ///         // Process successful reply
    ///     } else if reply.messageType == .error {
    ///         // Handle D-Bus error
    ///     }
    /// }
    ///
    /// // Send a signal (no reply expected)
    /// let signal = try Message.signal(
    ///     path: ObjectPath("/com/example/Object"),
    ///     interface: "com.example.Interface",
    ///     member: "SomethingHappened",
    ///     serial: connection.nextSerial()
    /// )
    ///
    /// _ = try await connection.send(message: signal)  // Returns nil
    /// ```
    ///
    /// ## Error Conditions
    ///
    /// - `connectionClosed`: Connection is not in connected state
    /// - `messageSerializationFailed`: Message could not be serialized
    /// - `socketError`: Network transmission failed
    ///
    /// ## Internal Implementation Notes
    ///
    /// - Uses SwiftNIO for asynchronous network I/O
    /// - Manages pending reply correlations with continuation-based design
    /// - Handles message serialization according to D-Bus wire format
    /// - Supports both little-endian and big-endian message formats
    public func send(message: Message) async throws -> Message? {
        guard case .connected = state else {
            throw ConnectionError.connectionClosed
        }

        guard let channel = self.channel else {
            throw ConnectionError.connectionClosed
        }

        // Serialize the message
        let serializedData: [UInt8]
        do {
            serializedData = try message.serialize()
        } catch {
            throw ConnectionError.messageSerializationFailed
        }

        let buffer = channel.allocator.buffer(bytes: serializedData)

        // For method calls that expect replies, set up continuation
        if message.messageType == .methodCall && !message.flags.contains(.noReplyExpected) {
            let messageSerial = message.serial
            return try await withCheckedThrowingContinuation { cont in
                pendingReplies[messageSerial] = cont

                // Send the message
                channel.writeAndFlush(buffer).whenComplete { [weak self] result in
                    if case .failure(let error) = result {
                        Task {
                            await self?.handleSendError(error, forSerial: messageSerial)
                        }
                    }
                }
            }
        } else {
            // Send without expecting reply
            return try await withCheckedThrowingContinuation { cont in
                channel.writeAndFlush(buffer).whenComplete { result in
                    switch result {
                    case .success:
                        cont.resume(returning: nil)
                    case .failure(let error):
                        cont.resume(
                            throwing: ConnectionError.socketError(error.localizedDescription))
                    }
                }
            }
        }
    }

    /// Create a method call message with automatic serial number assignment
    ///
    /// - Parameters:
    ///   - path: Object path
    ///   - interface: Interface name (optional)
    ///   - member: Method name
    ///   - destination: Destination bus name (optional)
    ///   - body: Message body (optional)
    ///   - bodySignature: Body signature (optional)
    ///   - flags: Message flags (optional)
    /// - Returns: A new method call message with assigned serial number
    public func createMethodCall(
        path: ObjectPath,
        interface: String? = nil,
        member: String,
        destination: String? = nil,
        body: [UInt8] = [],
        bodySignature: Signature? = nil,
        flags: DBusMessageFlags = []
    ) throws -> Message {
        let serial = nextSerial()
        return try Message.methodCall(
            path: path,
            interface: interface,
            member: member,
            destination: destination,
            serial: serial,
            body: body,
            bodySignature: bodySignature,
            flags: flags
        )
    }

    // MARK: - Object Export/Unexport

    /// Export an object to the D-Bus for method calls and property access
    /// - Parameters:
    ///   - object: The object to export
    ///   - path: The object path to export the object on
    /// - Throws: ConnectionError if the connection is not established or ObjectRegistryError if the object is already exported
    public func export<T: Exportable>(_ object: T, at path: ObjectPath) async throws {
        guard self.isConnected else {
            throw ConnectionError.connectionClosed
        }
        try await objectManager?.export(object, at: path)
    }

    /// Unexport an object from the D-Bus
    /// - Parameter path: The object path to unexport the object from
    /// - Throws: ConnectionError if the connection is not established or ObjectRegistryError if the object is not exported
    public func unexport(at path: ObjectPath) async throws {
        guard self.isConnected else {
            throw ConnectionError.connectionClosed
        }
        await objectManager?.unexport(at: path)
    }

    /// Get introspection XML for an object
    /// - Parameter path: The object path to introspect
    /// - Returns: XML introspection data or nil if object not found
    public func introspect(path: ObjectPath, interface: String) async throws -> String? {
        guard let objectManager = objectManager,
            let exportedObject = await objectManager.object(at: path)
        else {
            return nil
        }
        return try await exportedObject.getIntrospectionData()
    }

    // MARK: - Signal Handler Registration

    /// Register a signal handler for a specific object path and interface
    /// - Parameters:
    ///   - objectPath: The object path to listen for signals from
    ///   - interface: The interface to listen for signals from
    ///   - handler: The handler to call when matching signals are received
    public func registerSignalHandler(
        for objectPath: ObjectPath,
        interface: String,
        handler: @escaping (Message) async -> Void
    ) async {
        let key = SignalHandlerKey(objectPath: objectPath, interface: interface)
        signalHandlers[key] = handler
    }

    /// Remove a signal handler for a specific object path and interface
    /// - Parameters:
    ///   - objectPath: The object path to stop listening for signals from
    ///   - interface: The interface to stop listening for signals from
    public func unregisterSignalHandler(for objectPath: ObjectPath, interface: String) async {
        let key = SignalHandlerKey(objectPath: objectPath, interface: interface)
        signalHandlers.removeValue(forKey: key)
    }

    // MARK: - Serial Number Management

    /// Get next serial number (internal method for DBusObject system)
    public func nextSerial() -> UInt32 {
        let current = messageSerial
        messageSerial = messageSerial &+ 1
        if messageSerial == 0 {
            messageSerial = 1  // Serial must never be 0
        }
        return current
    }

    // MARK: - NIO Integration (nonisolated for channel handler callbacks)

    /// Handler called by DBusChannelHandler.channelRead to process incoming
    /// data. This is nonisolated to allow NIO channel handlers to call it directly.
    nonisolated func handleIncomingData(_ buffer: ByteBuffer) {
        Task {
            await self.processIncomingData(buffer)
        }
    }

    /// Handler called by DBusChannelHandler.errorCaught to handle channel errors.
    /// This is nonisolated to allow NIO channel handlers to call it directly.
    nonisolated func handleChannelError(_ error: Error) {
        Task {
            await self.processChannelError(error)
        }
    }

    // MARK: - Private Actor-Isolated Methods

    /// Actor-isolated method to process incoming data
    private func processIncomingData(_ buffer: ByteBuffer) async {
        // During authentication, only forward data to the authentication manager
        if case .authenticating = state, let authenticationManager = authenticationManager {
            await authenticationManager.updateBuffer(buffer)
            return  // Don't process as D-Bus messages during auth
        }

        // Only write to main buffer and process D-Bus messages when connected
        if case .connected = state {
            var mutableBuffer = buffer
            incomingBuffer.writeBuffer(&mutableBuffer)

            // Process all available messages in the buffer
            while let message = extractNextMessage() {
                await handleReceivedMessage(message)
            }
        }
    }

    /// Actor-isolated method to process channel errors
    private func processChannelError(_ error: Error) async {
        state = .error(.socketError(error.localizedDescription))

        // Cancel all pending replies
        for (_, continuation) in pendingReplies {
            continuation.resume(
                throwing: ConnectionError.socketError(error.localizedDescription))
        }
        pendingReplies.removeAll()
    }

    /// Handle received D-Bus messages with proper routing
    private func handleReceivedMessage(_ message: Message) async {
        // Handle replies to pending method calls
        if message.messageType == .methodReturn || message.messageType == .error {
            if let replySerial = message.replySerial,
                let continuation = pendingReplies.removeValue(forKey: replySerial)
            {
                continuation.resume(returning: message)
                return
            }
        }

        // Handle signal messages by routing to registered handlers
        if message.messageType == .signal {
            await routeSignalToHandlers(message)
            return
        }

        // Route remaining messages through the ObjectRegistry, assuming they
        // are for exported objects.
        do {
            if let response = try await objectManager?.handleMethodCall(message) {
                // Send the response back
                _ = try await send(message: response)
            }
        } catch {
            // Log error handling the message
            print("Error handling message: \(error)")
        }
    }

    /// Route a signal message to registered handlers
    private func routeSignalToHandlers(_ message: Message) async {
        guard let objectPath = message.path,
            let interface = message.interface
        else {
            return
        }

        let key = SignalHandlerKey(objectPath: objectPath, interface: interface)
        if let handler = signalHandlers[key] {
            await handler(message)
        }
    }

    /// Handle send errors for pending replies
    private func handleSendError(_ error: Error, forSerial serial: UInt32) async {
        if let continuation = pendingReplies.removeValue(forKey: serial) {
            continuation.resume(
                throwing: ConnectionError.socketError(error.localizedDescription))
        }
    }

    // MARK: - Private Methods

    private func resolveAddress(for busType: BusType) throws -> String {
        switch busType {
        case .system:
            return try getSystemBusAddress()
        case .session:
            return try getSessionBusAddress()
        case .address(let address):
            return address
        }
    }

    private func getSystemBusAddress() throws -> String {
        // Check environment variable first
        if let address = ProcessInfo.processInfo.environment["DBUS_SYSTEM_BUS_ADDRESS"] {
            return address
        }

        // Default system bus socket path for Unix systems
        #if os(macOS) || os(Linux)
            return "unix:path=/var/run/dbus/system_bus_socket"
        #else
            throw ConnectionError.environmentVariableNotSet("DBUS_SYSTEM_BUS_ADDRESS")
        #endif
    }

    private func getSessionBusAddress() throws -> String {
        // Check environment variable
        guard let address = ProcessInfo.processInfo.environment["DBUS_SESSION_BUS_ADDRESS"] else {
            throw ConnectionError.environmentVariableNotSet("DBUS_SESSION_BUS_ADDRESS")
        }
        return address
    }

    private func parseAddress(_ address: String) throws -> ParsedAddress {
        // Parse D-Bus address format: transport:key1=value1,key2=value2
        let components = address.split(separator: ":", maxSplits: 1)
        guard components.count == 2 else {
            throw ConnectionError.invalidAddress(address)
        }

        let transport = String(components[0])
        let params = String(components[1])

        var parsedParams: [String: String] = [:]

        for param in params.split(separator: ",") {
            let keyValue = param.split(separator: "=", maxSplits: 1)
            if keyValue.count == 2 {
                parsedParams[String(keyValue[0])] = String(keyValue[1])
            }
        }

        return ParsedAddress(transport: transport, parameters: parsedParams)
    }

    // MARK: - Channel Pipeline Creation

    /// Create a channel and connect to the specified address.
    private func createChannelAndConnect(to address: ParsedAddress) async throws -> Channel {
        switch address.transport.lowercased() {
        case "unix":
            guard let path = address.parameters["path"] else {
                throw ConnectionError.invalidAddress("Unix transport missing path parameter")
            }

            // Check if socket file exists and is accessible
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: path) else {
                throw ConnectionError.connectionFailed("Socket file does not exist: \(path)")
            }

            let bootstrap = ClientBootstrap(group: NIOSingletons.posixEventLoopGroup)
                .connectTimeout(TimeAmount.seconds(30))  // Add connection timeout
                .channelInitializer { channel in
                    channel.pipeline.addHandler(DBusChannelHandler(connection: self))
                }

            return try await bootstrap.connect(unixDomainSocketPath: path).get()
        default:
            throw ConnectionError.unsupportedTransport(address.transport)
        }
    }

    /// Attempts to extract a complete D-Bus message from the incoming buffer.
    ///
    /// The incoming buffer is not advanced unless a message is successfully
    /// extracted.
    ///
    /// - Returns: The next complete D-Bus message, or nil if no complete
    ///   message is available.
    private func extractNextMessage() -> Message? {
        guard incomingBuffer.readableBytes >= 16 else {
            return nil  // Need at least 16 bytes for header
        }

        // Parse header to get message size
        guard let headerData = incomingBuffer.getBytes(at: incomingBuffer.readerIndex, length: 16)
        else {
            return nil
        }

        let endianness: Endianness = headerData[0] == UInt8(ascii: "l") ? .littleEndian : .bigEndian

        // Extract body length (bytes 4-7) - break up complex expression
        let bodyLength: UInt32
        if endianness == .littleEndian {
            let b0 = UInt32(headerData[4])
            let b1 = UInt32(headerData[5]) << 8
            let b2 = UInt32(headerData[6]) << 16
            let b3 = UInt32(headerData[7]) << 24
            bodyLength = b0 | b1 | b2 | b3
        } else {
            let b0 = UInt32(headerData[4]) << 24
            let b1 = UInt32(headerData[5]) << 16
            let b2 = UInt32(headerData[6]) << 8
            let b3 = UInt32(headerData[7])
            bodyLength = b0 | b1 | b2 | b3
        }

        // Extract header fields array length (bytes 12-15) - break up complex expression
        let headerFieldsLength: UInt32
        if endianness == .littleEndian {
            let h0 = UInt32(headerData[12])
            let h1 = UInt32(headerData[13]) << 8
            let h2 = UInt32(headerData[14]) << 16
            let h3 = UInt32(headerData[15]) << 24
            headerFieldsLength = h0 | h1 | h2 | h3
        } else {
            let h0 = UInt32(headerData[12]) << 24
            let h1 = UInt32(headerData[13]) << 16
            let h2 = UInt32(headerData[14]) << 8
            let h3 = UInt32(headerData[15])
            headerFieldsLength = h0 | h1 | h2 | h3
        }

        // Calculate total message size
        let totalHeaderLength = 16 + Int(headerFieldsLength)
        let padding = (8 - (totalHeaderLength % 8)) % 8
        let totalMessageLength = totalHeaderLength + padding + Int(bodyLength)

        guard incomingBuffer.readableBytes >= totalMessageLength else {
            return nil  // Don't have complete message yet
        }

        // Extract complete message
        guard let messageBytes = incomingBuffer.readBytes(length: totalMessageLength) else {
            return nil
        }

        // Deserialize message
        do {
            return try Message.deserialize(from: messageBytes)
        } catch {
            print("Error deserializing message: \(error)")
            return nil
        }
    }
}

// MARK: - Helper Types

private struct ParsedAddress {
    let transport: String
    let parameters: [String: String]
}
