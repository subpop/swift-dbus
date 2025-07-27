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

@Suite("Signature parser tests") struct SignatureParserTests {
    @Test(
        "Parses a signature successfully",
        arguments: [
            ("i", SignatureParser(elements: [.int32])),
            ("ii", SignatureParser(elements: [.int32, .int32])),
            ("ai", SignatureParser(elements: [.array(.int32)])),
            ("a{ss}", SignatureParser(elements: [.dictionary(.string, .string)])),
            (
                "aya{sy}", SignatureParser(elements: [.array(.byte), .dictionary(.string, .byte)])
            ),
            ("(i)", SignatureParser(elements: [.struct([.int32])])),
            ("(ii)", SignatureParser(elements: [.struct([.int32, .int32])])),
            (
                "(b(i))", SignatureParser(elements: [.struct([.bool, .struct([.int32])])])
            ),
            ("()", SignatureParser(elements: [.struct([])])),
            (
                "((ii)(ii))",
                SignatureParser(elements: [
                    .struct([.struct([.int32, .int32]), .struct([.int32, .int32])])
                ])
            ),
            ("((ii)b)", SignatureParser(elements: [.struct([.struct([.int32, .int32]), .bool])])),
            ("(b(i)y)", SignatureParser(elements: [.struct([.bool, .struct([.int32]), .byte])])),
            ("i(i)", SignatureParser(elements: [.int32, .struct([.int32])])),
            (
                "(ba{ss})",
                SignatureParser(elements: [.struct([.bool, .dictionary(.string, .string)])])
            ),
            (
                "a{sa{ss}}",
                SignatureParser(elements: [.dictionary(.string, .dictionary(.string, .string))])
            ),
            (
                "a{(ii)s}",
                SignatureParser(elements: [.dictionary(.struct([.int32, .int32]), .string)])
            ),
            (
                "a{a{ss}s}",
                SignatureParser(elements: [.dictionary(.dictionary(.string, .string), .string)])
            ),
        ]) func parseSignature(input: String, want: SignatureParser) throws
    {
        let got = try SignatureParser(signature: input)
        #expect(got.signature == want.signature)
    }

}
