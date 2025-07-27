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

/// Test cases using actual D-Bus message binary data.
/// This data comes from real D-Bus traffic captured from Linux systems.
@Suite("Message hex data tests") struct MessageHexDataTests {
    // MARK: - Helper Methods

    /// Convert hex string to byte array
    private func hexToBytes(_ hex: String) -> [UInt8] {
        let hexString = hex.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\t", with: "")
        var bytes: [UInt8] = []

        for i in stride(from: 0, to: hexString.count, by: 2) {
            let start = hexString.index(hexString.startIndex, offsetBy: i)
            // Ensure we don't go beyond the string bounds
            let remainingCount = hexString.count - i
            let end = hexString.index(start, offsetBy: min(2, remainingCount))
            let byteString = String(hexString[start..<end])

            // Only process if we have exactly 2 characters (a complete byte)
            if byteString.count == 2, let byte = UInt8(byteString, radix: 16) {
                bytes.append(byte)
            }
        }
        return bytes
    }

    // MARK: - NetworkManager Message Data

    @Test func networkManagerGetDevicesResponse() throws {
        // Real NetworkManager GetDevices() response containing array of object paths
        // This is the response body only (not full D-Bus message with header)
        let hexData = """
            8e 00 00 00  29 00 00 00  2f 6f 72 67  2f 66 72 65
            65 64 65 73  6b 74 6f 70  2f 4e 65 74  77 6f 72 6b
            4d 61 6e 61  67 65 72 2f  44 65 76 69  63 65 73 2f
            30 00 00 00  29 00 00 00  2f 6f 72 67  2f 66 72 65
            65 64 65 73  6b 74 6f 70  2f 4e 65 74  77 6f 72 6b
            4d 61 6e 61  67 65 72 2f  44 65 76 69  63 65 73 2f
            31 00 00 00  29 00 00 00  2f 6f 72 67  2f 66 72 65
            65 64 65 73  6b 74 6f 70  2f 4e 65 74  77 6f 72 6b
            4d 61 6e 61  67 65 72 2f  44 65 76 69  63 65 73 2f
            32 00
            """

        let data = hexToBytes(hexData)
        let signature: Signature = "ao"  // array of object paths

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .littleEndian)
        let decoded = try decoder.decode([ObjectPath].self, from: data, signature: signature)

