[![Coverage Status](https://coveralls.io/repos/github/subpop/swift-dbus/badge.svg?branch=main)](https://coveralls.io/github/subpop/swift-dbus?branch=main)

# Swift D-Bus Library

A Swift library for working with D-Bus, providing both low-level wire protocol handling and high-level Swift integration through async/await and Codable support.

## Features

- **Full D-Bus Protocol Implementation**: Complete D-Bus wire format serialization and message handling
- **Swift Async/Await**: Modern concurrency support throughout the API
- **Connection Management**: Robust connection handling with authentication and reconnection
- **Object Export**: Export Swift objects as D-Bus services using the `Exportable` protocol
- **Proxy Objects**: Type-safe access to remote D-Bus objects
- **Codable Integration**: Encode/decode Swift types using familiar `Codable` protocols
- **Comprehensive Type Support**: All D-Bus basic types, arrays, structs, dictionaries, and variants
- **Command-Line Tool**: `DBusUtil` for interacting with D-Bus services from the command line
- **SwiftNIO Integration**: High-performance networking with SwiftNIO
- **Authentication Support**: SASL EXTERNAL and ANONYMOUS authentication for secure connections

## Architecture

The library provides a single `DBus` module with a layered architecture:

```
┌─────────────────────────────────────────┐
│           High-Level API                │
│  Connection, ProxyObject, Exportable    │
├─────────────────────────────────────────┤
│           Codable Integration           │
│      DBusEncoder, DBusDecoder           │
├─────────────────────────────────────────┤
│         Wire Protocol Layer             │
│  Message, Serializer, Deserializer      │
├─────────────────────────────────────────┤
│            Type System                  │
│ Signature, ObjectPath, Variant, etc.    │
└─────────────────────────────────────────┘
```

### Core Components

- **`Connection`**: Manages D-Bus connections with full async/await support
- **`ProxyObject`**: Provides type-safe access to remote D-Bus objects
- **`Exportable`**: Protocol for exporting Swift objects as D-Bus services
- **`Message`**: Represents D-Bus messages with full header and body support
- **`Serializer`/`Deserializer`**: Handle D-Bus wire format encoding/decoding
- **`DBusEncoder`/`DBusDecoder`**: Swift Codable integration

## Installation

### Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/subpop/swift-dbus.git", from: "1.0.0")
]
```

Then import the module:

```swift
import DBus
```

### Requirements

- Swift 6.0.3+
- macOS 13.0+
- Linux (with Swift support)

## Quick Start

### Connecting to D-Bus

```swift
import DBus

// Connect to session bus
let connection = try await Connection.sessionBusConnection()

// Connect to system bus  
let connection = try await Connection.systemBusConnection()

// Connect to specific address
let connection = Connection()
try await connection.open(address: "unix:path=/var/run/dbus/system_bus_socket")
```

### Calling Remote Methods

```swift
// Create a proxy object for a remote service
let proxy = connection.proxyObject(
    serviceName: "org.freedesktop.NetworkManager",
    objectPath: ObjectPath("/org/freedesktop/NetworkManager"),
    interfaceName: "org.freedesktop.NetworkManager"
)

// Call a method and get the result
if let (signature, data) = try await proxy.call(
    "GetDevices",
    signature: nil as Signature?,
    body: []
) {
    let decoder = DBusDecoder()
    let devices = try decoder.decode([ObjectPath].self, from: data, signature: signature)
    print("Network devices: \(devices)")
}
```

### Getting Properties

```swift
// Get a property from a remote object
if let (signature, data) = try await proxy.getProperty("State") {
    let decoder = DBusDecoder()
    let state = try decoder.decode(UInt32.self, from: data, signature: signature)
    print("NetworkManager state: \(state)")
}
```

### Exporting Objects

```swift
// Define a service by implementing Exportable
class CalculatorService: Exportable {
    var interfaces: [String: Interface] = [:]
    
    init() {
        // Define the interface
        interfaces["com.example.Calculator"] = Interface(
            name: "com.example.Calculator",
            methods: [
                "Add": Method(
                    name: "Add",
                    arguments: [
                        Argument(name: "a", signature: Signature("i"), direction: .in),
                        Argument(name: "b", signature: Signature("i"), direction: .in),
                        Argument(name: "result", signature: Signature("i"), direction: .out)
                    ]
                )
            ]
        )
    }
    
    func call(interface: String, method: String, signature: Signature, arguments: [UInt8]) async throws -> (Signature, [UInt8]) {
        if interface == "com.example.Calculator" && method == "Add" {
            // Deserialize arguments
            var deserializer = Deserializer(data: arguments, signature: signature, endianness: .littleEndian)
            let a: Int32 = try deserializer.unserialize()
            let b: Int32 = try deserializer.unserialize()
            
            // Calculate result
            let result = a + b
            
            // Serialize result
            let resultSignature = Signature("i")
            var serializer = Serializer(signature: resultSignature, endianness: .littleEndian)
            try serializer.serialize(result)
            
            return (resultSignature, serializer.data ?? [])
        }
        
        throw DBusError.unknownMethod
    }
    
    func getProperty(interface: String, name: String) async throws -> (Signature, [UInt8]) {
        throw DBusError.unknownProperty
    }
    
    func setProperty(interface: String, name: String, variant: Variant) async throws {
        throw DBusError.unknownProperty
    }
}

// Export the service
let calculator = CalculatorService()
try await connection.export(calculator, at: ObjectPath("/com/example/Calculator"))

// Request a bus name
let result = try await connection.requestName(name: "com.example.Calculator")
```

### Using Codable

```swift
// Encode basic types
let encoder = DBusEncoder()
let boolData = try encoder.encode(true, signature: "b")
let stringData = try encoder.encode("Hello D-Bus", signature: "s")
let arrayData = try encoder.encode([1, 2, 3, 4], signature: "ai")

// Decode basic types  
let decoder = DBusDecoder()
let decodedBool = try decoder.decode(Bool.self, from: boolData, signature: "b")
let decodedString = try decoder.decode(String.self, from: stringData, signature: "s")
let decodedArray = try decoder.decode([Int32].self, from: arrayData, signature: "ai")
```

## Command-Line Tool

The library includes `DBusUtil`, a command-line tool for D-Bus interaction:

### List Bus Names

```bash
# List session bus names
swift run DBusUtil list

# List system bus names  
swift run DBusUtil list --bus system
```

### Call Methods

```bash
# Call a method
swift run DBusUtil call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ListNames "" 

# Call with arguments
swift run DBusUtil call com.example.Calculator /com/example/Calculator com.example.Calculator Add "ii" 5 3
```

### Get Properties

```bash
# Get a property
swift run DBusUtil get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager State
```

### Set Properties

```bash
# Set a string property
swift run DBusUtil set-property com.example.Service /com/example/Object com.example.Interface MyStringProperty s "Hello World"

# Set an integer property
swift run DBusUtil set-property com.example.Service /com/example/Object com.example.Interface MyIntProperty i 42

# Set a boolean property  
swift run DBusUtil set-property com.example.Service /com/example/Object com.example.Interface MyBoolProperty b true

# Set a double property
swift run DBusUtil set-property com.example.Service /com/example/Object com.example.Interface MyDoubleProperty d 3.14159
```

### Emit Signals

```bash
# Emit a signal
swift run DBusUtil emit /com/example/Object com.example.Interface MySignal "s" "Hello World"
```

### Wait for Signals

```bash
# Wait for a signal
swift run DBusUtil wait /org/freedesktop/DBus org.freedesktop.DBus NameOwnerChanged

# Wait with timeout (in seconds)
swift run DBusUtil wait /org/freedesktop/DBus org.freedesktop.DBus NameOwnerChanged --timeout 10
```

### Introspect Objects

```bash
# Introspect an object
swift run DBusUtil introspect org.freedesktop.DBus /org/freedesktop/DBus
```

### Run Echo Service

```bash
# Export a simple echo service for testing
swift run DBusUtil echo-service
```

## D-Bus Type Mapping

| D-Bus Signature | Swift Type | Description |
|-----------------|------------|-------------|
| `b` | `Bool` | Boolean value |
| `y` | `UInt8` | Unsigned 8-bit integer (byte) |
| `n` | `Int16` | Signed 16-bit integer |
| `q` | `UInt16` | Unsigned 16-bit integer |
| `i` | `Int32` | Signed 32-bit integer |
| `u` | `UInt32` | Unsigned 32-bit integer |
| `x` | `Int64` | Signed 64-bit integer |
| `t` | `UInt64` | Unsigned 64-bit integer |
| `d` | `Double` | IEEE 754 double precision floating point |
| `s` | `String` | UTF-8 string |
| `o` | `ObjectPath` | D-Bus object path |
| `g` | `Signature` | D-Bus type signature |
| `v` | `Variant` | Variant (type-erased value) |
| `ai` | `[Int32]` | Array of signed 32-bit integers |
| `as` | `[String]` | Array of strings |
| `a{sv}` | `[String: Variant]` | Dictionary with string keys and variant values |
| `(si)` | Struct | Structure with string and int32 |

## API Reference

### Connection

```swift
public actor Connection {
    // Singleton connections
    static func sessionBusConnection() async throws -> Connection
    static func systemBusConnection() async throws -> Connection
    
    // Connection management
    func connect(to busType: BusType) async throws
    func open(address: String) async throws
    func disconnect() async
    
    // Message sending
    func send(message: Message) async throws -> Message?
    
    // Object management
    func export<T: Exportable>(_ object: T, at path: ObjectPath) async throws
    func unexport(at path: ObjectPath) async
    func proxyObject(serviceName: String, objectPath: ObjectPath, interfaceName: String) -> ProxyObject
    
    // Bus operations
    func requestName(name: String, flags: RequestNameFlags = []) async throws -> RequestNameReply?
    func releaseName(name: String) async throws -> ReleaseNameReply?
    func listNames() async throws -> [String]?
    
    // Properties
    var isConnected: Bool { get }
    var connectionState: ConnectionState { get }
}
```

### ProxyObject

```swift
public actor ProxyObject {
    // Method calling
    func call(_ method: String, interface: String? = nil, signature: Signature?, body: [UInt8]) async throws -> (Signature, [UInt8])?
    
    // Property access
    func getProperty(_ name: String) async throws -> (Signature, [UInt8])?
    func setProperty(_ name: String, value: Variant) async throws
    func getAllProperties() async throws -> (Signature, [UInt8])?
    
    // Properties
    let serviceName: String
    let objectPath: ObjectPath
    let interfaceName: String
}
```

### Exportable Protocol

```swift
public protocol Exportable: AnyObject, Sendable {
    var interfaces: [String: Interface] { get set }
    
    func call(interface: String, method: String, signature: Signature, arguments: [UInt8]) async throws -> (Signature, [UInt8])
    func getProperty(interface: String, name: String) async throws -> (Signature, [UInt8])
    func setProperty(interface: String, name: String, variant: Variant) async throws
}
```

### Codable Support

```swift
public class DBusEncoder {
    func encode<T: Encodable>(_ value: T, signature: Signature) throws -> [UInt8]
    func encode<T: Encodable>(_ value: T, signature: String) throws -> [UInt8]
    func encode<T: Encodable>(_ value: T) throws -> [UInt8] // Automatic signature inference
}

public class DBusDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: [UInt8], signature: Signature) throws -> T
    func decode<T: Decodable>(_ type: T.Type, from data: [UInt8], signature: String) throws -> T
}
```

## Advanced Usage

### Custom Authentication

```swift
// Use EXTERNAL authentication (default)
try await connection.connect(to: .session, authenticationType: .external)

