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

import MiniLexer
import Testing

@testable import DBus

@Suite("Signature lexer tests") struct SignatureLexerTests {
    @Test(
        "Signature lexer tokenizes correctly",
        arguments: [
            ("y", [SignatureToken.byte]),
            ("by", [SignatureToken.bool, SignatureToken.byte]),
            ("ai", [SignatureToken.array, SignatureToken.int32]),
            (
                "(ii)",
                [
                    SignatureToken.structStart, SignatureToken.int32, SignatureToken.int32,
                    SignatureToken.structEnd,
                ]
            ),
            ("w", [SignatureToken]()),
            (
                "a{ss}",
                [
                    SignatureToken.array, SignatureToken.dictEntryStart, SignatureToken.string,
                    SignatureToken.string, SignatureToken.dictEntryEnd,
                ]
            ),
        ])
    func correctSignatureLexerTokenization(input: String, expected: [SignatureToken]) throws {
        let lexer = TokenizerLexer<SignatureToken>(input: input)
        let got = lexer.allTokens()
        #expect(got == expected)
    }
}
