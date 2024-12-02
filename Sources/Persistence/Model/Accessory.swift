//
//  Accessory.swift
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

public class Accessory: Entity {
    
    // MARK: - AuthenticationMethod
    
    public enum AuthenticationMethod: Int, Codable, Value {
        
        // MARK: - Cases
        
        case none       = 0
        case pin        = 1
        case passwd     = 2
        case usrPasswd  = 3
        
        
        // MARK: - Properties
        
        public var rawValue: Int {
            switch self {
            case .none: return 0
            case .pin: return 1
            case .passwd: return 2
            case .usrPasswd: return 3
            }
        }
        
        
        // MARK: - Initialization
        
        public init?(rawValue: Int) {
            switch rawValue {
            case 0: self = .none
            case 1: self = .pin
            case 2: self = .passwd
            case 3: self = .usrPasswd
            default: return nil
            }
        }
        
        
        // MARK: - Value
        
        public static func fromDatatypeValue(_ datatypeValue: Int) throws -> Accessory.AuthenticationMethod {
            return AuthenticationMethod(rawValue: datatypeValue)!
        }
        
        public var datatypeValue: Int {
            return self.rawValue
        }
        
        public static var declaredDatatype: String {
            return "INTEGER"
        }
        
    }
    
    
    // MARK: - Static Methods
    
    public static func table() -> Table {
        return Table("accessories")
    }
    
    public static func id() -> SQLite.Expression<String> { SQLite.Expression<String>("id") }
    public static func name() -> SQLite.Expression<String> { SQLite.Expression<String>("name") }
    public static func authenticationMethod() -> SQLite.Expression<AuthenticationMethod> { SQLite.Expression<AuthenticationMethod>("authenticationMethod") }
    
}
