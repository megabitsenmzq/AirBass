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

class ParameterParser: Parser {
    private let parameters: String

    required init?(data: Data) {
        guard let parameters = String(
            data: data, encoding: .utf8) else { return nil }
        self.parameters = parameters
    }

    func parse() -> [String: AnyHashable] {
        if let progress = Progress(
            parameters: parameters) {
            return [
                "duration": progress.duration,
                "position": progress.position,
            ]
        }
        
        if let info = Info(
            parameters: parameters) {
            return [
                "volume": info.volume
            ]
        }
        return [:]
    }
}

private class Info {
    let volume: Double
    
    init?(parameters: String) {
        guard let info = parameters.match(
            "(volume: )(.*)", group: 2) else { return nil }
        volume = Double(info)!
    }
}

private class Progress {
    private let startTime: Double
    private let currentTime: Double
    private let endTime: Double
    private let sampleRate = 44100.0  // Constant in AirPlay protocol

    init?(parameters: String) {
        guard let progress = parameters.match(
            "(progress: )([\\d\\/]*)", group: 2) else { return nil }
        let components = progress.components(separatedBy: "/")
        startTime = Double(components[0])!
        currentTime = Double(components[1])!
        endTime = Double(components[2])!
    }

    var duration: TimeInterval {
        return round((endTime - startTime) / sampleRate)
    }
    
    var position: TimeInterval {
        let position = round((currentTime - startTime) / sampleRate)
        // AirPlay-reported position is off to allow for buffering
        let playbackDelay = 2.0
        return position - playbackDelay
    }
}
