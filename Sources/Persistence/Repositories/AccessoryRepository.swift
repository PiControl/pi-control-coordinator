//
//  AccessoryRepository.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 18.11.24.
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

struct AccessoryRepository {
    
    // MARK: - Initialization
    
    public init() {}
    
    
    // MARK: - Public Methods
    
    public func upsert(accessoryId: String, name: String, authenticationMethod: Int) async throws {
        try await withEntity(Accessory.self) { a in
            try await Serve.globals.run(
                a.table().upsert(
                    a.id() <- accessoryId,
                    a.name() <- name,
                    a.authenticationMethod() <- a.AuthenticationMethod(rawValue: authenticationMethod)!,
                    onConflictOf: a.id()
                )
            )
        }
    }
    
    public func read(accessoryId: String) async throws -> Row? {
        return try await withEntity(Accessory.self) { a in
            return try await Serve.globals.pluck(
                a.table()
                    .select(a.id(), a.name(), a.authenticationMethod())
                    .filter(a.id() == accessoryId).limit(1)
            )
        }
    }
}
