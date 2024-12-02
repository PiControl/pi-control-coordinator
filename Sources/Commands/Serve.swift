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
import MQTTNIO
import SQLite

struct Serve: AsyncParsableCommand {
    
    // MARK: - Dependency Injector
    
    actor Globals {
        
        // MARK: - Properties
        
        public private(set) var properties: Properties!
        public private(set) var persistenceLayer: PersistenceLayer!
        public private(set) var accessoryRepository: AccessoryRepository!
        public private(set) var controllerRepository: ControllerRepository!
        public private(set) var devicesRepository: DevicesRepository!
        public private(set) var mqttClient: MQTTClient!
        
        
        // MARK: - Setters
        
        public func setProperties(_ properties: Properties) {
            self.properties = properties
        }
        
        public func setPersistenceLayer(_ persistenceLayer: PersistenceLayer) {
            self.persistenceLayer = persistenceLayer
        }
        
        public func setAccessoryRepository(_ accessoryRepository: AccessoryRepository) {
            self.accessoryRepository = accessoryRepository
        }
        public func setControllerRepository(_ controllerRepository: ControllerRepository) {
            self.controllerRepository = controllerRepository
        }
        
        public func setDevicesRepository(_ devicesRepository: DevicesRepository) {
            self.devicesRepository = devicesRepository
        }
        
        public func setMqttClient(_ mqttClient: MQTTClient) {
            self.mqttClient = mqttClient
        }
        
    }
    
    
    // MARK: - Static Properties
    
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Start the Pi Control Coordinator web server."
    )
    
    public static let globals = Globals()
    
    
    // MARK: - Options
    
    @Option(name: .shortAndLong, help: "The directory where the state shall be stored.")
    var state: String = "/var/lib/pi-control"
    
    @Option(name: .shortAndLong, help: "The configuration file path.")
    var config: String = "/etc/pi-control/pi-control-coordinator.yaml"
    
    @Option(name: .shortAndLong, help: "The hostname under which the server is serving.")
    var hostname: String = ProcessInfo.processInfo.hostName
    
    @Option(name: .long, help: "The name with which this service is advertised")
    var serviceName: String = "PiControl"
    
    @Option(name: .shortAndLong, help: "The port on which the server should listen.")
    var port: Int = 8080
    
    
    // MARK: - Entry Point
    
    func run() async throws {        
        do {
            await Serve.globals.setProperties(try Properties(from: self.config))
            await Serve.globals.setPersistenceLayer(try PersistenceLayer(self.state, migrations: ModelMigrations()))
            await Serve.globals.setAccessoryRepository(AccessoryRepository())
            await Serve.globals.setControllerRepository(ControllerRepository())
            await Serve.globals.setDevicesRepository(DevicesRepository())
            await Serve.globals.setMqttClient(MQTTClient(
                configuration: .init(
                    target: .host("localhost", port: 1883),
                    clientId: self.serviceName,
                    credentials: .init(
                        username: Serve.globals.properties.security.mqtt.username,
                        password: Serve.globals.properties.security.mqtt.password)))
            )
            try await Serve.globals.mqttClient.connect()
            
            await Serve.globals.mqttClient.whenMessage(
                forTopic: "coordinator/register-accessory",
                RegisterAccessoryHandler.handle)
            await Serve.globals.mqttClient.whenMessage(
                forTopic: "coordinator/register-device",
                RegisterDeviceHandler.handle)
            await Serve.globals.mqttClient.whenMessage(
                forTopic: "coordinator/accessories",
                AccessoriesHandler.handle)
            await Serve.globals.mqttClient.whenMessage(
                forTopic: "coordinator/devices",
                DevicesHandler.handle)
            try await Serve.globals.mqttClient.subscribe(to: "coordinator/#", qos: .exactlyOnce)
        } catch {
            fatalError(error.localizedDescription)
        }
        
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
        
        do {
            try await app.runService()
        } catch {
            print("Failed to start server: \(error)")
        }
        
        advertiser.stop()
    }
}
