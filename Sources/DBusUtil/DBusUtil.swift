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

@main
struct DBusUtil: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for interacting with D-Bus",
        subcommands: [
            CallCommand.self,
            EchoService.self,
            EmitCommand.self,
            GetPropertyCommand.self,
            IntrospectCommand.self,
            ListCommand.self,
            SetPropertyCommand.self,
            WaitCommand.self,
        ]
    )
}

extension DBusUtil {
    struct GlobalOptions: ParsableArguments {
        enum BusType: String, ExpressibleByArgument {
            case session
            case system
        }

        @Option(name: .shortAndLong, help: "Connect to the specified bus")
        var bus: BusType = .session
    }
}

extension DBus.BusType {
    /// Convenience initializer to create a `DBusBusType` from a
    /// `DBusUtil.GlobalOptions.BusType`.
    init(from: DBusUtil.GlobalOptions.BusType) {
        switch from {
        case .session:
            self = .session
        case .system:
            self = .system
        }
    }
}
