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

@Suite("Object path tests") struct ObjectPathTests {
    @Test(
        "Creates an object path successfully",
        arguments: [
            ("/foo", ObjectPath(components: ["foo"])),
            ("/", ObjectPath(components: [])),
            ("/foo/bar/baz", ObjectPath(components: ["foo", "bar", "baz"])),
        ])
    func createObjectPath(input: String, want: ObjectPath) throws {
        let got = try ObjectPath(input)
        #expect(got == want)
        #expect(got.fullPath == input)
    }
}
