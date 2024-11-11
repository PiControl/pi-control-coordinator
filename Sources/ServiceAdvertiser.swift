//
//  ServiceAdvertiser.swift
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

import NetService

class ServiceAdvertiser {
    private var netService: NetService?

    init(serviceName: String, port: Int) {
        // Set up NetService to advertise an HTTP service over TCP
        netService = NetService(domain: "local.", type: "_pictrl._tcp.", name: serviceName, port: Int32(port))
        netService?.delegate = self
    }

    func start() {
        netService?.publish()
    }

    func stop() {
        netService?.stop()
    }
}

extension ServiceAdvertiser: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        print("HTTP service published: \(sender)")
    }

    private func netService(_ sender: NetService, didNotPublish errorDict: [String : Int]) {
        print("Failed to publish HTTP service: \(errorDict)")
    }

    func netServiceDidStop(_ sender: NetService) {
        print("HTTP service stopped: \(sender)")
    }
}
