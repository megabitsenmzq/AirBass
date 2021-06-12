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

public class ABPlayerController: NSViewController, ABPlayerServiceDelegate {
    private var collapsedView: ABCollapsedView!
    private var expandedView: ABExpandedView!
    private var playTimer: Timer?
    private var fadeTimer: Timer?
    private var currentTime = 0.0

    /// The service object that controls audio playback.
    public var service: ABPlayerService
    /// The object containing info on the audio player.
    public let playerInfo: ABPlayerInfo
    /// The object containing info on the current track.
    public let trackInfo: ABTrackInfo

    /// Creates an `ABPlayerController` instance with the specified `service`.
    ///
    /// - Parameter service: The service object that controls audio playback.
    public init(service: ABPlayerService) {
        self.service = service
        self.playerInfo = service.playerInfo
        self.trackInfo = service.trackInfo
        super.init(nibName: nil, bundle: Bundle(for: type(of: self)))
        self.collapsedView = ABCollapsedView.fromNib(owner: self)
        self.expandedView = ABExpandedView.fromNib(owner: self)
        self.service.delegate = self
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Whether the view controller's parent window floats above other windows
    /// or behaves as a normal window.
    public var isFloatingWindow = false {
        didSet {
            if isFloatingWindow {
                view.window!.level = convertToNSWindowLevel(Int(CGWindowLevelForKey(.floatingWindow)))
            }
            else {
                view.window!.level = convertToNSWindowLevel(Int(CGWindowLevelForKey(.normalWindow)))
            }
        }
    }

    /// Whether the user interface is in expanded or collapsed mode.
    public var isCollapsed = !UserDefaults.standard.bool(forKey: "view.isCollapsed") {
        didSet {
            UserDefaults.standard.setValue(!isCollapsed, forKey: "view.isCollapsed")
            expandedView.isCollapsed = isCollapsed
            collapsedView.isCollapsed = isCollapsed
        }
    }

    /// Whether or not the user interface uses dark mode.
    public var isDarkMode = false {
        didSet {
            if isDarkMode {
                view.window!.appearance = NSAppearance(
                    named: NSAppearance.Name.vibrantDark)
            }
            else {
                view.window!.appearance = NSAppearance(
                    named: NSAppearance.Name.vibrantLight)
            }
            updateTint()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(expandedView)
        view.addSubview(collapsedView)
        expandedView.autoresizingMask = NSView.AutoresizingMask.none
        collapsedView.autoresizingMask = NSView.AutoresizingMask.height
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        isDarkMode = true
        updateView()
        collapsedView.createAutohideTrackingArea()
        setViewType(to: isCollapsed ? .collapsed : .expanded, animate: false)
    }

    private func updateTint() {
        expandedView.updateTint()
        collapsedView.updateTint()
    }

    private func updateView() {
        updateMetadata()
        updatePlaybackStatus()
        handlePlaybackStart()
        handlePlaybackStop()
    }

    private func updateMetadata() {
        let artwork = trackInfo.artwork
        let title = trackInfo.name
        let subtitle = formatSubtitle(with: trackInfo.artist, trackInfo.album)
        expandedView.trackArtwork = artwork
        expandedView.trackTitle = title
        expandedView.trackSubtitle = subtitle
        collapsedView.trackTitle = title
        collapsedView.trackSubtitle = subtitle
    }

    private func formatSubtitle(with strings: String...) -> String {
        var formatted = ""
        var previous = ""
        for string in strings {
            if string != "" {
                if previous != "" { formatted += " — " }
                formatted += string
                previous = string
            }
        }
        return formatted
    }

    private func updatePlaybackStatus() {
        currentTime = trackInfo.position
        expandedView.isPlaying = playerInfo.isPlaying
    }

    private func handlePlaybackStart() {
        if playerInfo.isPlaying && playTimer == nil {
            playTimer = Timer(timeInterval: 0.5,
                              target: self,
                              selector: #selector(incrementTime),
                              userInfo: nil,
                              repeats: true)
            RunLoop.main.add(playTimer!, forMode: RunLoop.Mode.common)
            autohideControls()
        }
    }

    private func handlePlaybackStop() {
        if !playerInfo.isPlaying && playTimer != nil {
            stopPlayTimer()
            expandedView.resetPlaybackSlider()
            showControls()
        }
    }

    private func stopPlayTimer() {
        playTimer?.invalidate()
        playTimer = nil
    }

    @objc private func incrementTime() {
        let precision = 0.5
        currentTime += precision
        if currentTime > trackInfo.duration {
            stopPlayTimer()
            currentTime = trackInfo.duration
        }
        expandedView.setPlaybackSlider(
            to: currentTime, withDuration: trackInfo.duration)
    }

    private func showControls() {
        collapsedView.hideTrackInfo()
        expandedView.showControls()
    }

    private func hideControls() {
        fadeTimer?.invalidate()
        fadeTimer = Timer(fireAt: Date(timeIntervalSinceNow: 0.5),
                          interval: 0,
                          target: self,
                          selector: #selector(fadeOutControls),
                          userInfo: nil,
                          repeats: false)
        RunLoop.main.add(fadeTimer!, forMode: RunLoop.Mode.common)
    }

    private func autohideControls() {
        if isCollapsed && !isCursorInFrame {
            hideControls()
        }
        else {
            showControls()
        }
    }

    @objc private func fadeOutControls() {
        if isCursorInFrame { return }
        if !playerInfo.isPlaying { return }
        if trackInfo.name == "" { return }
        collapsedView.showTrackInfo()
        NSAnimationContext.current.duration = 0.5

        NSAnimationContext.beginGrouping()
        collapsedView.fadeInTrackInfo()
        expandedView.hideControls()
        NSAnimationContext.endGrouping()
    }

    private var isCursorInFrame: Bool {
        return NSPointInRect(NSEvent.mouseLocation, view.window!.frame)
    }

    private enum ViewType {
        case expanded
        case collapsed
    }

    private func setViewType(to type: ViewType, animate animateFlag: Bool) {
        isCollapsed = (type == .collapsed)
        autohideControls()
        expandedView.toggle(
            toFrame: frameForToggledView())
    }

    private func frameForToggledView() -> NSRect {
        let expandedHeight = ABPlayerControllerConstants.expandedHeight
        let collapsedHeight = ABPlayerControllerConstants.collapsedHeight
        let oldHeight = isCollapsed ? expandedHeight : collapsedHeight
        let newHeight = isCollapsed ? collapsedHeight : expandedHeight
        var frame = view.window!.frame
        frame.size.height = CGFloat(newHeight)
        frame.origin.y += CGFloat(oldHeight - newHeight)
        return frame
    }

    public func playerService(_ playerService: ABPlayerService,
                              didChangeTrackInfo trackInfo: ABTrackInfo) {
        DispatchQueue.main.async { self.updateView() }
    }

    public func playerService(_ playerService: ABPlayerService,
                              didChangePlayerInfo playerInfo: ABPlayerInfo) {
        DispatchQueue.main.async {
            self.updateView()
            self.setVolume()
        }
    }

    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return true }
        switch action {
            case #selector(togglePlayAction(_:)):
                menuItem.title = playerInfo.isPlaying ? "Pause" : "Play"
            case #selector(pressedNextButton(_:)):
                return playerInfo.isPlaying
            case #selector(pressedPreviousButton(_:)):
                return playerInfo.isPlaying
            case #selector(toggleDarkMode(_:)):
                menuItem.state = isDarkMode ? .on : .off
            case #selector(toggleLargeArtwork(_:)):
                menuItem.state = isCollapsed ? .on : .off
                return playerInfo.isPlaying
            case #selector(toggleFloatingWindow(_:)):
                menuItem.state = isFloatingWindow ? .on : .off
            default:
                break
        }
        return true
    }

