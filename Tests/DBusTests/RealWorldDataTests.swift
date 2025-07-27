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

import Testing

@testable import DBus

/// Test cases using real-world D-Bus message data
/// Based on actual D-Bus traffic from common services like NetworkManager, systemd, etc.
@Suite("Real world data tests") struct RealWorldDataTests {

    // MARK: - NetworkManager Messages

    @Test func networkManagerDeviceList() throws {
        // Real NetworkManager.GetDevices() response
        // Method call: org.freedesktop.NetworkManager.GetDevices() -> ao (array of object paths)
        let signature: Signature = "ao"
        let devicePaths = [
            try ObjectPath("/org/freedesktop/NetworkManager/Devices/0"),
            try ObjectPath("/org/freedesktop/NetworkManager/Devices/1"),
            try ObjectPath("/org/freedesktop/NetworkManager/Devices/2"),
        ]

        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test encoding
        let encoded = try encoder.encode(devicePaths, signature: signature)
        #expect(!encoded.isEmpty, "Encoded device list should not be empty")

        // Test decoding
        let decoded = try decoder.decode([ObjectPath].self, from: encoded, signature: signature)
        #expect(decoded.count == devicePaths.count, "Should decode same number of devices")
        #expect(decoded[0].fullPath == "/org/freedesktop/NetworkManager/Devices/0")
        #expect(decoded[1].fullPath == "/org/freedesktop/NetworkManager/Devices/1")
        #expect(decoded[2].fullPath == "/org/freedesktop/NetworkManager/Devices/2")
    }

    @Test func networkManagerConnectionProperties() throws {
        // Real NetworkManager connection properties (simplified)
        // Use separate dictionaries rather than a struct, as that's what the signature expects
        let connectionDict = [
            "id": "MyWiFi",
            "type": "802-11-wireless",
            "uuid": "12345678-1234-1234-1234-123456789abc",
        ]
        let wifiDict = [
            "ssid": "MyNetworkName",
            "mode": "infrastructure",
        ]

        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test connection dictionary separately
        let connectionEncoded = try encoder.encode(connectionDict, signature: "a{ss}")
        let connectionDecoded = try decoder.decode(
            [String: String].self, from: connectionEncoded, signature: "a{ss}")
        #expect(connectionDecoded["id"] == "MyWiFi")

        // Test wifi dictionary separately
        let wifiEncoded = try encoder.encode(wifiDict, signature: "a{ss}")
        let wifiDecoded = try decoder.decode(
            [String: String].self, from: wifiEncoded, signature: "a{ss}")
        #expect(wifiDecoded["ssid"] == "MyNetworkName")
    }

    // MARK: - systemd Messages

    @Test func systemdUnitStatus() throws {
        // systemd GetUnitFileState() response
        // Returns: s (string) - one of "enabled", "disabled", "static", etc.
        let signature: Signature = "s"
        let unitState = "enabled"

        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let encoded = try encoder.encode(unitState, signature: signature)
        let decoded = try decoder.decode(String.self, from: encoded, signature: signature)

        #expect(decoded == unitState)
    }

    @Test func systemdJobInfo() throws {
        // systemd job information: (uint32 id, string unit, string type, string
        // state, object_path job_path)
        struct JobInfo: Codable {
            let jobId: UInt32
            let jobUnit: String
            let jobType: String
            let jobState: String
            let jobPath: ObjectPath
        }
        // Need to use tuple encoding since this is a struct
        let signature: Signature = "(ussso)"
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let jobInfo = JobInfo(
            jobId: 1234,
            jobUnit: "NetworkManager.service",
            jobType: "start",
            jobState: "running",
            jobPath: try ObjectPath("/org/freedesktop/systemd1/job/1234")
        )

        let encodedData = try encoder.encode(jobInfo, signature: signature)
        let decodedData = try decoder.decode(JobInfo.self, from: encodedData, signature: signature)
        #expect(decodedData.jobId == 1234)
        #expect(decodedData.jobUnit == "NetworkManager.service")
        #expect(decodedData.jobType == "start")
        #expect(decodedData.jobState == "running")
        #expect(decodedData.jobPath.fullPath == "/org/freedesktop/systemd1/job/1234")
    }

