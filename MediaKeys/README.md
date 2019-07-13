MediaKeys
=========

[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms macOS](https://img.shields.io/badge/Platforms-macOS-lightgray.svg?style=flat)](http://www.apple.com/macos/)
[![License Apache](https://img.shields.io/badge/License-APACHE2-blue.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)

The MediaKeys framework is a Mac framework for monitoring and intercepting media key presses.

General
-------
Media keys are keys on an Apple keyboard that control media playback. These include the ⏪, ⏯, and ⏩ keys found on the function row. The framework can also handle other special keys such as the display brightness and Mission Control keys.

In addition to monitoring key presses, the MediaKeys framework can intercept them so that other applications are not notified of the key press. This would, for example, enable a music player application to start playing when the ⏯ key is pressed without iTunes also doing so.

Example
-------
MediaKeys is used in the [AirBass](https://github.com/jenghis/airbass) app.

Instructions
------------
Drag `MediaKeys.xcodeproj` into the Project Navigator of your app's Xcode project. Then open your app target's "General" configuration page. In the "Embedded Binaries" section, click the `+` icon and select `MediaKeys.framework`.

Usage
-----
To use the framework, create a `MediaKeys` instance and assign it a delegate to respond to media key presses.

License
-------
This project is available under the Apache 2.0 license. See LICENSE for details.
