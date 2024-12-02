//
//  DevicesHandler.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 16.11.24.
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
import Logging
import MQTTNIO
import PiControlMqttMessages

struct DevicesHandler: MessageHandler {
    
    private static let logger: Logger = Logger(label: "DevicesHandler")
    
    static func handle(_ message: MQTTMessage) {
        Task {
            logger.info("Received ReadDevices message from topic '\(message.topic)'")
            logger.debug("Payload: \(message.payload.debugDescription)")
            
            do {
                guard let payload = message.payload.string else { return }
                let msg = try ReadDevices(jsonString: payload)
                
                let devices = try await Serve.globals.devicesRepository.readAll()
                
                var headers = MessageHeaders()
                headers.source = "coordinator/devices"
                var rspMsg = Devices()
                rspMsg.headers = headers
                rspMsg.devices = try await devices.asyncMap { row in
                    let acc = try await Serve.globals.accessoryRepository.read(accessoryId: row[Device.id()])
                    var dev = PiControlMqttMessages.Device()
                    
                    if let acc {
                        var msgAcc = PiControlMqttMessages.Accessory()
                        msgAcc.id = acc[Accessory.id()]
                        msgAcc.name = acc[Accessory.name()]
                        dev.accessory = msgAcc
                    }
                    
                    dev.id = row[Device.id()]
                    dev.name = row[Device.name()]
                    
                    return dev
                }
                
                try await Serve.globals.mqttClient.publish(
                    rspMsg.jsonString(),
                    to: "\(msg.headers.source)/devices")
                
            } catch {
                logger.error("Error while reading accessory: \(error)")
            }
        }
    }
    
}
