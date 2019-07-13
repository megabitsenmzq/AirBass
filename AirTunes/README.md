AirTunes
========

[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms macOS](https://img.shields.io/badge/Platforms-macOS-lightgray.svg?style=flat)](http://www.apple.com/macos/)
[![License Apache](https://img.shields.io/badge/License-APACHE2-blue.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)

AirTunes is a Mac framework for creating an AirPlay audio server. It enables wireless audio streaming from an iOS device to a Mac.

Example
-------
AirTunes is used in the [AirBass](https://github.com/jenghis/airbass) app.

Instructions
------------
Drag `AirTunes.xcodeproj` into the Project Navigator of your app's Xcode project. Then open your app target's "General" configuration page. In the "Embedded Binaries" section, click the `+` icon and select `AirTunes.framework`.

Dependencies
------------
AirTunes depends on the `ABPlayerInterface` framework, which is part of the ABPlayerController project. Follow the instructions on the project page to install the framework:

[https://github.com/jenghis/abplayercontroller](https://github.com/jenghis/abplayercontroller)

Usage
-----
Create an `AirTunes` instance and call `start()` to start the server. Playback can be monitored and controlled using the methods described by the `ABPlayerService` protocol. 

License
-------
This project is available under the Apache 2.0 license. See LICENSE for details.
