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

struct SignatureParser {
    var signature: [SignatureElement] = []

    init(signature: String) throws {
        var lexer = SignatureLexer(input: signature)
        var state = State.value
        while state != State.end {
            try self.parse(lexer: &lexer, state: &state)
        }
    }

    init(elements: [SignatureElement]) {
        self.signature = elements
    }

    private func readValue(token: FullToken<SignatureToken>) throws -> SignatureElement {
        switch token.tokenType {
        case .byte: return .byte
        case .bool: return .bool
        case .int16: return .int16
        case .uint16: return .uint16
        case .int32: return .int32
        case .uint32: return .uint32
        case .int64: return .int64
        case .uint64: return .uint64
        case .double: return .double
        case .string: return .string
        case .objectPath: return .objectPath
        case .signature: return .signature
        case .variant: return .variant
        case .unixFD: return .unixFD
        default: throw SignatureParserError(value: token.tokenString, kind: .unexpectedToken)
        }
    }

    private func readArray(lexer: inout SignatureLexer) throws -> SignatureElement {
        let token = lexer.nextToken()
        let value: SignatureElement

        switch token.tokenType {
        case .structStart:
            value = try readStruct(lexer: &lexer)
        case .dictEntryStart:
            value = try readDictionary(lexer: &lexer)
        default:
            value = try readValue(token: token)
        }

        return .array(value)
    }

    private func readDictionary(lexer: inout SignatureLexer) throws -> SignatureElement {
        lexer.skipToken()  // Skip the initial '{' token

        // Read key (can be complex type)
        let key = try readAnyType(lexer: &lexer)

        // Read value (can be complex type)
        let value = try readAnyType(lexer: &lexer)

        lexer.skipToken()  // Skip the closing '}' token
        return .dictionary(key, value)
    }

    private func readAnyType(lexer: inout SignatureLexer) throws -> SignatureElement {
        let token = lexer.nextToken()
        switch token.tokenType {
        case .array:
            // Check if this is a dictionary (a{...}) or a regular array (a...)
            if lexer.token().tokenType == .dictEntryStart {
                return try readDictionary(lexer: &lexer)
            } else {
                let elementType = try readAnyType(lexer: &lexer)
                return .array(elementType)
            }
        case .structStart:
            return try readStruct(lexer: &lexer)
        case .dictEntryStart:
            return try readDictionary(lexer: &lexer)
        default:
            return try readValue(token: token)
        }
    }

    private func readStruct(lexer: inout SignatureLexer) throws -> SignatureElement {
        var substring = ""
        var elements: [SignatureElement] = []
        while !lexer.isEof {
            let token = lexer.nextToken()
            switch token.tokenType {
            case .structStart:
                let parser = try SignatureParser(signature: substring)
                elements += parser.signature
                substring = ""
                let element = try readStruct(lexer: &lexer)
                elements.append(element)
            case .structEnd:
                let parser = try SignatureParser(signature: substring)
                elements += parser.signature
                return .struct(elements)
            default:
                substring.append(String(token.value))
            }
        }
        throw SignatureParserError.init(value: String(lexer.token().value), kind: .unexpectedToken)
    }

    private mutating func parse(lexer: inout SignatureLexer, state: inout State) throws {
        switch state {
        case .value:
            let token = lexer.nextToken()
            switch token.tokenType {
            case .byte, .bool, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .string,
                .objectPath, .signature, .variant, .unixFD:
                let element = try readValue(token: token)
                signature.append(element)
                state = .value
            case .array:
                switch lexer.token().tokenType {
                case .dictEntryStart:
                    state = .dictionary
                default:
                    state = .array
                }
            case .structStart:
                state = .struct
            case .eof:
                state = .end
            default:
                // TODO: Error
                state = .end
                break
            }
        case .array:
            let element = try readArray(lexer: &lexer)
            signature.append(element)
            state = .value
        case .dictionary:
            let element = try readDictionary(lexer: &lexer)
            signature.append(element)
            state = .value
        case .struct:
            let element = try readStruct(lexer: &lexer)
            signature.append(element)
            state = .value
        case .end:
            return
        }
    }
}

extension SignatureParser {
    private enum State {
        case value
        case array
        case dictionary
        case `struct`
        case end
    }
}

struct SignatureParserError: Error {
    enum ErrorKind {
        case unexpectedToken
    }

    let value: String
    let kind: ErrorKind
}
