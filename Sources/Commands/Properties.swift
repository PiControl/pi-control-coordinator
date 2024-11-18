//
//  Properties.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 12.11.24.
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
import Yaml

struct Properties {
    
    // MARK: - Error
    
    public enum Error: Swift.Error, LocalizedError {
        
        // MARK: - Errors
        
        case fileError(String)
        case propertyError(String, String)
        
        
        // MARK: - LocalizedError
        
        public var errorDescription: String? {
            switch self {
            case .fileError(let message):
                return message
                
            case.propertyError(let property, let message):
                return "\(property): \(message)"
            }
        }
    }
    
    // MARK: - Security Properties
    
    struct Security {
        
        // MARK: - Properties
        
        let jwtSigningKey: String
        
        
        // MARK: - MQTT Properties
        
        struct Mqtt {
            
            // MARK: - Properties
            
            let username: String
            let password: String
            
            
            // MARK: - Initialization
            
            fileprivate init(_ yaml: Yaml) throws {
                guard let un = yaml["username"].string else {
                    throw Properties.Error.propertyError("security.mqtt.username", "Property is not available")
                }
                self.username = un
                
                guard let pw = yaml["password"].string else {
                    throw Properties.Error.propertyError("security.mqtt.password", "Property is not available")
                }
                self.password = pw
            }
        }
        
        let mqtt: Mqtt
        
        
        // MARK: - Initialization
        
        fileprivate init(_ yaml: Yaml) throws {
            guard let signingKeyB64 = yaml["jwt-signing-key"].string else {
                throw Properties.Error.propertyError("security.jwt-signing-key", "Property is not available")
            }
            guard let decodedData = Data(base64Encoded: signingKeyB64) else {
                throw Properties.Error.propertyError("security.jwt-signing-key", "Decoding error")
            }
            guard let signingKey = String(data: decodedData, encoding: .utf8) else {
                throw Properties.Error.propertyError("security.jwt-signing-key", "Decoding error")
            }

            self.jwtSigningKey = signingKey
            self.mqtt = try Mqtt(yaml["mqtt"])
        }
        
    }
    
    public private(set) var security: Security!
    
    
    // MARK: - Initialization
    
    public init(from path: String) throws {
        try ensureOwnerOnlyAccess(path)
        
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let yaml = try Yaml.load(content)
        
        self.security = try Security(yaml["security"])
    }
    
    
    // MARK: - Private Methods
    
    private func ensureOwnerOnlyAccess(_ path: String) throws {
        var fileStat = stat()
        
        // Check if we can retrieve file information
        guard stat(path, &fileStat) == 0 else {
            throw Properties.Error.fileError("Unable to get file attributes for \(path)")
        }
        
        // Permissions are in the fileStat.st_mode field
        let ownerOnlyMask: mode_t = S_IRUSR | S_IWUSR | S_IXUSR  // rwx for owner
        let groupMask: mode_t = S_IRGRP | S_IWGRP | S_IXGRP      // --- for group
        let othersMask: mode_t = S_IROTH | S_IWOTH | S_IXOTH     // --- for others
        
        // Check if the file permissions match "only accessible by owner"
        let isOwnerOnly = (fileStat.st_mode & (groupMask | othersMask)) == 0
        let hasOwnerAccess = (fileStat.st_mode & ownerOnlyMask) != 0
        
        guard isOwnerOnly && hasOwnerAccess else {
            throw Properties.Error.fileError("\(path) is accessible to group or others")
        }
    }
}
