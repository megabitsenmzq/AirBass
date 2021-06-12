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

import Cocoa

class RTSPSession: NSObject, GCDAsyncSocketDelegate {
    private let manager: SessionManager
    private var tcpSockets = [GCDAsyncSocket]()
    private let registry = TypeRegistry()
    private let contentTypes: [String] = [
        "application/rtsp",
        "application/sdp",
        "image/jpeg",
        "text/parameters",
        "application/x-dmap-tagged",
    ]
    
    init(manager: SessionManager) {
        self.manager = manager
        super.init()
        registerContentTypes()
    }

    func start() {
        let socket = createSocket()
        tcpSockets.append(socket)
    }

	func socket(_ sock: GCDAsyncSocket,
				didAcceptNewSocket newSocket: GCDAsyncSocket) {
        tcpSockets.append(newSocket)
        let packetEnd = "\r\n\r\n".data(using: .utf8)!
        newSocket.readData(to: packetEnd, withTimeout: 30, tag: rtspTag)
    }

	func socket(_ sock: GCDAsyncSocket,
				didRead data: Data, withTag tag: Int) {
        guard let type = registry.contentType(for: tag) else { return }
        switch type {
            case "application/rtsp":
                handleRTSPData(data, from: sock)
            case "application/sdp":
                handleSDPData(data)
            case "image/jpeg":
                handleJPEGData(data)
            case "text/parameters":
                handleParameterData(data)
            case "application/x-dmap-tagged":
                handleDAAPData(data)
            default:
                break
        }
    }

	func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int,
                elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        #if DEBUG
            print("Connection timed out")
        #endif
        return 0
    }

    private func registerContentTypes() {
        contentTypes.forEach() { registry.registerContentType($0) }
    }
    
    private func createSocket() -> GCDAsyncSocket {
        let tcpQueue = DispatchQueue(label: "tcpQueue")
        let socket = GCDAsyncSocket(delegate: self, delegateQueue: tcpQueue)
        try? socket.accept(onPort: RTSPSessionConstants.port)
        return socket
    }

    private var rtspTag: Int! {
        return registry.tag(for: "application/rtsp")
    }

    private func handleRTSPData(_ data: Data, from sock: GCDAsyncSocket) {
        let request = RTSPParser(data: data)!.parse() as! [String: String]
        handleMethod(inRequest: request, from: sock)
        readContent(forRequest: request, from: sock)
        respond(toRequest: request, using: sock)
        updateRemoteFromInfo(inRequest: request)
        readNextRTSPPacket(from: sock)
        #if DEBUG
            manager.printDebugInfo()
        #endif
    }

    private func handleMethod(inRequest request: [String: String],
                              from sock: GCDAsyncSocket) {
        let method = request["Method"]!
        switch method {
            case "SETUP":
                setSessionSocket(sock)
                manager.beginPlayback()
            case "RECORD", "FLUSH":
                manager.resetPlayback()
            case "TEARDOWN":
                manager.endPlayback()
            default:
                break
        }
    }

    private func setSessionSocket(_ sock: GCDAsyncSocket!) {
        // Disconnect any other session
        for i in 1..<tcpSockets.count {
            if tcpSockets[i] === sock { break }
            tcpSockets[i].disconnect()
        }
    }

    private func readContent(forRequest request: [String: String],
                             from sock: GCDAsyncSocket) {
        guard let contentType = request["Content-Type"] else { return }
        guard let contentLength = request["Content-Length"] else { return }
        guard let tag = registry.tag(for: contentType) else { return }
        sock.readData(
            toLength: UInt(contentLength)!, withTimeout: 30, tag: tag)
    }

    private func respond(toRequest request: [String: String],
                         using sock: GCDAsyncSocket) {
        let response = RTSPResponse()
        let method = request["Method"]!
        switch method {
            case "OPTIONS":
                guard let challenge = request["Apple-Challenge"] else { break }
                response.addChallengeResponse(
                    createResponse(forChallenge: challenge, from: sock))
            case "SETUP":
                response.addSetupResponse()
            default:
                break
        }
        let sequenceNumber = Int(request["CSeq"] ?? "0")!
        response.addSequenceNumber(sequenceNumber)
        let responseData = response.build()
        sock.write(responseData, withTimeout: 30, tag: rtspTag)
    }

    private func createResponse(forChallenge challenge: String,
                                from sock: GCDAsyncSocket) -> String {
        var responseData = Data(base64Encoded: challenge)!
        responseData.append(sock.internetAddress)
        responseData.append(Data(manager.hardwareAddress))
        while responseData.count < 32 { responseData.append(0) }
        let signedResponse = manager.sign(responseData)
        return signedResponse.base64EncodedString()
    }

    private func updateRemoteFromInfo(inRequest request: [String: String]) {
        guard let token = request["Active-Remote"] else { return }
        guard let id = request["DACP-ID"] else { return }
        manager.updateToken(token, forRemoteIdentifier: id)
    }
    
    private func readNextRTSPPacket(from sock: GCDAsyncSocket) {
        let packetEnd = "\r\n\r\n".data(using: .utf8)!
        sock.readData(to: packetEnd, withTimeout: 30, tag: rtspTag)
    }

    private func handleSDPData(_ data: Data) {
        let parsed = SDPParser(data: data)!.parse()
        manager.updateEncryption(with: parsed)
    }

    private func handleJPEGData(_ data: Data) {
        let artwork = NSImage(data: data) ?? NSImage()
        let parsed = ["artwork": artwork]
        manager.updateTrackInfo(withKeyedValues: parsed)
    }

    private func handleParameterData(_ data: Data) {
        let parsed = ParameterParser(data: data)!.parse()
        manager.updateTrackInfo(withKeyedValues: parsed)
        manager.updatePlayerInfo(withKeyedValues: parsed)
    }

    private func handleDAAPData(_ data: Data) {
        let parsed = DAAPParser(data: data)!.parse()
        manager.updateTrackInfo(withKeyedValues: parsed)
        manager.updatePlayerInfo(withKeyedValues: parsed)
    }
}

private enum RTSPSessionConstants {
    static let port: UInt16 = 5001
}