// Use ANONYMOUS authentication for testing
try await connection.connect(to: .session, authenticationType: .anonymous)
```

### Message Handling

```swift
// Create custom messages
let message = try Message.methodCall(
    path: ObjectPath("/com/example/Object"),
    interface: "com.example.Interface", 
    member: "Method",
    destination: "com.example.Service",
    serial: 1,
    body: [],
    bodySignature: nil
)

// Send and receive
if let reply = try await connection.send(message: message) {
    print("Received reply: \(reply)")
}
```

### Low-Level Serialization

```swift
// Direct serialization
let signature = Signature("(si)")
var serializer = Serializer(signature: signature, endianness: .littleEndian)

try serializer.serialize { structSerializer in
    try structSerializer.serialize("Hello")
    try structSerializer.serialize(Int32(42))
}

if let data = serializer.data {
    print("Serialized data: \(data)")
}
```

## Testing

Run the test suite:

```bash
swift test
```

Run specific tests:

```bash
swift test --filter ConnectionTests
swift test --filter EncoderDecoderTests
swift test --filter SerializerTests
```

## Contributing

Contributions are welcome! Areas for improvement:

- Enhanced error handling and recovery
- Type system reliability improvements
- Performance optimizations
- More comprehensive examples
- Documentation improvements

### Development Setup

1. Clone the repository
2. **Using Dev Container (Recommended)**: Open the project in VS Code and use the "Reopen in Container" option to automatically set up the development environment with all dependencies
3. **Manual Setup**: Ensure you have Swift 6.0.3+ installed on your system
4. Run tests: `swift test`
5. Build the command-line tool: `swift build`
6. Try the examples: `swift run DBusUtil --help`

## Dependencies

- [MiniLexer](https://github.com/LuizZak/MiniLexer.git): Parsing support
- [SwiftNIO](https://github.com/apple/swift-nio.git): High-performance networking
- [ArgumentParser](https://github.com/apple/swift-argument-parser.git): Command-line interface
- [Logging](https://github.com/apple/swift-log.git): Structured logging
- [XMLCoder](https://github.com/CoreOffice/XMLCoder.git): XML processing for introspection

## License

This project is licensed under the Apache License, Version 2.0.  
You may use, modify, and distribute this software in accordance with the terms of the Apache 2.0 license.  
See the [LICENSE](LICENSE) file for the full license text.
