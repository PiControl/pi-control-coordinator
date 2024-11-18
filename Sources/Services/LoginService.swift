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
import PiControlRestMessages
import SQLite

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
        guard
            try await !Serve.globals.controllerRepository.controllers().isEmpty
        else {
            return try await handleOwnerRegistration(request: request, context: context)
        }
        
        if case let .basic(usrPwd) = authorizationScheme(of: request) {
            return try await handleLogin(basic: usrPwd)
        }
        if case let .bearer(token) = authorizationScheme(of: request) {
            return try await handleLogin(bearer: token)
        }
        
        return Response(status: .unauthorized)
    }
    
    private func handleLogin(basic: String? = nil, bearer: String? = nil) async throws -> Response {
        if basic == nil && bearer == nil {
            return try requestCredentials()
        }
        
        guard let auth = try await auth(from: basic, or: bearer),
              let deviceId = auth.deviceId
        else {
            return try requestCredentials("Device ID or password is invalid")
        }
        
        // Load the device from the DB
        var controller: Row?
        try await withEntity(Controller.self) { d in
            controller = try await Serve.globals.persistenceFirst(
                d.table()
                    .select(d.controllerId(), d.isOwner(), d.passwordHash(), d.salt())
                    .filter(d.controllerId() == deviceId)
            )
        }
        
        guard let controller else {
            return try requestCredentials("Device ID or password is invalid")
        }
        
        if let pwd = auth.password {
            if !(try PasswordHasher.verify(
                password: pwd, hash: controller.get(Controller.passwordHash())!,
                salt: controller.get(Controller.salt())!)) {
                
                return try requestCredentials("Device ID or password is invalid")
            }
        }
        
        let token = try await TokenUtils.createToken(for: deviceId, owner: controller.get(Controller.isOwner()))
        
        return Response(
            status: .ok,
            headers: HTTPFields(dictionaryLiteral: (.contentType, "application/json")),
            body: ResponseBody(
                byteBuffer: try LoginResponse(
                    result: .success,
                    message: "Owner created",
                    token: token,
                    mqttCredentials: await getMqttCredentials()
                ).encoded().byteBuffer
            )
        )
    }
    
    private func handleOwnerRegistration(request: Request, context: any RequestContext) async throws -> Response {
        guard
            case let .basic(value) = authorizationScheme(of: request),
            let (deviceId, password) = decodeDeviceIdAndPassword(value)
        else {
            return try requestCredentials()
        }
        
        guard
            let (hashedPassword, salt) = PasswordHasher.createHash(for: password)
        else {
            return try requestCredentials()
        }
        
        try await withEntity(Controller.self) { d in
            try await Serve.globals.persistenceRun(
                d.table().insert(
                    d.id() <- UUID(),
                    d.controllerId() <- deviceId,
                    d.isOwner() <- true,
                    d.passwordHash() <- hashedPassword,
                    d.salt() <- salt
                )
            )
        }
        
        // - create JWT token
        let token = try await TokenUtils.createToken(for: deviceId, owner: true)
        
        return Response(
            status: .ok,
            headers: HTTPFields(dictionaryLiteral: (.contentType, "application/json")),
            body: ResponseBody(
                byteBuffer: try LoginResponse(
                    result: .success,
                    message: "Owner created",
                    token: token,
                    mqttCredentials: await getMqttCredentials()
                ).encoded().byteBuffer
            )
        )
    }
    
    private func getMqttCredentials() async -> String {
        let mqttUsername = await Serve.globals.properties.security.mqtt.username
        let mqttPassword = await Serve.globals.properties.security.mqtt.password
        let mqttCredentials: String = {
            let credentials = "\(mqttUsername):\(mqttPassword)"
            let data = credentials.data(using: .utf8)
            
            return data!.base64EncodedString()
        }()
        
        return mqttCredentials
    }
    
    private func auth(from basic: String?, or bearer: String?) async throws -> (deviceId: String?, password: String?)? {
        if let bearer {
            let tokenPayload = try await TokenUtils.decodeToken(bearer)
            
            return (deviceId: tokenPayload.sub.value, password: nil)
        }
        if let basic {
            let (deviceId, password) = decodeDeviceIdAndPassword(basic)!
            
            return (deviceId: deviceId, password: password)
        }
        
        return nil
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
    
    private func decodeDeviceIdAndPassword(_ value: String) -> (deviceId: String, password: String)? {
        guard
            let data = Data(base64Encoded: value),
            let decodedString = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        
        let components = decodedString.split(separator: ":", maxSplits: 1)
        guard components.count == 2 else { return nil }
        
        return (deviceId: String(components[0]), password: String(components[1]))
    }
}

extension LoginService {
    
    private func requestCredentials(_ msg: String = "Send credentials") throws -> Response {
        return Response(
            status: .ok,
            headers: HTTPFields(dictionaryLiteral: (.contentType, "application/json")),
            body: ResponseBody(
                byteBuffer: try LoginResponse(
                    result: .sendCredentials,
                    message: "Send credentials"
                ).encoded().byteBuffer
            )
        )
    }
    
}
