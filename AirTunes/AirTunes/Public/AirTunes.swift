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
import ABPlayerInterface

/// The `AirTunes` class creates a server that AirPlay clients may connect and
/// stream audio to.
public class AirTunes: NSObject, ABPlayerService {
    private let manager: SessionManager
    public var delegate: ABPlayerServiceDelegate?

    /// Creates an `AirTunes` instance with the specified delegate.
    ///
    /// - Parameter name: The name by which the service is identified to the 
    /// network.
    /// - Parameter delegate: The object to be notified of changes to the
    /// player or track info. Defaults to `nil`.
    public init(name: String, delegate: ABPlayerServiceDelegate? = nil) {
        self.manager = SessionManager(name: name)
        self.delegate = delegate
    }

    /// Starts the server and listens for client connections.
    public func start() {
        manager.start()
        observeTrackInfoChanges(for: manager.trackInfo)
        observePlayerInfoChanges(for: manager.playerInfo)
    }

    public var playerInfo: ABPlayerInfo {
        return manager.playerInfo
    }

    public var trackInfo: ABTrackInfo {
        return manager.trackInfo
    }

    public func play() { manager.play() }

    public func pause() { manager.pause() }

    public func next() { manager.next() }

    public func previous() { manager.previous() }

    private func observeTrackInfoChanges(for trackInfo: TrackInfo) {
        ["name", "album", "artist",
         "position", "duration", "artwork"].forEach() {
            trackInfo.addObserver(
                self, forKeyPath: $0, options: [], context: nil)
        }
    }

    private func observePlayerInfoChanges(for playerInfo: PlayerInfo) {
        ["isPlaying", "volume"].forEach() {
            playerInfo.addObserver(
                self, forKeyPath: $0, options: [], context: nil)
        }
    }

    public override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if object is ABTrackInfo {
            delegate?.playerService(self, didChangeTrackInfo: trackInfo)
        }
        if object is ABPlayerInfo {
            delegate?.playerService(self, didChangePlayerInfo: playerInfo)
        }
    }
}
