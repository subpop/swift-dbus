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
import Testing

@testable import DBus

/// Tests to verify that Message is concurrency-safe and properly conforms to
/// Sendable.
@Suite("Message Concurrency Safety Tests")
struct MessageConcurrencyTests {

    // MARK: - Actor-based Tests

    @MainActor
    @Test("Message can be passed to and from actors")
    func messagePassingBetweenActors() async throws {
        // Create a message on the main actor
        let path = try ObjectPath("/test/concurrent")
        let originalMessage = try Message.methodCall(
            path: path,
            interface: "com.example.Test",
            member: "ConcurrentMethod",
            destination: "com.example.Service",
            serial: 42,
            bodySignature: "s"
        )

        // Pass message to isolated actor and get it back
        let processedMessage = await MessageProcessor().processMessage(originalMessage)

        // Verify message integrity
        #expect(processedMessage.serial == originalMessage.serial)
        #expect(processedMessage.path == originalMessage.path)
        #expect(processedMessage.interface == originalMessage.interface)
        #expect(processedMessage.member == originalMessage.member)
        #expect(processedMessage.destination == originalMessage.destination)
    }

    @Test("Multiple actors can safely access the same message concurrently")
    func multipleActorAccess() async throws {
        let path = try ObjectPath("/test/shared")
        let sharedMessage = try Message.methodCall(
            path: path,
            interface: "com.example.Shared",
            member: "SharedMethod",
            destination: "com.example.Service",
            serial: 123,
            bodySignature: "i"
        )

        // Launch multiple concurrent tasks that access the same message
        let results = await withTaskGroup(
            of: MessageProperties.self, returning: [MessageProperties].self
        ) { group in
            for _ in 0..<10 {
                group.addTask {
                    // Each task accesses the message concurrently
                    let processor = MessageProcessor()
                    return await processor.readMessageProperties(sharedMessage)
                }
            }

            var results: [MessageProperties] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // All tasks should have read the same data
        #expect(results.count == 10)
        for result in results {
            #expect(result.serial == 123)
            #expect(result.path == "/test/shared")
            #expect(result.interface == "com.example.Shared")
            #expect(result.member == "SharedMethod")
            #expect(result.destination == "com.example.Service")
        }
    }

    // MARK: - Task-based Concurrency Tests

    @Test("Message serialization and deserialization in concurrent tasks")
    func concurrentSerializationDeserialization() async throws {
        let path = try ObjectPath("/test/serialization")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Serialization",
            member: "SerializeMethod",
            destination: "com.example.Service",
            serial: 456,
            bodySignature: "s"
        )

        let serialized = try message.serialize()

        // Launch multiple concurrent deserialization tasks
        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    do {
                        let deserialized = try Message.deserialize(from: serialized)
                        return deserialized.serial == 456
                            && deserialized.path?.fullPath == "/test/serialization"
                            && deserialized.interface == "com.example.Serialization"
                            && deserialized.member == "SerializeMethod"
                            && deserialized.destination == "com.example.Service"
                    } catch {
                        return false
                    }
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // All deserializations should succeed
        #expect(results.count == 50)
        #expect(results.allSatisfy { $0 })
    }

    // MARK: - Sendable Conformance Tests

