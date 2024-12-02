//
//  DevicesRepository.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 24.11.24.
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

import Foundation
import SQLite

struct DevicesRepository {
    
    // MARK: - Initialization
    
    public init() {}
    
    
    // MARK: - Public Methods
    
    public func readAll() async throws -> [Row] {
        return try await withEntity(Device.self) { d in
            return try await Serve.globals.prepare(
                d.table().select(d.accesoryId(), d.id(), d.name())
            )
        }
    }
}
