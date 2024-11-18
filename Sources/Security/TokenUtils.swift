//
//  TokenUtils.swift
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
import JWTKit

struct TokenPayload: JWTPayload {
    
    // MARK: - Proeprties

    var sub: SubjectClaim           // DeviceID is the subject
    var exp: ExpirationClaim
    var owner: BoolClaim            // Determines if the device is the owner's
    
    
    // MARK: - JWTPayload
    
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.exp.verifyNotExpired()
    }
    
}

struct TokenUtils {
    
    static func createToken(for deviceId: String, owner: Bool) async throws -> String {
        // Signs and verifies JWTs
        let keys = JWTKeyCollection()
        
        // Registers an HS256 (HMAC-SHA-256) signer.
        await keys.add(
            hmac: .init(from: Serve.globals.properties.security.jwtSigningKey),
            digestAlgorithm: .sha512,
            kid: "jwt-signing-key"
        )
        
        // Create the payload
        let payload = TokenPayload(
            sub: .init(value: deviceId),
            exp: .init(value: .distantFuture),
            owner: .init(value: owner)
        )
        
        let jwt = try await keys.sign(payload, kid: "jwt-signing-key")
        
        return jwt
    }
    
    static func decodeToken(_ token: String) async throws -> TokenPayload {
        // Signs and verifies JWTs
        let keys = JWTKeyCollection()
        
        // Registers an HS256 (HMAC-SHA-256) signer.
        await keys.add(
            hmac: .init(from: Serve.globals.properties.security.jwtSigningKey),
            digestAlgorithm: .sha512,
            kid: "jwt-signing-key"
        )
        
        // Parse the JWT, verify its signature and decode its content
        let token = try await keys.verify(token, as: TokenPayload.self)
        return token
    }
    
}
