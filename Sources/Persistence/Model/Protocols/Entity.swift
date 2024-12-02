//
//  Entity.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 14.11.24.
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

protocol Entity {
    // Empty by design
}

func withEntity<T: Entity>(_ model: T.Type, _ lambda: (T.Type) async throws -> Void) async throws {
    try await lambda(T.self)
}

@discardableResult
func withEntity<T: Entity>(_ model: T.Type, _ lambda: (T.Type) async throws -> Int64) async throws -> Int64 {
    return try await lambda(T.self)
}

@discardableResult
func withEntity<T: Entity, R>(_ model: T.Type, _ lambda: (T.Type) async throws -> R?) async throws -> R? {
    return try await lambda(T.self)
}

@discardableResult
func withEntity<T: Entity, R>(_ model: T.Type, _ lambda: (T.Type) async throws -> [R]) async throws -> [R] {
    return try await lambda(T.self)
}
