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

import ArgumentParser
import DBus

struct IntrospectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "introspect",
        abstract: "Introspect a remote object to get its XML interface description"
    )

    @OptionGroup()
    var globalOptions: DBusUtil.GlobalOptions

    @ArgumentParser.Argument(help: "Service name of the object")
    var serviceName: String

    @ArgumentParser.Argument(help: "Object path of the object")
    var objectPath: String

    func run() async throws {
        let connection = Connection()
        try await connection.connect(to: BusType(from: globalOptions.bus))

        let proxyObject = connection.proxyObject(
            serviceName: serviceName,
            objectPath: try ObjectPath(objectPath),
            interfaceName: "org.freedesktop.DBus.Introspectable"
        )

        guard let (signature, data) = try await proxyObject.introspect() else {
            throw IntrospectCommandError.introspectionFailed
        }

        let decoder = DBusDecoder()
        let xmlString = try decoder.decode(String.self, from: data, signature: signature)
        print(xmlString)
    }
}

enum IntrospectCommandError: Error {
    case introspectionFailed
}
