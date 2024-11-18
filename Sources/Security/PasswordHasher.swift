//
//  PasswordHasher.swift
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

import CryptoSwift
import Foundation

struct PasswordHasher {
    
    static func createHash(for password: String) -> (hash: String, salt: String)? {
        // 1. Generate a random salt
        let salt = generateSalt()
        
        // 2. Combine password and salt
        let saltedPassword = password + salt
        
        // 3. Hash the salted password using SHA-256
        let hashData = saltedPassword.data(using: .utf8)?.sha3(.keccak512)
        let hashString = hashData!.base64EncodedString()
        
        return (hash: hashString, salt: salt)
    }
    
    private static func generateSalt() -> String {
        let saltLength = 32  // You can increase or decrease the length as desired
        var salt = ""
        for _ in 0..<saltLength {
            salt.append(String(format: "%02x", UInt8.random(in: 0...255)))
        }
        return salt
    }
    
    static func verify(password: String, hash: String, salt: String) -> Bool {
        let saltedPassword = password + salt
        let hashData = saltedPassword.data(using: .utf8)?.sha3(.keccak512)
        let computedHashString = hashData!.base64EncodedString()
        
        return computedHashString == hash
    }
    
}
