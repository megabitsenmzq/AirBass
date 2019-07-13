ABPlayerController
==================

[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms macOS](https://img.shields.io/badge/Platforms-macOS-lightgray.svg?style=flat)](http://www.apple.com/macos/)
[![License Apache](https://img.shields.io/badge/License-APACHE2-blue.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)

ABPlayerController is a Mac framework for creating a minimal audio player UI.

Example
-------
ABPlayerController is used in the [AirBass](https://github.com/jenghis/airbass) app.

<img src="https://raw.githubusercontent.com/jenghis/airbass/master/screenshot.png" width="700">

Instructions
------------
Drag `ABPlayerController.xcodeproj` into the Project Navigator of your app's Xcode project. Then open your app target's "General" configuration page. In the "Embedded Binaries" section, click the `+` icon and select `ABPlayerController.framework`. Repeat these instructions for the `ABPlayerInterface` framework.

Usage
-----
To use the framework, an audio source needs to conform to the `ABPlayerService` protocol. An `ABPlayerController` instance can then be initialized with the audio source and attached to a window created by `ABWindow`.

License
-------
This project is available under the Apache 2.0 license. See LICENSE for details.
