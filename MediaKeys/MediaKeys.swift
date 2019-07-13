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
public class MediaKeys: NSApplication {
    private var appWhitelist = Set<String>()
    private var runningApps = [String]()
    private let currentApp = Bundle.main.bundleIdentifier!

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
		loadWhitelist()
		observeApplicationEvents()
		runningApps.append(currentApp)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    private func loadWhitelist() {
		appWhitelist.insert(currentApp)
        guard let path = Bundle(for: type(of: self)).path(
            forResource: "AppWhitelist", ofType:"plist") else { return }
        if let apps = NSArray(contentsOfFile: path) as? [String] {
            appWhitelist.formUnion(apps)
        }
    }

    private func observeApplicationEvents() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self,
                           selector: #selector(applicationDidActivate(_:)),
                           name: NSWorkspace.didActivateApplicationNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(applicationDidTerminate(_:)),
                           name: NSWorkspace.didTerminateApplicationNotification,
                           object: nil)
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        handleNotification(notification)
        if let identifier = getIdentifier(for: notification) {
            updateMostRecentApp(to: identifier)
        }
    }

    @objc private func applicationDidTerminate(_ notification: Notification) {
        handleNotification(notification)
    }

    private func handleNotification(_ notification: Notification) {
        guard let identifier = getIdentifier(for: notification) else { return }
        guard appWhitelist.contains(identifier) else { return }
        if let index = runningApps.firstIndex(of: identifier) {
            runningApps.remove(at: index)
        }
    }

    private func getIdentifier(for notification: Notification) -> String? {
        guard let userInfo = notification.userInfo else { return nil }
        guard let app = userInfo[NSWorkspace.applicationUserInfoKey] as?
            NSRunningApplication else { return nil }
        return app.bundleIdentifier
    }

    private func updateMostRecentApp(to identifier: String) {
        guard appWhitelist.contains(identifier) else { return }
        runningApps.insert(identifier, at: 0)
    }
	
	override public func sendEvent(_ event: NSEvent) {
		let shouldIntercept = (runningApps.first == currentApp)
		guard shouldIntercept else {
			super.sendEvent(event)
			return
		}
		if (event.type == .systemDefined && event.subtype.rawValue == 8) {
			let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
			let keyFlags = (event.data1 & 0x0000FFFF)
			// Get the key state. 0xA is KeyDown, OxB is KeyUp
			let keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA
			let keyRepeat = (keyFlags & 0x1)
			_ = mediaKeysdelegate!.mediaKeys(key: Int32(keyCode), state: keyState, keyRepeat: Bool(truncating: keyRepeat as NSNumber))
		}
		
		super.sendEvent(event)
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
    func mediaKeys(key: Int32, state: Bool, keyRepeat: Bool) -> Bool
}
