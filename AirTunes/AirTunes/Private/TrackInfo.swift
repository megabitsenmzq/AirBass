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
import ABPlayerInterface

class TrackInfo: NSObject, ABTrackInfo {
    @objc dynamic var name = ""
    @objc dynamic var album = ""
    @objc dynamic var artist = ""
    @objc dynamic var position = -1.0
    @objc dynamic var duration = -1.0
    @objc dynamic var artwork = NSImage()

    func reset() {
        name = ""
        album = ""
        artist = ""
        position = -1.0
        duration = -1.0
        artwork = NSImage()
    }

    func update(withKeyedValues keyedValues: [String: AnyHashable]) {
        setValuesForKeys(keyedValues)
    }

    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        return
    }
}
