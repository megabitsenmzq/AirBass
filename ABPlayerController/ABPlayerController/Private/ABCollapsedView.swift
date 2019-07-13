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

class ABCollapsedView: ABView {
    @IBOutlet private var titleField: NSTextField!
    @IBOutlet private var subtitleField: NSTextField!
    @IBOutlet private var expandButton: NSButton!
    @IBOutlet private var collapseButton: NSButton!
    @IBOutlet private var quitButton: NSButton!

    var isCollapsed = false {
        didSet {
            expandButton.isHidden = !isCollapsed
            collapseButton.isHidden = isCollapsed
        }
    }

    var canExpand = false {
        didSet { expandButton.isEnabled = canExpand }
    }

    var trackTitle = "" {
        didSet { titleField.stringValue = trackTitle }
    }

    var trackSubtitle = "" {
        didSet { subtitleField.stringValue = trackSubtitle }
    }

    func createAutohideTrackingArea() {
        // Tracking to show/hide controls in collapsed view
        let trackingArea = NSTrackingArea(
            rect: frame,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil)
        addTrackingArea(trackingArea)
    }

    func hideTrackInfo() {
        titleField.alphaValue = 0
        subtitleField.alphaValue = 0
        titleField.isHidden = true
        subtitleField.isHidden = true
    }

    func showTrackInfo() {
        titleField.isHidden = false
        subtitleField.isHidden = false
    }

    func fadeInTrackInfo() {
        titleField.animator().alphaValue = 1
        subtitleField.animator().alphaValue = 1
    }
}