    public override func mouseUp(with event: NSEvent) {
        autohideControls()
    }

    public override func mouseEntered(with theEvent: NSEvent) {
        autohideControls()
    }

    public override func mouseExited(with theEvent: NSEvent) {
        autohideControls()
    }

    @IBAction private func pressedPlayButton(_ sender: AnyObject) {
        service.play()
    }

    @IBAction private func pressedPauseButton(_ sender: AnyObject) {
        service.pause()
    }

    @IBAction private func pressedNextButton(_ sender: AnyObject) {
        service.next()
    }

    @IBAction private func pressedPreviousButton(_ sender: AnyObject) {
        service.previous()
    }

    @IBAction private func pressedQuitButton(_ sender: AnyObject) {
        NSApp.terminate(nil)
    }

    @IBAction private func pressedExpandButton(_ sender: AnyObject) {
        setViewType(to: .expanded, animate: true)
    }

    @IBAction private func pressedCollapseButton(_ sender: AnyObject) {
        setViewType(to: .collapsed, animate: true)
    }

    @IBAction private func togglePlayAction(_ sender: AnyObject) {
        if playerInfo.isPlaying { service.pause() } else { service.play() }
    }

    @IBAction private func toggleDarkMode(_ sender: AnyObject) {
        isDarkMode = !isDarkMode
    }

    @IBAction private func toggleLargeArtwork(_ sender: AnyObject) {
        guard playerInfo.isPlaying else { return }
        if isCollapsed {
            setViewType(to: .expanded, animate: true)
        }
        else {
            setViewType(to: .collapsed, animate: true)
        }
    }

    @IBAction private func toggleFloatingWindow(_ sender: AnyObject) {
        isFloatingWindow = !isFloatingWindow
    }
}

private enum ABPlayerControllerConstants {
    static let expandedHeight: CGFloat = 382
    static let collapsedHeight: CGFloat = 44
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSWindowLevel(_ input: Int) -> NSWindow.Level {
	return NSWindow.Level(rawValue: input)
}
