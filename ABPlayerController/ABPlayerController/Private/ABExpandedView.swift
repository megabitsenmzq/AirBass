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

class ABExpandedView: ABView {
    @IBOutlet private var artwork: NSImageView!
    @IBOutlet private var thumbnail: NSImageView!
    @IBOutlet private var thumbnailConstraint: NSLayoutConstraint!
    @IBOutlet private var playbackSlider: NSSliderCell!
    @IBOutlet private var titleField: NSTextField!
    @IBOutlet private var subtitleField: NSTextField!
    @IBOutlet private var positionField: NSTextField!
    @IBOutlet private var durationField: NSTextField!
    @IBOutlet private var dummyField: NSTextField!
    @IBOutlet private var playButton: NSButton!
    @IBOutlet private var pauseButton: NSButton!
    @IBOutlet private var nextButton: NSButton!
    @IBOutlet private var previousButton: NSButton!

    private var toggleAnimation: NSViewAnimation?

    var isPlaying = false {
        didSet {
            playButton.isHidden = isPlaying
            pauseButton.isHidden = !isPlaying
        }
    }
    
    var isCollapsed = false {
        didSet {
            positionField.isHidden = isCollapsed
            thumbnailConstraint.isActive = isCollapsed
        }
    }

    var trackTitle = "" {
        didSet { titleField.stringValue = trackTitle }
    }

    var trackSubtitle = "" {
        didSet { subtitleField.stringValue = trackSubtitle }
    }

    var trackArtwork = NSImage() {
        didSet {
            artwork.image = trackArtwork
            thumbnail.image = trackArtwork
        }
    }

    func showControls() {
        playButton.alphaValue = 1
        pauseButton.alphaValue = 1
        previousButton.alphaValue = 1
        nextButton.alphaValue = 1
    }

    func hideControls() {
        playButton.animator().alphaValue = 0
        pauseButton.animator().alphaValue = 0
        previousButton.animator().alphaValue = 0
        nextButton.animator().alphaValue = 0
    }

    func toggle(toFrame frame: NSRect) {
        window!.setFrame(frame, display: true, animate: false)
        thumbnail.isHidden = !isCollapsed
    }

//    func toggle(toFrame frame: NSRect, animate animateFlag: Bool) {
//        if !animateFlag { return toggle(toFrame: frame) }
//        if toggleAnimation?.isAnimating ?? false { return }
//        let effect = isCollapsed ?
//            convertFromNSViewAnimationEffectName(NSViewAnimation.EffectName.fadeIn) : convertFromNSViewAnimationEffectName(NSViewAnimation.EffectName.fadeOut)
//        let toggleThumbnail: [String: AnyObject] = [
//            convertFromNSViewAnimationKey(NSViewAnimation.Key.target): thumbnail,
//            convertFromNSViewAnimationKey(NSViewAnimation.Key.effect): effect as AnyObject,
//        ]
//        let windowResize: [String: AnyObject] = [
//            convertFromNSViewAnimationKey(NSViewAnimation.Key.target): window!,
//            convertFromNSViewAnimationKey(NSViewAnimation.Key.endFrame): NSValue(rect: frame),
//        ]
//        let animations = [toggleThumbnail, windowResize]
//        toggleAnimation = NSViewAnimation(viewAnimations: animations)
//        toggleAnimation?.duration = 0.3
//        toggleAnimation?.start()
//    }

    func setPlaybackSlider(to position: TimeInterval,
                           withDuration duration: TimeInterval) {
        positionField.stringValue = formatTime(position)
        if position < 0 {
            playbackSlider.doubleValue = 0
            durationField.stringValue = formatTime(-1)
            return
        }
        let newValue = formatTime(duration)

        // Set an upper bound to text field size so that
        // the frame doesn't change unless we add more digits
        if durationField.stringValue != newValue {
            durationField.stringValue = newValue
            var dummyString = ""
            for i in newValue {
                switch i {
                case ":":
                    dummyString += ":"
                case "-":
                    dummyString += "-"
                default:
                    // Arbitrary numerical character to determine width
                    dummyString += "8"
                }
            }
            dummyField.stringValue = dummyString
        }

        if duration > 0 {
            // Calculate a slider value that doesn't render to a subpixel
            let width = Double(playbackSlider.controlView!.frame.size.width)
            let unitValue = round(position * width / duration) / width
            playbackSlider.doubleValue = unitValue
        }
        else {
            playbackSlider.doubleValue = 0
        }
    }

    func resetPlaybackSlider() {
        setPlaybackSlider(to: -1, withDuration: -1)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time >= 0 else { return "--:--" }
        let i = Int(floor(time))
        let hours = i / 3600
        let minutes = (i / 60) % 60
        let seconds = i % 60
        if hours == 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        else {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSViewAnimationEffectName(_ input: NSViewAnimation.EffectName) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSViewAnimationKey(_ input: NSViewAnimation.Key) -> String {
	return input.rawValue
}
