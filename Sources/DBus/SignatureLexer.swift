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

enum SignatureToken: String, TokenProtocol {
    case byte = "y"
    case bool = "b"
    case int16 = "n"
    case uint16 = "q"
    case int32 = "i"
    case uint32 = "u"
    case int64 = "x"
    case uint64 = "t"
    case double = "d"
    case string = "s"
    case objectPath = "o"
    case signature = "g"
    case variant = "v"
    case unixFD = "h"
    case array = "a"
    case dictEntryStart = "{"
    case dictEntryEnd = "}"
    case structStart = "("
    case structEnd = ")"
    case eof = ""

    static let eofToken = SignatureToken.eof

    var tokenString: String {
        return self.rawValue
    }

    func length(in lexer: Lexer) -> Int {
        return 1
    }

    static func tokenType(at lexer: Lexer) -> SignatureToken? {
        if lexer.safeIsNextChar(equalTo: "y") {
            return .byte
        }
        if lexer.safeIsNextChar(equalTo: "b") {
            return .bool
        }
        if lexer.safeIsNextChar(equalTo: "n") {
            return .int16
        }
        if lexer.safeIsNextChar(equalTo: "q") {
            return .uint16
        }
        if lexer.safeIsNextChar(equalTo: "i") {
            return .int32
        }
        if lexer.safeIsNextChar(equalTo: "u") {
            return .uint32
        }
        if lexer.safeIsNextChar(equalTo: "x") {
            return .int64
        }
        if lexer.safeIsNextChar(equalTo: "t") {
            return .uint64
        }
        if lexer.safeIsNextChar(equalTo: "d") {
            return .double
        }
        if lexer.safeIsNextChar(equalTo: "s") {
            return .string
        }
        if lexer.safeIsNextChar(equalTo: "o") {
            return .objectPath
        }
        if lexer.safeIsNextChar(equalTo: "g") {
            return .signature
        }
        if lexer.safeIsNextChar(equalTo: "v") {
            return .variant
        }
        if lexer.safeIsNextChar(equalTo: "h") {
            return .unixFD
        }
        if lexer.safeIsNextChar(equalTo: "a") {
            return .array
        }
        if lexer.safeIsNextChar(equalTo: "(") {
            return .structStart
        }
        if lexer.safeIsNextChar(equalTo: ")") {
            return .structEnd
        }
        if lexer.safeIsNextChar(equalTo: "{") {
            return .dictEntryStart
        }
        if lexer.safeIsNextChar(equalTo: "}") {
            return .dictEntryEnd
        }
        return nil
    }
}

typealias SignatureLexer = TokenizerLexer<FullToken<SignatureToken>>
