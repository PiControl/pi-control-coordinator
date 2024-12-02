//
//  DeviceRepository.swift
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

struct ControllerRepository {
    
    // MARK: - Initialization
    
    public init() {}
    
    
    // MARK: - Public Methods
    
    public func controllers() async throws -> [Row] {
        //return try await Device.query(on: Serve.di.persistenceLayer.dbConnection).all()
        var controlers = [Row]()
        
        try await withEntity(Controller.self) { c in
            controlers.append(contentsOf: try await Serve.globals.prepare(c.table()))
        }
        
        return controlers
    }
    
    public func owner() async throws -> Row? {
        var controller: Row? = nil
        
        try await withEntity(Controller.self) { c in
            controller = try await Serve.globals.pluck(c.table().filter(c.isOwner() == true))
        }

        return controller
    }
    
    public func create(deviceId: String, isOwner: Bool, passwordHash: String, salt: String) async throws {
        try await withEntity(Controller.self) { d in
            try await Serve.globals.run(
                d.table().insert(
                    d.id() <- UUID(),
                    d.controllerId() <- deviceId,
                    d.isOwner() <- true,
                    d.passwordHash() <- passwordHash,
                    d.salt() <- salt
                )
            )
        }
    }
    
}
