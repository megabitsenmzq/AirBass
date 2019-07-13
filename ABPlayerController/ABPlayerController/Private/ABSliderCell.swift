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

class ABSliderCell: NSSliderCell {
    override func drawKnob(_ knobRect: NSRect) {
        return  // No knob on slider
    }
    
    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        drawRemainingTimeBar(inside: aRect)
        drawElapsedTimeBar(inside: aRect)
    }

    private func drawRemainingTimeBar(inside aRect: NSRect) {
        var remainingTimeBar = aRect
        remainingTimeBar.size.height = ABSliderCellConstants.barHeight
        if isDarkMode {
            ABSliderCellConstants.remainingTimeDark.setFill()
        }
        else {
            ABSliderCellConstants.remainingTimeLight.setFill()
        }
        NSBezierPath(rect: remainingTimeBar).fill()
    }

    private func drawElapsedTimeBar(inside aRect: NSRect) {
        var elapsedTimeBar = aRect
        elapsedTimeBar.size.height = ABSliderCellConstants.barHeight
        elapsedTimeBar.size.width = elapsedTimeBarWidth
        if isDarkMode {
            ABSliderCellConstants.elapsedTimeDark.setFill()
        }
        else {
            ABSliderCellConstants.elapsedTimeLight.setFill()
        }
        NSBezierPath(rect: elapsedTimeBar).fill()
    }

    private var isDarkMode: Bool {
        return (convertFromNSAppearanceName((controlView?.effectiveAppearance.name)!) ==
            convertFromNSAppearanceName(NSAppearance.Name.vibrantDark))
    }

    private var elapsedTimeBarWidth: CGFloat {
        let value = CGFloat((doubleValue - minValue) / (maxValue - minValue))
        return CGFloat(value * (controlView!.frame.size.width))
    }
}

private enum ABSliderCellConstants {
    static let barHeight: CGFloat = 4
    static let remainingTimeDark = NSColor(white: 74/255, alpha: 0.5)
    static let remainingTimeLight = NSColor(white: 122/255, alpha: 0.5)
    static let elapsedTimeDark = NSColor(white: 141/255, alpha: 0.7)
    static let elapsedTimeLight = NSColor(white: 98/255, alpha: 0.7)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAppearanceName(_ input: NSAppearance.Name) -> String {
	return input.rawValue
}
