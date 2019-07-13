// Copyright 2017 Jenghis
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

class BonjourService {
    private var service: NetService!
    private let name: String
    private let hardwareAddress: [UInt8]

    init(name: String, hardwareAddress: [UInt8]) {
        self.hardwareAddress = hardwareAddress
        self.name = hardwareAddress.reduce(
            "", {$0 + String(format: "%02X", $1)}) + "@\(name)"
    }
    
    func publish() {
        createService(onPort: ServiceProperties.rtspPort)
        service.publish()
    }

    private func createService(onPort port: Int32) {
        service = NetService(
            domain: "", type: ServiceProperties.type, name: name, port: port)
        service.setTXTRecord(ServiceProperties.txtRecord)
    }
}

// Necessary info for AirPlay to find our service
private enum ServiceProperties {
    static let type = "_raop._tcp."
    static let rtspPort: Int32 = 5001
    static var txtRecord: Data {
        var txtRecord = [String: Data]()
        let txtFields = [
            "et": "1", "sf": "0x4", "tp": "UDP",
            "vn": "3", "cn": "1", "md": "0,1,2"
        ]
        txtFields.forEach({txtRecord[$0.0] = $0.1.data(using: .utf8)})
        return NetService.data(fromTXTRecord: txtRecord)
    }
}
