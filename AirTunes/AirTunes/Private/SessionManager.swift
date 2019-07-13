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

class SessionManager {
    private var audioSession: AudioSession!
    private var rtpSession: RTPSession!
    private var rtspSession: RTSPSession!
    private var remote: RemoteService!
    private var crypto: CryptoService!
    private var bonjour: BonjourService!

    var trackInfo = TrackInfo()
    var playerInfo = PlayerInfo()

    init(name: String) {
        rtspSession = RTSPSession(manager: self)
        audioSession = AudioSession(manager: self)
        rtpSession = RTPSession(manager: self)
        remote = RemoteService()
        let keyPath = Bundle(for: type(of: self)).path(
            forResource: "PrivateKey.pem", ofType: nil)!
        crypto = CryptoService(privateKeyPath: keyPath)
        bonjour = BonjourService(
            name: name,
            hardwareAddress: hardwareAddress
        )
    }

    var hardwareAddress: [UInt8] {
        // Hard-code a random address to avoid the
        // convoluted lookup process
        return [184, 199, 93, 59, 114, 43]
    }

    var isPlaying: Bool {
        return playerInfo.isPlaying
    }

    func start() {
        bonjour.publish()
        audioSession.start()
        rtspSession.start()
        rtpSession.start()
    }

    func play() { remote.play() }

    func pause() { remote.pause() }

    func next() { remote.next() }

    func previous() { remote.previous() }

    func add(_ packet: RTPPacket) { audioSession.add(packet) }

    func sign(_ data: Data) -> Data { return crypto.sign(data) }

    func beginPlayback() {
        playerInfo.isPlaying = true
    }

    func endPlayback() {
        trackInfo.reset()
        audioSession.pause()
        playerInfo.isPlaying = false
    }

    func resetPlayback() {
        audioSession.reset()
        rtpSession.reset()
    }

    func updateEncryption(with info: [String: AnyHashable]) {
        let encryptedKey = info["key"] as! Data
        rtpSession.key = crypto.decrypt(encryptedKey)
        rtpSession.iv = info["iv"] as! Data
    }

    func updateToken(_ token: String, forRemoteIdentifier id: String) {
        remote.updateToken(token, forRemoteIdentifier: id)
    }

    func updateTrackInfo(withKeyedValues keyedValues: [String: AnyHashable]) {
        trackInfo.update(withKeyedValues: keyedValues)
    }

    func updatePlayerInfo(withKeyedValues keyedValues: [String: AnyHashable]) {
        playerInfo.update(withKeyedValues: keyedValues)
    }

    func setSequenceNumber(_ sequenceNumber: UInt16) {
        audioSession.setSequenceNumber(sequenceNumber)
    }

    func printDebugInfo() {
        audioSession.printDebugInfo()
    }
}
