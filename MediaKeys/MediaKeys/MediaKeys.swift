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
public class MediaKeys: NSObject, EventTapDelegate {
    private var appWhitelist = Set<String>()
    private var runningApps = [String]()
    private var eventTap: EventTap?
    private let currentApp = Bundle.main.bundleIdentifier!

    /// The object that handles media key presses.
    public var delegate: MediaKeysDelegate?

    /// Creates a `MediaKeys` instance with the specified delegate.
    ///
    /// - Parameter delegate: The object that handles media key presses.
    /// Defaults to `nil`.
    public init(delegate: MediaKeysDelegate? = nil) {
        self.delegate = delegate
        super.init()
        loadWhitelist()
        observeApplicationEvents()
        createEventTap()
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

    private func createEventTap() {
        let systemEvents: CGEventMask = 16384  // not defined in public API
        eventTap = EventTap(delegate: self, eventsOfInterest: systemEvents)
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

    func eventTap(_ tap: EventTap!, shouldIntercept event: CGEvent!) -> Bool {
        guard let delegate = self.delegate else { return false }
        let shouldIntercept = (runningApps.first == currentApp)
        guard shouldIntercept else { return false }
        guard let cocoaEvent = NSEvent(cgEvent: event) else { return false }
        let keyCode = Int32(cocoaEvent.data1 & 0xffff0000) >> 16
        let keyFlags = (cocoaEvent.data1 & 0x0000ffff)
        let keyState = ((keyFlags & 0xff00) >> 8) == 0xA
        guard keyState else { return false }
        return delegate.mediaKeys(self, shouldInterceptKeyWithKeyCode: keyCode)
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
    func mediaKeys(_ mediaKeys: MediaKeys,
                   shouldInterceptKeyWithKeyCode keyCode: Int32) -> Bool
}
