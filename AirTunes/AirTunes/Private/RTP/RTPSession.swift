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

class RTPSession: NSObject, GCDAsyncUdpSocketDelegate {
    private let manager: SessionManager
    private let udpQueue = DispatchQueue(label: "UDPQueue")
    private var lastSequenceNumber: UInt16? = nil
    private var serverSocket: GCDAsyncUdpSocket!
    private var controlSocket: GCDAsyncUdpSocket!
    private var controlAddress: Data?

    var key = Data()
    var iv = Data()

    init(manager: SessionManager) {
        self.manager = manager
    }

	func udpSocket(_ sock: GCDAsyncUdpSocket,
				   didReceive data: Data,
				   fromAddress address: Data,
				   withFilterContext filterContext: Any?) {
        if sock.localPort() == RTPSessionConstants.controlPort {
            controlAddress = address
        }
        processPacketData(data)
    }

    func start() {
        createSockets()
        try? controlSocket.beginReceiving()
        try? serverSocket.beginReceiving()
    }

    func reset() {
        udpQueue.async { self.lastSequenceNumber = nil }
    }

    private func createSockets() {
        serverSocket = GCDAsyncUdpSocket(delegate: self,
                                         delegateQueue: udpQueue)
        controlSocket = GCDAsyncUdpSocket(delegate: self,
                                          delegateQueue: udpQueue)
        try? serverSocket.bind(toPort: RTPSessionConstants.serverPort)
        try? controlSocket.bind(toPort: RTPSessionConstants.controlPort)
    }

    private func processPacketData(_ data: Data) {
        guard let audioPacket = AudioPacket.packet(from: data) else { return }
        if audioPacket is NewAudioPacket { handleNewAudioPacket(audioPacket) }
        let decryptedPacket = DecryptedPacket(
            packet: audioPacket, key: key, iv: iv)
        manager.add(decryptedPacket)
    }

    private func handleNewAudioPacket(_ packet: RTPPacket) {
        handleMissingPackets(for: packet)
        updateSequenceNumber(with: packet)
    }

    private func handleMissingPackets(for packet: RTPPacket) {
        guard let lastSequenceNumber = lastSequenceNumber else { return }
        let currentSequenceNumber = lastSequenceNumber &+ 1
        guard packet.sequenceNumber != currentSequenceNumber else { return }
        let missingCount = Int(packet.sequenceNumber &- currentSequenceNumber)
        let shouldAttemptRetransmit = (controlAddress != nil
            && missingCount < RTPSessionConstants.retransmitLimit)
        if !shouldAttemptRetransmit { return }
        retransmitPacketSequenceStarting(at: currentSequenceNumber,
                                         count: missingCount)
        #if DEBUG
            print(
                "Retransmit: \(currentSequenceNumber)",
                "Packets: \(missingCount)",
                "Current: \(packet.sequenceNumber)",
                "Last: \(lastSequenceNumber)"
            )
        #endif
    }

    private func updateSequenceNumber(with packet: RTPPacket) {
        if lastSequenceNumber == nil {
            manager.setSequenceNumber(packet.sequenceNumber)
            lastSequenceNumber = packet.sequenceNumber
        }
        let packetInterval = packet.sequenceNumber &- lastSequenceNumber!
        let isPacketNewer = packetInterval < (1 << 15)
        if isPacketNewer { lastSequenceNumber = packet.sequenceNumber }
    }

    private func retransmitPacketSequenceStarting(at sequenceNumber: UInt16,
                                                  count: Int) {
        var sequenceNumber = sequenceNumber.bigEndian
        var count = UInt16(count).bigEndian
        let rtpHeader: [UInt8] = [128, 213, 0, 1]
        var request = Data(rtpHeader)
        withUnsafePointer(to: &sequenceNumber) { request.append(UnsafeBufferPointer(start: $0, count: 1)) }
        withUnsafePointer(to: &count) { request.append(UnsafeBufferPointer(start: $0, count: 1)) }
        controlSocket.send(
            request, toAddress: controlAddress!, withTimeout: 5, tag: 0)
    }
}

enum RTPSessionConstants {
    static let retransmitLimit = 128
    static let serverPort: UInt16 = 6010
    static let controlPort: UInt16 = 6011
}
