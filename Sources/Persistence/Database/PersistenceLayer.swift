//
//  PersistanceLayer.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 10.11.24.
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

struct PersistenceLayer {
    
    // MARK: - Public Properties
    
    public private(set) var db: Connection
    
    
    // MARK: - Private Properties
    
    private let state: String

    
    // MARK: - Initialization
    
    public init(_ state: String, migrations: Migrations) async throws {
        self.state = state
        self.db = try Connection(state.appendingPathComponent("pi-control-coordinator.sqlite"))
        
        for m in migrations.migrations() {
            try! await m.migrate(db)
        }
    }
}

extension Serve.Globals {
    // MARK: - Persistence Methods
    
    @discardableResult
    public func run(_ query: Insert) throws -> Int64 {
        return try self.persistenceLayer.db.run(query)
    }
    
    public func pluck(_ query: any QueryType) throws -> Row? {
        return try self.persistenceLayer.db.pluck(query)
    }
    
    public func prepare(_ query: QueryType) throws -> [Row] {
        return Array(try self.persistenceLayer.db.prepare(query))
    }
}

extension Row: @unchecked @retroactive Sendable {
    
}