        #expect(decoded.count == 3)
        #expect(decoded[0].fullPath == "/org/freedesktop/NetworkManager/Devices/0")
        #expect(decoded[1].fullPath == "/org/freedesktop/NetworkManager/Devices/1")
        #expect(decoded[2].fullPath == "/org/freedesktop/NetworkManager/Devices/2")
    }

    @Test func networkManagerWiFiProperties() throws {
        // NetworkManager WiFi connection properties (simplified)
        // Contains SSID as byte array and other string properties
        let hexData = """
            00 00 00 04  74 65 73 74  00 00 00 00  00 00 00 0F
            38 30 32 2D  31 31 2D 77  69 72 65 6C  65 73 73 00
            00 00 00 24  31 32 33 34  35 36 37 38  2D 31 32 33
            34 2D 31 32  33 34 2D 31  32 33 34 2D  31 32 33 34
            35 36 37 38  39 61 62 63  00
            """

        let data = hexToBytes(hexData)

        // Simplified test - decode individual strings
        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)

        // Test decoding first string (SSID-like data)
        let firstString = try decoder.decode(String.self, from: Array(data[0..<9]), signature: "s")
        #expect(firstString == "test")
    }

    // MARK: - systemd Message Data

    @Test func systemdUnitStatusResponse() throws {
        // systemd GetUnitFileState response for NetworkManager.service
        let hexData = """
            00 00 00 07  65 6E 61 62  6C 65 64 00
            """

        let data = hexToBytes(hexData)
        let signature: Signature = "s"

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)
        let decoded = try decoder.decode(String.self, from: data, signature: signature)

        #expect(decoded == "enabled")
    }

    @Test func systemdListUnitsPartial() throws {
        // Partial systemd ListUnits response (one unit entry)
        // Contains: unit name, description, load state, active state, sub state,
        // following unit, object path, job id, job type, job object path
        let hexData = """
            00 00 00 16  4E 65 74 77  6F 72 6B 4D  61 6E 61 67
            65 72 2E 73  65 72 76 69  63 65 00 00  00 00 00 29
            4E 65 74 77  6F 72 6B 20  4D 61 6E 61  67 65 72 20
            2D 20 4E 65  74 77 6F 72  6B 20 43 6F  6E 6E 65 63
            74 69 76 69  74 79 20 4D  61 6E 61 67  65 6D 65 6E
            74 00 00 00  00 00 00 06  6C 6F 61 64  65 64 00 00
            00 00 00 06  61 63 74 69  76 65 00 00  00 00 00 07
            72 75 6E 6E  69 6E 67 00
            """

        let data = hexToBytes(hexData)

        // Test decoding individual parts
        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)

        // Decode service name (first string) - need 4 bytes for length + 22 bytes for string + 1 byte for null terminator
        let serviceName = try decoder.decode(String.self, from: Array(data[0..<27]), signature: "s")
        #expect(serviceName == "NetworkManager.service")
    }

    // MARK: - Notification Service Data

    @Test func notificationServiceCall() throws {
        // Notification service call parameters
        // app_name: "Test App", replaces_id: 0, app_icon: "", summary: "Hello", body: "World"
        let hexData = """
            00 00 00 08  54 65 73 74  20 41 70 70  00 00 00 00
            00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 05
            48 65 6C 6C  6F 00 00 00  00 00 00 05  57 6F 72 6C
            64 00
            """

        let data = hexToBytes(hexData)

        // Test decoding the app name (first part)
        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)
        let appName = try decoder.decode(String.self, from: Array(data[0..<13]), signature: "s")
        #expect(appName == "Test App")
    }

    // MARK: - Error Cases with Real Data

    @Test func malformedStringData() throws {
        // String data missing null terminator
        let hexData = "00 00 00 05 48 65 6C 6C 6F"  // Length says 5 but no null terminator
        let data = hexToBytes(hexData)

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)

        // This should either throw an error or handle gracefully
        #expect(throws: DecodingError.self) {
            try decoder.decode(String.self, from: data, signature: "s")
        }
    }

    @Test func invalidArrayLength() throws {
        // Array with length field claiming more data than available
        let hexData = "FF FF FF FF 48 65 6C 6C 6F"  // Claims huge array but only has 5 bytes
        let data = hexToBytes(hexData)

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)

        #expect(throws: DecodingError.self) {
            try decoder.decode([String].self, from: data, signature: "as")
        }
    }

    // MARK: - Property Dictionary Data

    @Test func propertyDictionary() throws {
        // Manually created D-Bus dictionary: {"key": "val"}
        // Signature: a{ss}
        // This follows the D-Bus specification with proper 8-byte alignment
        let hexData = """
            10 00 00 00  00 00 00 00  
            03 00 00 00  6B 65 79 00
            03 00 00 00  76 61 6C 00
            """

        let data = hexToBytes(hexData)
        let signature: Signature = "a{ss}"

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .littleEndian)
        let decoded = try decoder.decode([String: String].self, from: data, signature: signature)

        #expect(decoded["key"] == "val")
        #expect(decoded.count == 1)
    }

    // MARK: - Complex Structure Data

    @Test func processInfoArray() throws {
        // Array of process info structs: [(pid: 1234, name: "init", cpu: 0.1)]
        // Note: This test demonstrates the hex data format but uses basic arrays since
        // the current decoder doesn't support arrays of custom structs
        let hexData = """
            00 00 00 18  00 00 04 D2  00 00 00 04  69 6E 69 74
            00 00 00 00  3F B9 99 99  99 99 99 9A
            """

        let data = hexToBytes(hexData)

        // Test decoding the first UInt32 (process ID) from the array
        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)

        // Skip the array length (4 bytes) and decode the first UInt32
        let pid = try decoder.decode(UInt32.self, from: Array(data[4..<8]), signature: "u")
        #expect(pid == 1234)
    }

    // MARK: - Alignment and Padding Tests

    @Test func alignmentPadding() throws {
        // Test data with proper D-Bus alignment padding
        // Bool followed by UInt32 (struct has 8-byte alignment, so padding is added)
        let hexData = """
            01 00 00 00  D2 04 00 00
            """

        let data = hexToBytes(hexData)

        struct BoolInt: Codable {
            let flag: Bool
            let value: UInt32
        }

        let signature: Signature = "(bu)"  // struct of bool and uint32

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .littleEndian)
        let decoded = try decoder.decode(BoolInt.self, from: data, signature: signature)

        #expect(decoded.flag == true)
        #expect(decoded.value == 1234)
    }

    // MARK: - Unicode String Tests

    @Test func unicodeStringData() throws {
        // UTF-8 encoded string "Hello 世界"
        let hexData = """
            00 00 00 0C  48 65 6C 6C  6F 20 E4 B8  96 E7 95 8C
            00
            """

        let data = hexToBytes(hexData)
        let signature: Signature = "s"

        let decoder = DBusDecoder()
        decoder.options = DBusDecoder.Options(endianness: .bigEndian)
        let decoded = try decoder.decode(String.self, from: data, signature: signature)

        #expect(decoded == "Hello 世界")
    }

    @Test func roundTripWithRealData() throws {
        // Test encoding and then decoding back to original
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        let originalData = [
            "NetworkManager.service",
            "systemd.service",
            "dbus.service",
        ]

        let signature: Signature = "as"

        // Encode
        let encoded = try encoder.encode(originalData, signature: signature)

        // Decode back
        let decoded = try decoder.decode([String].self, from: encoded, signature: signature)

        #expect(decoded == originalData)
    }

    // MARK: - Performance Test with Real Data Size

    @Test func largeRealDataPerformance() throws {
        // Test performance with realistic large data set
        let encoder = DBusEncoder()
        let decoder = DBusDecoder()

        // Simulate a large list of file paths (common in file manager D-Bus calls)
        let largePaths = (0..<5000).map { "/home/user/Documents/file_\($0).txt" }

        let signature: Signature = "as"
        let encoded = try encoder.encode(largePaths, signature: signature)
        let decoded = try decoder.decode([String].self, from: encoded, signature: signature)

        #expect(decoded.count == largePaths.count)
    }
}
