//
//  Serve.swift
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

import ArgumentParser
import Foundation
import Hummingbird

struct Serve: ParsableCommand {
    
    // MARK: - Static Properties
    
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Start the Pi Control Coordinator web server."
    )
    
    
    // MARK: - Options
    
    @Option(name: .shortAndLong, help: "The directory where the state shall be stored.")
    var state: String = "/var/lib/pi-control"
    
    @Option(name: .shortAndLong, help: "The hostname under which the server is serving.")
    var hostname: String = ProcessInfo.processInfo.hostName
    
    @Option(name: .long, help: "The name with which this service is advertised")
    var serviceName: String = "PiControl"
    
    @Option(name: .shortAndLong, help: "The port on which the server should listen.")
    var port: Int = 8080
    
    
    // MARK: - Entry Point
    
    func run() throws {
        // Configure the DB instance
        PersistanceLayer.configure(state: self.state)
        
        // create router and add services
        let router = Router()
        
        LoginService.default.register(with: router)
        
        // create application using router
        let app = Application(
            router: router,
            configuration: .init(
                address: .hostname(self.hostname, port: self.port),
                serverName: self.hostname
            )
        )
        
        // Advertise this service
        let advertiser = ServiceAdvertiser(serviceName: self.serviceName, port: self.port)
        advertiser.start()
        
        // run hummingbird application
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                try await app.runService()
            } catch {
                print("Failed to start server: \(error)")
            }
            semaphore.signal()
        }
        // Wait for the server task to complete
        semaphore.wait()
        
        advertiser.stop()
    }
}
