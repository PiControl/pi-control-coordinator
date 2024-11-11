//
//  LoginService.swift
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
import Hummingbird

fileprivate enum AuthorizationScheme: Codable {
    
    // MARK: - Cases
    
    case basic(String)
    case bearer(String)
    case code(String)
    
    
    // MARK: - Intialization
    
    init?(_ rawKey: String, value: String) {
        switch rawKey.lowercased() {
        case "basic":
            self = .basic(value)
        case "bearer":
            self = .bearer(value)
        case "code":
            self = .code(value)
        default:
            return nil
        }
    }
}

struct LoginService {
    
    // MARK: - Static Properties
    
    public static let `default`: LoginService = { LoginService() }()
    
    
    // MARK: - Public Methods
    
    public func register<Context: RequestContext>(with router: Router<Context>) {
        router.post("/login", use: self.onLogin)
    }
    
    
    // MARK: - Private Methods
    
    private func onLogin(request: Request, context: any RequestContext) async throws -> Response {
        let owner = try await DeviceRepository.shared.owner()
        
        guard let authorizationScheme = self.authorizationScheme(of: request) else {
            return Response(
                status: .ok,
                headers: .init(dictionaryLiteral: (.contentType, "application/json")),
                body: ResponseBody(byteBuffer: ByteBufferAllocator().buffer(capacity: 0))
            )
        }
        
        return Response(status: .notFound)
    }
    
    private func authorizationScheme(of request: Request) -> AuthorizationScheme? {
        guard let authorizationHeaderValue: String = request.headers[.authorization] else {
            return nil
        }
        
        let values = authorizationHeaderValue.split(separator: " ", maxSplits: 1)
        guard values.count == 2 else {
            return nil
        }
        
        return AuthorizationScheme(String(values[0]), value: String(values[1]))
    }
}