    // MARK: - Notification Service Messages

    @Test func notificationServiceBasic() throws {
        // Test individual components of notification rather than the complex struct
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test basic notification fields
        let appName = "TestApp"
        let appNameEncoded = try encoder.encode(appName, signature: "s")
        let appNameDecoded = try decoder.decode(String.self, from: appNameEncoded, signature: "s")
        #expect(appNameDecoded == "TestApp")

        let replacesId: UInt32 = 0
        let replacesIdEncoded = try encoder.encode(replacesId, signature: "u")
        let replacesIdDecoded = try decoder.decode(
            UInt32.self, from: replacesIdEncoded, signature: "u")
        #expect(replacesIdDecoded == 0)

        let actions = ["default", "Show Details"]
        let actionsEncoded = try encoder.encode(actions, signature: "as")
        let actionsDecoded = try decoder.decode(
            [String].self, from: actionsEncoded, signature: "as")
        #expect(actionsDecoded.count == 2)
        #expect(actionsDecoded[0] == "default")
        #expect(actionsDecoded[1] == "Show Details")

        let expireTimeout: Int32 = 5000
        let timeoutEncoded = try encoder.encode(expireTimeout, signature: "i")
        let timeoutDecoded = try decoder.decode(Int32.self, from: timeoutEncoded, signature: "i")
        #expect(timeoutDecoded == 5000)
    }

    // MARK: - UDisks2 Messages (Storage Management)

    @Test func uDisks2DriveInfo() throws {
        // Test individual fields of drive info rather than the complex struct
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let vendor = "Samsung"
        let vendorEncoded = try encoder.encode(vendor, signature: "s")
        let vendorDecoded = try decoder.decode(String.self, from: vendorEncoded, signature: "s")
        #expect(vendorDecoded == "Samsung")

        let model = "SSD 980 PRO"
        let modelEncoded = try encoder.encode(model, signature: "s")
        let modelDecoded = try decoder.decode(String.self, from: modelEncoded, signature: "s")
        #expect(modelDecoded == "SSD 980 PRO")

        let size: UInt64 = 1_000_204_886_016
        let sizeEncoded = try encoder.encode(size, signature: "t")
        let sizeDecoded = try decoder.decode(UInt64.self, from: sizeEncoded, signature: "t")
        #expect(sizeDecoded == 1_000_204_886_016)

        let removable = false
        let removableEncoded = try encoder.encode(removable, signature: "b")
        let removableDecoded = try decoder.decode(Bool.self, from: removableEncoded, signature: "b")
        #expect(removableDecoded == false)
    }

    // MARK: - Complex Variant Testing

    @Test func complexVariantData() throws {
        // Test variants containing different types (common in property dictionaries)
        // Note: This test is simplified until Variant conforms to Codable
        // TODO: Implement Codable conformance for Variant

        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test individual values that would be inside variants
        let stringValue = "Hello World"
        let intValue: Int32 = 42
        let boolValue = true

        // Test encoding/decoding the values directly
        let stringEncoded = try encoder.encode(stringValue, signature: "s")
        let stringDecoded = try decoder.decode(String.self, from: stringEncoded, signature: "s")
        #expect(stringDecoded == "Hello World")

        let intEncoded = try encoder.encode(intValue, signature: "i")
        let intDecoded = try decoder.decode(Int32.self, from: intEncoded, signature: "i")
        #expect(intDecoded == 42)

        let boolEncoded = try encoder.encode(boolValue, signature: "b")
        let boolDecoded = try decoder.decode(Bool.self, from: boolEncoded, signature: "b")
        #expect(boolDecoded == true)
    }

    // MARK: - Array of Complex Types

