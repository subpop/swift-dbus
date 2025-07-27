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

/// The coding key used by the D-Bus encoder and decoder.
public struct DBusCodingKey {
    /// The string to use in a named collection (e.g. a string-keyed dictionary).
    public var stringValue: String

    /// The value to use in an integer-indexed collection (e.g. an int-keyed
    /// dictionary).
    public var intValue: Int?

    /// Creates a new key with the same string and int value as the provided key.
    /// - Parameter key: The key whose values to copy.
    public init(_ key: some CodingKey) {
        self.stringValue = key.stringValue
        self.intValue = key.intValue
    }
}

extension DBusCodingKey: CodingKey {
    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