    @Test("Message can be sent across isolation boundaries")
    func sendableConformance() async throws {
        let path = try ObjectPath("/test/sendable")
        let originalMessage = try Message.signal(
            path: path,
            interface: "com.example.Sendable",
            member: "SendableSignal",
            destination: "com.example.Service",
            serial: 789,
            bodySignature: "b"
        )

        // Create multiple concurrent tasks that process the same message
        let results = await withTaskGroup(
            of: Message.self, returning: [Message].self
        ) { group in
            for _ in 0..<20 {
                group.addTask {
                    let data = try! originalMessage.serialize()
                    return try! Message.deserialize(from: data)
                }
            }

            var results: [Message] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // All results should be equivalent to the original
        #expect(results.count == 20)
        for result in results {
            #expect(result.serial == originalMessage.serial)
            #expect(result.path == originalMessage.path)
            #expect(result.interface == originalMessage.interface)
            #expect(result.member == originalMessage.member)
            #expect(result.destination == originalMessage.destination)
        }
    }

    // MARK: - Memory Safety Tests

    @Test("Message remains valid when passed between tasks")
    func memoryConsistency() async throws {
        let path = try ObjectPath("/test/memory")
        let message = try Message.methodCall(
            path: path,
            interface: "com.example.Memory",
            member: "MemoryMethod",
            destination: "com.example.Service",
            serial: 999,
            bodySignature: "d"
        )

        // Pass message through a chain of tasks
        let chainLength = 100
        var currentMessage = message

        for _ in 0..<chainLength {
            let messageToProcess = currentMessage
            let nextMessage = await withTaskGroup(of: Message.self, returning: Message.self) {
                group in
                group.addTask {
                    // Each task in the chain gets the message and returns it
                    return messageToProcess
                }

                return await group.next()!
            }

            // Verify the message is still intact
            #expect(nextMessage.serial == 999)
            #expect(nextMessage.path?.fullPath == "/test/memory")
            #expect(nextMessage.interface == "com.example.Memory")
            #expect(nextMessage.member == "MemoryMethod")
            #expect(nextMessage.destination == "com.example.Service")

            currentMessage = nextMessage
        }
    }

    // MARK: - High-Concurrency Stress Tests

    @Test("Many concurrent message creations")
    func highConcurrencyCreation() async throws {
        let concurrentTasks = 100

        let messages = await withTaskGroup(of: Message.self, returning: [Message].self) { group in
            for i in 0..<concurrentTasks {
                group.addTask {
                    let path = try! ObjectPath("/test/stress/\(i)")
                    return try! Message.methodCall(
                        path: path,
                        interface: "com.example.Stress",
                        member: "StressMethod",
                        destination: "com.example.Service",
                        serial: UInt32(i + 1),  // +1 to ensure serial is never zero
                        bodySignature: "s"
                    )
                }
            }

            var results: [Message] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Verify all messages were created correctly
        #expect(messages.count == concurrentTasks)

        // Sort by serial to check each one
        let sortedMessages = messages.sorted { $0.serial < $1.serial }
        for (index, message) in sortedMessages.enumerated() {
            #expect(message.serial == UInt32(index + 1))  // +1 because serials start from 1
            #expect(message.path?.fullPath == "/test/stress/\(index)")
            #expect(message.interface == "com.example.Stress")
            #expect(message.member == "StressMethod")
            #expect(message.destination == "com.example.Service")
        }
    }

    // MARK: - Error Handling in Concurrent Context

    @Test("Error handling doesn't break concurrency safety")
    func concurrentErrorHandling() async throws {
        let path = try ObjectPath("/test/error")

        // Create a valid message
        let validMessage = try Message.methodCall(
            path: path,
            interface: "com.example.Error",
            member: "ErrorMethod",
            destination: "com.example.Service",
            serial: 1111
        )

        // Create an invalid message (method call without required path and member fields)
        let invalidMessage = try Message(
            endianness: .littleEndian,
            messageType: .methodCall,
            serial: 2222,  // Valid serial, but missing required header fields
            headerFields: []  // Missing required .path and .member fields
        )

        // Test concurrent access to both valid and invalid messages
        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            // Add tasks that work with valid message
            for _ in 0..<25 {
                group.addTask {
                    do {
                        let data = try validMessage.serialize()
                        let _ = try Message.deserialize(from: data)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            // Add tasks that work with invalid message
            for _ in 0..<25 {
                group.addTask {
                    do {
                        try invalidMessage.validate()
                        return false  // Should not reach here
                    } catch {
                        return true  // Expected to throw
                    }
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // All tasks should succeed (valid ones succeed, invalid ones properly fail)
        #expect(results.count == 50)
        #expect(results.allSatisfy { $0 })
    }

    // MARK: - Message Factory Methods Concurrency

    @Test("All message factory methods are thread-safe")
    func factoryMethodsConcurrency() async throws {
        let path = try ObjectPath("/test/factory")
        let concurrentCalls = 20

        let messages = await withTaskGroup(of: [Message].self, returning: [Message].self) { group in
            group.addTask {
                var messages: [Message] = []
                for i in 0..<concurrentCalls {
                    messages.append(
                        try! Message.methodCall(
                            path: path,
                            interface: "com.example.Factory",
                            member: "MethodCall",
                            destination: "com.example.Service",
                            serial: UInt32(1000 + i)
                        ))
                }
                return messages
            }

            group.addTask {
                var messages: [Message] = []
                for i in 0..<concurrentCalls {
                    messages.append(
                        try! Message.methodReturn(
                            replySerial: UInt32(2000 + i),
                            destination: "com.example.Service",
                            serial: UInt32(3000 + i)
                        ))
                }
                return messages
            }

            group.addTask {
                var messages: [Message] = []
                for i in 0..<concurrentCalls {
                    messages.append(
                        try! Message.error(
                            errorName: "com.example.Error",
                            replySerial: UInt32(4000 + i),
                            destination: "com.example.Service",
                            serial: UInt32(5000 + i)
                        ))
                }
                return messages
            }

            group.addTask {
                var messages: [Message] = []
                for i in 0..<concurrentCalls {
                    messages.append(
                        try! Message.signal(
                            path: path,
                            interface: "com.example.Factory",
                            member: "Signal",
                            destination: "com.example.Service",
                            serial: UInt32(6000 + i)
                        ))
                }
                return messages
            }

            var allMessages: [Message] = []
            for await messageGroup in group {
                allMessages.append(contentsOf: messageGroup)
            }
            return allMessages
        }

        // Should have 4 groups of 20 messages each
        #expect(messages.count == 80)

        // Verify each message is valid
        for message in messages {
            do {
                let serialized = try message.serialize()
                let deserialized = try Message.deserialize(from: serialized)
                #expect(deserialized.serial == message.serial)
            } catch {
                #expect(Bool(false), "Message should be valid: \(error)")
            }
        }
    }

    // MARK: - Real-World Scenario Tests

    @Test("Simulate real-world message processing pipeline")
    func realWorldScenario() async throws {
        let path = try ObjectPath("/test/realworld")

        // Create a base message that will be processed through a pipeline
        let baseMessage = try Message.methodCall(
            path: path,
            interface: "com.example.Pipeline",
            member: "ProcessData",
            destination: "com.example.Service",
            serial: 2024,
            body: "Hello, D-Bus!".data(using: .utf8)?.map { $0 } ?? [],
            bodySignature: "s"
        )

        // Simulate a processing pipeline with multiple stages
        let stages = 10
        let messagesPerStage = 20

        var stageResults: [[Message]] = []

        for stage in 1..<stages {
            let stageMessages = await withTaskGroup(of: Message.self, returning: [Message].self) {
                group in
                for i in 0..<messagesPerStage {
                    group.addTask {
                        // Each stage processes the base message
                        let serialized = try! baseMessage.serialize()
                        let deserialized = try! Message.deserialize(from: serialized)

                        // Simulate processing by creating a new message with modified serial
                        return try! Message.methodCall(
                            path: deserialized.path!,
                            interface: deserialized.interface!,
                            member: deserialized.member!,
                            destination: deserialized.destination!,
                            serial: deserialized.serial + UInt32(stage * messagesPerStage + i),
                            body: deserialized.body,
                            bodySignature: deserialized.bodySignature
                        )
                    }
                }

                var results: [Message] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            // Sort messages by serial to ensure consistent ordering for verification
            let sortedMessages = stageMessages.sorted { $0.serial < $1.serial }
            stageResults.append(sortedMessages)
        }

        // Verify the pipeline processed all messages correctly
        #expect(stageResults.count == stages - 1)  // stages-1 because we skip stage 0

        for (stageIndex, stageMessages) in stageResults.enumerated() {
            #expect(stageMessages.count == messagesPerStage)

            for (messageIndex, message) in stageMessages.enumerated() {
                // Account for the offset: stageIndex 0 corresponds to stage 1
                let actualStage = stageIndex + 1
                let expectedSerial =
                    baseMessage.serial + UInt32(actualStage * messagesPerStage + messageIndex)
                #expect(message.serial == expectedSerial)
                #expect(message.path == baseMessage.path)
                #expect(message.interface == baseMessage.interface)
                #expect(message.member == baseMessage.member)
                #expect(message.destination == baseMessage.destination)
                #expect(message.body == baseMessage.body)
            }
        }
    }
}

// MARK: - Supporting Types and Actors

/// Actor for processing messages in isolation
actor MessageProcessor {
    func processMessage(_ message: Message) -> Message {
        // Simulate some processing work
        return message
    }

    /// Read message properties concurrently
    func readMessageProperties(_ message: Message) -> MessageProperties {
        // Access various properties to test concurrent safety
        return MessageProperties(
            serial: message.serial,
            path: message.path?.fullPath ?? "",
            interface: message.interface ?? "",
            member: message.member ?? "",
            destination: message.destination ?? ""
        )
    }
}

/// Value type for holding message properties
struct MessageProperties {
    let serial: UInt32
    let path: String
    let interface: String
    let member: String
    let destination: String
}
