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

class ABImageView: NSImageView, ABTintable {
    @IBInspectable var lightTint: NSImage?
    @IBInspectable var darkTint: NSImage?

    var isDarkMode: Bool {
        return convertFromNSAppearanceName(effectiveAppearance.name) == convertFromNSAppearanceName(NSAppearance.Name.vibrantDark)
    }

    func updateTint() {
        guard image == nil || image!.size == NSZeroSize else { return }
        image = isDarkMode ? darkTint : lightTint  // Handle missing image
    }

    override var image: NSImage? {
        didSet { updateTint() }
    }

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func mouseUp(with theEvent: NSEvent) {
        // Perform action on double click
        if theEvent.clickCount == 2 {
            if action != nil { let _ = target?.perform(action, with: self) }
        }
        super.mouseUp(with: theEvent)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAppearanceName(_ input: NSAppearance.Name) -> String {
	return input.rawValue
}
