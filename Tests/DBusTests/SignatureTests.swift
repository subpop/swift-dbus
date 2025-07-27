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

@Suite("Signature tests") struct SignatureTests {
    @Test(
        "Creates a signature from a raw value",
        arguments: ["i", "ii", "a{ss}", "ayai", "(i)", "(ii)", "b(ii)"])
    func createSignatureFromRawValue(input: String) throws {
        let got = Signature(rawValue: input)
        #expect(got?.rawValue == input)
    }

    @Test(
        "Signatures are equal",
        arguments: [
            ("y", Signature(elements: [.byte])),
            ("ay", Signature(elements: [.array(.byte)])),
            ("(bb)", Signature(elements: [.struct([.bool, .bool])])),
        ])
    func signatureEquality(input: String, want: Signature) throws {
        let got = Signature(rawValue: input)
        #expect(got != nil)
        #expect(got! == want)
    }

    @Test("Signatures are expressible by string literal")
    func signatureExpressibleByStringLiteral() throws {
        let got: Signature = "y"
        #expect(got == Signature(elements: [.byte]))
    }

    @Test("Creates a D-Bus header signature")
    func createDBusHeaderSignature() throws {
        // Test individual components first
        let simpleComponents = ["y", "u", "v"]
        for component in simpleComponents {
            let sig = Signature(rawValue: component)
            #expect(sig != nil, "Simple component '\(component)' should be parseable")
        }

        // Test struct with variant
        let structSig = Signature(rawValue: "(yv)")
        #expect(structSig != nil, "Struct signature '(yv)' should be parseable")

        // Test array of struct
        let arraySig = Signature(rawValue: "a(yv)")
        #expect(arraySig != nil, "Array of struct signature 'a(yv)' should be parseable")

        // Test combinations
        let components = ["yyyy", "uu", "a(yv)"]
        for component in components {
            let sig = Signature(rawValue: component)
            #expect(sig != nil, "Component '\(component)' should be parseable")
        }

        // Test the full D-Bus header signature
        let headerSig = "yyyyuua(yv)"
        let signature = Signature(rawValue: headerSig)
        #expect(signature != nil, "D-Bus header signature should be parseable")
        if let sig = signature {
            #expect(sig.rawValue == headerSig)
        }
    }
}
