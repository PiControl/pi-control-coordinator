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

import FluentKit
import FluentSQLiteDriver
import Foundation
import Logging

struct PersistanceLayer {
    
    // MARK: - Static Properties
    
    nonisolated(unsafe) private static var stateDirectory: String?
    @MainActor
    private static var instance: PersistanceLayer?
    
    @MainActor
    public static func shared() throws -> PersistanceLayer {
        guard let instance else {
            instance = try PersistanceLayer(state: stateDirectory!)
            return instance!
        }
        return instance
    }
    
    
    // MARK: - Static Methods
    
    public static func configure(state directory: String) {
        PersistanceLayer.stateDirectory = directory
    }
    
    
    // MARK: - Public Properties
    
    public  let dbConnection: any Database
    
    
    // MARK: - Private Properties
    
    private let logger: Logger = Logger(label: "PersistanceLayer")
    private let threadCount = 100
    private let maxConnections = 10
    private let state: String
    private let eventLoopGroup: MultiThreadedEventLoopGroup
    private let databases: Databases
    private let migrator: Migrator

    
    // MARK: - Initialization
    
    private init(state directory: String) throws {
        self.state = directory
        
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: threadCount)
        
        let configuration = SQLiteConfiguration(
            storage: .file(path: self.state.appendingPathComponent("pi-control-coordinator.sqlite"))
        )
        
        let db = DatabaseConfigurationFactory.sqlite(
            configuration,
            maxConnectionsPerEventLoop: maxConnections
        )
        
        self.databases = Databases(threadPool: NIOThreadPool(numberOfThreads: threadCount), on: self.eventLoopGroup)
        self.databases.use(db, as: .sqlite)
        
        // Add migrations and models as needed
        let migrations = Migrations()
        migrations.add(DeviceModelV1())
        
        self.migrator = Migrator(
            databases: self.databases,
            migrations: migrations,
            logger: self.logger,
            on: self.eventLoopGroup.next()
        )
        
        // Run migrations
        try migrator.setupIfNeeded().wait()
        
        // Access the database for queries
        dbConnection = databases.database(.sqlite, logger: self.logger, on: eventLoopGroup.next())!
    }
}
