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

public class ABWindow {
    /// Factory method to return an `NSWindow` object preconfigured with the
    /// appropriate attributes for an `ABPlayerController` instance.
    ///
    /// - Parameter contentViewController: The view controller to initialize
    /// the window with.
    public static func makeWindow(
        contentViewController: ABPlayerController) -> NSWindow
    {
        let window = NSWindow(contentViewController: contentViewController)
        window.styleMask = .borderless
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        return window
    }
}
