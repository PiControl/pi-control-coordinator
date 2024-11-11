//
//  PiControlCoordinator.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 09.11.24.
//  Copyright 2024 Thomas Bonk
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import ArgumentParser

@main
struct PiControlCoordinator: ParsableCommand {
    
    // MARK: - ParsableCommand
    
    static let configuration = CommandConfiguration(
        commandName: "pi-control-coordinator",
        abstract: "The central service of PiControl.",
        subcommands: [Serve.self],
        defaultSubcommand: Serve.self
    )
}