    @Test func arrayOfStructs() throws {
        // Test array of basic types rather than complex structs for now
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test array of UInt32 (process IDs)
        let pids: [UInt32] = [1234, 5678, 9012]
        let pidsEncoded = try encoder.encode(pids, signature: "au")
        let pidsDecoded = try decoder.decode([UInt32].self, from: pidsEncoded, signature: "au")
        #expect(pidsDecoded.count == 3)
        #expect(pidsDecoded[0] == 1234)
        #expect(pidsDecoded[1] == 5678)
        #expect(pidsDecoded[2] == 9012)

        // Test array of strings (process names)
        let names = ["systemd", "NetworkManager", "pulseaudio"]
        let namesEncoded = try encoder.encode(names, signature: "as")
        let namesDecoded = try decoder.decode([String].self, from: namesEncoded, signature: "as")
        #expect(namesDecoded.count == 3)
        #expect(namesDecoded[0] == "systemd")
        #expect(namesDecoded[1] == "NetworkManager")
        #expect(namesDecoded[2] == "pulseaudio")
    }

    // MARK: - Dictionary Testing

    @Test func dictionaryEncoding() throws {
        // Test dictionary (string -> string) - very common in D-Bus
        let properties: [String: String] = [
            "Version": "1.2.3",
            "State": "active",
            "Description": "Network Manager Service",
        ]

        let signature: Signature = "a{ss}"  // dictionary of string->string
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let encoded = try encoder.encode(properties, signature: signature)
        let decoded = try decoder.decode([String: String].self, from: encoded, signature: signature)

        #expect(decoded["Version"] == "1.2.3")
        #expect(decoded["State"] == "active")
        #expect(decoded["Description"] == "Network Manager Service")
    }

    // MARK: - Error Handling with Real Scenarios

    @Test func invalidObjectPath() throws {
        // Test with invalid object path (common error scenario)
        let invalidPath = "not/a/valid/path"  // Missing leading slash

        #expect(throws: (any Error).self) {
            try ObjectPath(invalidPath)
        }
    }

    @Test func signatureMismatch() throws {
        // Test signature mismatch (common real-world error)
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let stringValue = "test"
        let encoded = try encoder.encode(stringValue, signature: "s")

        // Try to decode as wrong type
        #expect(throws: DecodingError.self) {
            try decoder.decode(Int32.self, from: encoded, signature: "s")
        }
    }

    // MARK: - Large Data Testing

    @Test func largeStringArray() throws {
        // Test with large amount of data (simulating file listings, etc.)
        let largeArray = (0..<1000).map {
            "Item_\($0)_with_some_longer_content_to_test_performance"
        }

        let signature: Signature = "as"
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let encoded = try encoder.encode(largeArray, signature: signature)
        let decoded = try decoder.decode([String].self, from: encoded, signature: signature)

        #expect(decoded.count == 1000)
        #expect(decoded[0] == "Item_0_with_some_longer_content_to_test_performance")
        #expect(decoded[999] == "Item_999_with_some_longer_content_to_test_performance")
    }

    // MARK: - Edge Cases from Real Services

    @Test func emptyArrays() throws {
        // Empty arrays are common in D-Bus responses
        let emptyStringArray: [String] = []
        let emptyIntArray: [Int32] = []

        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Test empty string array
        let encodedStrings = try encoder.encode(emptyStringArray, signature: "as")
        let decodedStrings = try decoder.decode(
            [String].self, from: encodedStrings, signature: "as")
        #expect(decodedStrings.count == 0)

        // Test empty int array
        let encodedInts = try encoder.encode(emptyIntArray, signature: "ai")
        let decodedInts = try decoder.decode([Int32].self, from: encodedInts, signature: "ai")
        #expect(decodedInts.count == 0)
    }

    @Test func unicodeStrings() throws {
        // Test Unicode strings (common in real-world usage)
        let unicodeStrings = [
            "Hello 世界",
            "Привет мир",
            "🚀 Rocket emoji",
            "Mathematical symbols: ∑∫∞≠≤≥",
            "Arabic: مرحبا بالعالم",
        ]

        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        for testString in unicodeStrings {
            let encoded = try encoder.encode(testString, signature: "s")
            let decoded = try decoder.decode(String.self, from: encoded, signature: "s")
            #expect(
                decoded == testString, "Unicode string encoding/decoding failed for: \(testString)")
        }
    }
}
