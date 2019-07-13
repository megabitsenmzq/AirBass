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

/// Types conforming to the `ABTrackInfo` protocol enable access to the metadata
/// of the currently playing audio track.
public protocol ABTrackInfo {
    /// The name of the track.
    var name: String { get }
    /// The album the track belongs to.
    var album: String { get }
    /// The artist associated with the track.
    var artist: String { get }
    /// The playback position for the track in seconds.
    var position: TimeInterval { get }
    /// The total duration of the track in seconds.
    var duration: TimeInterval { get }
    /// The cover artwork for the track.
    var artwork: NSImage { get }
}
