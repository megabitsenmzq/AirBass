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
import AudioToolbox

class AudioSession {
    private var callbackQueue = DispatchQueue(label: "CallbackQueue")
    private var playerState = PlayerState()
    private let manager: SessionManager

    init(manager: SessionManager) {
        self.manager = manager
    }

    func start() {
        createAudioQueue(
            for: playerState, callbackQueue: callbackQueue) { (queue, buffer) in
                self.handleOutputBuffer(playerState: self.playerState,
                                        queue: queue,
                                        buffer: buffer)}
        setMagicCookie(for: playerState.queue)
        createAudioBuffers(for: playerState.queue,
                           count: playerState.bufferCount)
    }

    func add(_ packet: RTPPacket) {
        callbackQueue.async { self.handlePacket(packet) }
    }

    func setSequenceNumber(_ sequenceNumber: UInt16) {
        callbackQueue.async {
            self.playerState.readIndex = sequenceNumber
            self.playerState.writeIndex = sequenceNumber
            self.playerState.packets = [RTPPacket](
                repeating: EmptyPacket.packet(), count: 1024)
        }
    }

    func pause() {
        callbackQueue.async { self.playerState.isPlaying = false }
        AudioQueuePause(playerState.queue)
    }

    func reset() {
        AudioQueueReset(playerState.queue)
    }

    func printDebugInfo() {
        #if DEBUG
            print(
                "Read: \(playerState.readIndex)",
                "Write: \(playerState.writeIndex)",
                "Diff: \(playerState.writeIndex &- playerState.readIndex)",
                "Buffers: \(playerState.buffers.count)"
            )
        #endif
    }

    private typealias AudioQueueCallback = AudioQueueOutputCallbackBlock

    private func createAudioQueue(for playerState: PlayerState,
                                  callbackQueue: DispatchQueue,
                                  callback: @escaping AudioQueueCallback) {
        var format = createFormat()
        var queue: AudioQueueRef? = nil
        AudioQueueNewOutputWithDispatchQueue(
            &queue, &format, 0, callbackQueue, callback)
        playerState.queue = queue
    }

    private func createFormat() -> AudioStreamBasicDescription {
        var format = AudioStreamBasicDescription()
        format.mSampleRate = StreamProperties.sampleRate
        format.mFormatID = StreamProperties.audioFormat
        format.mFramesPerPacket = StreamProperties.framesPerPacket
        format.mChannelsPerFrame = StreamProperties.channelsPerFrame
        return format
    }

    private func setMagicCookie(for queue: AudioQueueRef) {
        let magicCookie = Data(base64Encoded: StreamProperties.magicCookie)!
		AudioQueueSetProperty(queue, kAudioQueueProperty_MagicCookie,
                                  [UInt8](magicCookie), UInt32(magicCookie.count))
    }

    private func createAudioBuffers(for queue: AudioQueueRef, count: Int) {
        let maxPacketSize = UInt32(playerState.bufferSize)
        let minPacketSize = UInt32(32)
        let numberOfPacketDescriptions = maxPacketSize / minPacketSize
        for _ in 0..<count {
            var buffer: AudioQueueBufferRef?
            AudioQueueAllocateBufferWithPacketDescriptions(
                queue, maxPacketSize, numberOfPacketDescriptions, &buffer)
            playerState.buffers.append(buffer!)
        }
    }

    private func handlePacket(_ packet: RTPPacket) {
        let maxIndex = playerState.packets.count - 1
        let index = Int(packet.sequenceNumber) & maxIndex
        guard writePacket(packet, to: index) else { return }
        updateWriteIndex(with: packet)
        updatePlaybackStatus(with: packet)
    }

    private func writePacket(_ packet: RTPPacket, to index: Int) -> Bool {
        let oldPacket = playerState.packets[index]
        let shouldOverwrite = checkPacket(packet, newerThan: oldPacket)
        guard shouldOverwrite else { return false }
        playerState.packets[index] = packet
        return true
    }

    private func checkPacket(_ packet: RTPPacket,
                             newerThan oldPacket: RTPPacket) -> Bool {
        guard !(oldPacket is EmptyPacket) else { return true }
        let packetInterval = packet.sequenceNumber &- oldPacket.sequenceNumber
        let isPacketNewer = packetInterval < (1 << 15)
        return isPacketNewer
    }

    private func updateWriteIndex(with packet: RTPPacket) {
        if packet.sequenceNumber &- playerState.writeIndex < (1 << 15) {
            playerState.writeIndex = packet.sequenceNumber
        }
    }

    private func updatePlaybackStatus(with packet: RTPPacket) {
        let currentDelay = calculateDelay(for: packet)
        let hasEnoughPackets = currentDelay > StreamProperties.playbackDelay
        if hasEnoughPackets { handlePlayback() }
        let hasAvailableBuffers = playerState.buffers.count > 0
        let hasIdleBuffers = playerState.isPlaying && hasAvailableBuffers
        if hasIdleBuffers { loadBuffers() }
    }

    private func loadBuffers() {
        for _ in 0..<playerState.buffers.count {
            let buffer = playerState.buffers[0]
            playerState.buffers.removeFirst()
            handleOutputBuffer(playerState: playerState,
                               queue: playerState.queue, buffer: buffer)
        }
    }

