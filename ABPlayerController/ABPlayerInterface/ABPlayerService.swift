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

/// Types conforming to the `ABPlayerService` protocol can be used to control
/// audio playback and to access info on the track and player.
public protocol ABPlayerService {
    /// The delegate to notify when track or player info changes.
    var delegate: ABPlayerServiceDelegate? { get set }
    /// The metadata info for the current track.
    var trackInfo: ABTrackInfo { get }
    /// The state of the audio player.
    var playerInfo: ABPlayerInfo { get }
    /// Begin audio playback.
    func play()
    /// Pause audio playback.
    func pause()
    /// Skip to the next track.
    func next()
    /// Go back to the previous track.
    func previous()
}
