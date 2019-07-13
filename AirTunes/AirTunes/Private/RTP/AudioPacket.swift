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

class AudioPacket {
    static func packet(from data: Data) -> RTPPacket? {
        var packet: RTPPacket?
        let type = getPayloadType(from: data)
        switch type {
            case 86:
                packet = RetransmittedAudioPacket(data: data)
            case 96:
                packet = NewAudioPacket(data: data)
            default:
                return nil
        }
        return packet
    }

    private static func getPayloadType(from data: Data) -> UInt8 {
        let payloadType: UInt8 = data.subdata(
            in: 1..<2).withUnsafeBytes { $0.load(as: UInt8.self) }
        let noMarkerBit: UInt8 = 127
        return payloadType & noMarkerBit
    }
}

class NewAudioPacket: RTPPacket {
    private let data: Data

    init?(data: Data) {
        self.data = data
        let headerLength = 12
        guard data.count >= headerLength else { return nil }
    }

    var sequenceNumber: UInt16 {
        let sequenceNumber: UInt16 = data.subdata(
            in: 2..<4).withUnsafeBytes { $0.load(as: UInt16.self) }
        return sequenceNumber.bigEndian
    }

    var timestamp: UInt32 {
        let timestamp: UInt32 = data.subdata(
            in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self) }
        return timestamp.bigEndian
    }

    var payloadData: Data {
        return data.subdata(in: 12..<data.count)
    }
}

class RetransmittedAudioPacket: RTPPacket {
    private let data: Data

    init?(data: Data) {
        self.data = data
        let headerLength = 16
        guard data.count >= headerLength else { return nil }
    }

    var sequenceNumber: UInt16 {
        let sequenceNumber: UInt16 = data.subdata(
            in: 6..<8).withUnsafeBytes { $0.load(as: UInt16.self) }
        return sequenceNumber.bigEndian
    }

    var timestamp: UInt32 {
        let timestamp: UInt32 = data.subdata(
            in: 8..<12).withUnsafeBytes { $0.load(as: UInt32.self) }
        return timestamp.bigEndian
    }

    var payloadData: Data {
        return data.subdata(in: 16..<data.count)
    }
}
