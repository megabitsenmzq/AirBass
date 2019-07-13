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

class RTSPResponse {
    private var response: [String]

    init() {
        response = ["RTSP/1.0 200 OK"]
    }

    func addChallengeResponse(_ challengeResponse: String) {
        response.append("Apple-Response: \(challengeResponse)")
    }

    func addSetupResponse(serverPort: Int = 6010, controlPort: Int = 6011) {
        response.append(
            "Transport: RTP/AVP/UDP;" +
            "server_port=\(serverPort);control_port=\(controlPort)")
        response.append("Session: 1")
    }

    func addSequenceNumber(_ number: Int) {
        response.append("CSeq: \(number)")
    }

    func build() -> Data {
        response.append("\r\n")
        return response.joined(separator: "\r\n").data(using: .utf8)!
    }
}
