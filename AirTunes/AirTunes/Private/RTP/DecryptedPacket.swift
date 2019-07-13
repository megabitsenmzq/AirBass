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
import CommonCrypto

class DecryptedPacket: RTPPacket, CustomDebugStringConvertible {
    let sequenceNumber: UInt16
    let timestamp: UInt32
    let payloadData: Data

    init(packet: RTPPacket, key: Data, iv: Data) {
        self.sequenceNumber = packet.sequenceNumber
        self.timestamp = packet.timestamp
        self.payloadData = DecryptedPacket.decrypt(
            packet.payloadData, withKey: key, iv: iv)
    }

    var debugDescription: String {
        return "\(sequenceNumber)"
    }

    private static func decrypt(
        _ payloadData: Data, withKey key: Data, iv: Data) -> Data
    {
        var cryptor: CCCryptorRef? = nil
        let length = payloadData.count
        var output = [UInt8](repeating: 0, count: length)
        var moved = 0
		CCCryptorCreate(UInt32(kCCDecrypt), 0, 0, [UInt8](key), 16, [UInt8](iv), &cryptor)
		CCCryptorUpdate(cryptor, [UInt8](payloadData), length, &output, output.count, &moved)
        var decrypted = Data(output[0..<moved])

        // Remaining data is plain-text
        let remaining = decrypted.count..<length
        decrypted.append(payloadData.subdata(in: remaining))

        CCCryptorRelease(cryptor)
        return decrypted
    }
}