    private func calculateDelay(for packet: RTPPacket) -> TimeInterval {
        let maxIndex = UInt16(playerState.packets.count - 1)
        let lastRead = Int(playerState.readIndex & maxIndex)
        let lastReadTimestamp = playerState.packets[lastRead].timestamp
        let remainingTime = Double(packet.timestamp &- lastReadTimestamp) /
            StreamProperties.sampleRate
        return remainingTime
    }

    private func handlePlayback() {
        if !playerState.isPlaying && manager.isPlaying {
            loadBuffers()
            playerState.isPlaying = true
            AudioQueueStart(playerState.queue, nil)
        }
    }

    private func handleOutputBuffer(playerState: PlayerState,
                                    queue: AudioQueueRef,
                                    buffer: AudioQueueBufferRef) {
        var packetCount = 0
        var offset = 0
        while hasAvailablePackets && manager.isPlaying {
            let packet = currentPacket
            if !checkPacketIsSequential(packet) { continue }
            if !checkBufferHasSpace(for: packet, atOffset: offset) { break }
            writePacket(packet, to: buffer, index: packetCount, offset: offset)
            packetCount += 1
            offset += packet.payloadData.count
            playerState.readIndex = playerState.readIndex &+ 1
        }
        buffer.pointee.mAudioDataByteSize = UInt32(offset)
        buffer.pointee.mPacketDescriptionCount = UInt32(packetCount)
        enqueueBuffer(buffer, to: queue)
    }

    private var hasAvailablePackets: Bool {
        return playerState.writeIndex &- playerState.readIndex > 0
    }

    private var currentPacket: RTPPacket {
        let maxIndex = UInt16(playerState.packets.count - 1)
        let packetIndex = Int(playerState.readIndex & maxIndex)
        return playerState.packets[packetIndex]
    }

    private func checkPacketIsSequential(_ packet: RTPPacket) -> Bool {
        if packet.sequenceNumber != playerState.readIndex {
            #if DEBUG
                print("Skip: \(packet.sequenceNumber)",
                    "Index: \(playerState.readIndex)")
            #endif
            playerState.readIndex = playerState.readIndex &+ 1
            return false
        }
        return true
    }

    private func checkBufferHasSpace(for packet: RTPPacket,
                                     atOffset offset: Int) -> Bool {
        let packetSize = packet.payloadData.count
        return offset + packetSize <= playerState.bufferSize
    }

    private func writePacket(_ packet: RTPPacket,
                             to buffer: AudioQueueBufferRef,
                             index: Int, offset: Int) {
        let packetSize = packet.payloadData.count
		buffer.pointee.mAudioData.advanced(by: offset).copyMemory(
                from: [UInt8](packet.payloadData), byteCount: packetSize)
        let packetDescriptions = buffer.pointee.mPacketDescriptions
        packetDescriptions?[index].mStartOffset = Int64(offset)
        packetDescriptions?[index].mDataByteSize = UInt32(packetSize)
        packetDescriptions?[index].mVariableFramesInPacket = 0
    }

    private func enqueueBuffer(_ buffer: AudioQueueBufferRef,
                               to queue: AudioQueueRef) {
        let error = AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
        if error != 0 {
            handleEnqueueError(for: buffer, in: queue, errorCode: Int(error))
        }
    }

    private func handleEnqueueError(for buffer: AudioQueueBufferRef,
                                    in queue: AudioQueueRef,
                                    errorCode: Int? = nil) {
        // Make buffer available for reuse
        playerState.buffers.append(buffer)
        let hasAvailableBuffer = (
            playerState.buffers.count < playerState.bufferCount)
        if !hasAvailableBuffer { resetPlaybackState(for: queue) }
        #if DEBUG
            printDebugInfo()
            if errorCode != nil { print("Enqueue error: \(errorCode!)") }
        #endif
    }

    private func resetPlaybackState(for queue: AudioQueueRef) {
        playerState.isPlaying = false
        AudioQueuePause(queue)
        playerState.readIndex = playerState.writeIndex
    }
}

private class PlayerState {
    let bufferSize = 2048
    let bufferCount = 3

    var queue: AudioQueueRef! = nil
    var buffers = [AudioQueueBufferRef]()
    // Invariant: `packets[x].sequenceNumber` % `packets.count` == x
    var packets = [RTPPacket](repeating: EmptyPacket.packet(), count: 1024)
    // Invariant: `readIndex` points to current audio queue position
    var readIndex: UInt16 = 0
    // Invariant: `writeIndex` points to newest packet received
    var writeIndex: UInt16 = 0
    var isPlaying = false
}

// Properties are constant for AirPlay audio streams
private enum StreamProperties {
    static let audioFormat = kAudioFormatAppleLossless
    static let sampleRate = 44100.0
    static let framesPerPacket: UInt32 = 352
    static let channelsPerFrame: UInt32 = 2
    static let playbackDelay = 2.0
    static let magicCookie = "AAABYAAQKAoOAgD/AAAAAAAAAAAAAKxE"
}
