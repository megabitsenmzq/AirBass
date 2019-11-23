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
import MediaPlayer

/// The `MediaKeys` class creates a service that monitors and optionally
/// intercepts media key press events.
///
/// Event interception is based on two factors: the last-active application and
/// the delegate response. `MediaKeys` will only intercept events if the parent
/// application is the last-active application among all applications specified
/// in the bundled whitelist. It may still pass on the event unless the delegate
/// also specifies that the event should be intercepted.
///
var sharedMediaKeys: MediaKeys!
public class MediaKeys: NSApplication, EventTapDelegate {
    private var eventTap: EventTap?

    /// The object that handles media key presses.
    public var mediaKeysdelegate: MediaKeysDelegate?

    /// Creates a `MediaKeys` instance with the specified delegate.
    ///
    /// - Parameter delegate: The object that handles media key presses.
    /// Defaults to `nil`.
	///
	
	override public init() {
		super.init()
		sharedMediaKeys = self
        createEventTap()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    let keyList = [NX_KEYTYPE_PLAY,
                   NX_KEYTYPE_FAST,
                   NX_KEYTYPE_REWIND]
    
    private func createEventTap() {
        let systemEvents: CGEventMask = 16384  // not defined in public API
        eventTap = EventTap(delegate: self, eventsOfInterest: systemEvents)
    }
    
    func eventTap(_ tap: EventTap!, shouldIntercept cgEvent: CGEvent!) -> Bool {
        if let event = NSEvent(cgEvent: cgEvent) {
            if event.type == .systemDefined && event.subtype.rawValue == 8 {
                let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
                let keyFlags = (event.data1 & 0x0000FFFF)
                // Get the key state. 0xA is KeyDown, OxB is KeyUp
                let keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA
                let keyRepeat = (keyFlags & 0x1)
                
                mediaKeysdelegate!.mediaKeys(key: Int32(keyCode), state: keyState, keyRepeat: Bool(truncating: keyRepeat as NSNumber))
                
                for key in keyList {
                    if key == Int32(keyCode) {
                        return true
                    }
                }
                return false
            }
        }
        return false
    }
    
    // Fallback when there is no accessibility access.
    override public func sendEvent(_ event: NSEvent) {
        super.sendEvent(event)
        if !eventTap!.disabled {
            return
        }
        if event.type == .systemDefined && event.subtype.rawValue == 8 {
            let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (event.data1 & 0x0000FFFF)
            // Get the key state. 0xA is KeyDown, OxB is KeyUp
            let keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA
            let keyRepeat = (keyFlags & 0x1)
            mediaKeysdelegate!.mediaKeys(key: Int32(keyCode), state: keyState, keyRepeat: Bool(truncating: keyRepeat as NSNumber))
        }
    }

}

/// The `MediaKeysDelegate` responds to media key press events and determines
/// whether or not an event should be intercepted.
public protocol MediaKeysDelegate {
    /// Determines whether or not a media key press should be intercepted.
    ///
    /// - Parameter mediaKeys: The instance that called the function.
    /// - Parameter keyCode: The keycode of the pressed key as defined in the
    /// IOKit keymap header file `ev_keymap.h`.
    func mediaKeys(key: Int32, state: Bool, keyRepeat: Bool)
}
