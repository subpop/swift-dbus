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

struct GetPropertyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-property",
        abstract: "Get a property from a remote object"
    )

    @OptionGroup()
    var globalOptions: DBusUtil.GlobalOptions

    @ArgumentParser.Argument(help: "Service name of the object")
    var serviceName: String

    @ArgumentParser.Argument(help: "Object path of the object")
    var objectPath: String

    @ArgumentParser.Argument(help: "Interface of the object")
    var interface: String

    @ArgumentParser.Argument(help: "Property name")
    var propertyName: String

    func run() async throws {
        let connection = Connection()
        try await connection.connect(to: BusType(from: globalOptions.bus))

        let proxyObject = connection.proxyObject(
            serviceName: serviceName,
            objectPath: try ObjectPath(objectPath),
            interfaceName: interface
        )

        guard let (signature, property) = try await proxyObject.getProperty(propertyName) else {
            throw GetPropertyCommandError.propertyNotFound(propertyName)
        }

        let decoder = DBusDecoder()
        let result = try decoder.decode(Variant.self, from: property, signature: signature)
        print(result.value.anyValue)
    }
}

enum GetPropertyCommandError: Error {
    case propertyNotFound(String)
}
