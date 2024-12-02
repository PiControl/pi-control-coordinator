//
//  RegisterAccessoryHandler.swift
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
import SQLite

struct RegisterAccessoryHandler: MessageHandler, Sendable {
    
    private static let logger: Logger = Logger(label: "RegisterAccessoryHandler")
    
    static func handle(_ message: MQTTMessage) {
        Task {
            logger.info("Received RegisterAccessory message from topic '\(message.topic)'")
            logger.debug("Payload: \(message.payload.debugDescription)")
            
            do {
                guard let payload = message.payload.string else { return }
                let msg =
                    try RegisterAccessory(jsonString: payload)

                try await Serve.globals.accessoryRepository.upsert(
                    accessoryId: msg.id,
                    name: msg.name,
                    authenticationMethod: msg.authenticationMethod.rawValue)
            } catch {
                logger.error("Error while registering accessory: \(error)")
            }
        }
    }
    
}
