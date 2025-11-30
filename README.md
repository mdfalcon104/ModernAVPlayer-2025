# ModernAVPlayer2
![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)
![CocoaPods](https://img.shields.io/cocoapods/v/ModernAVPlayer2.svg)
![CocoaPods](https://img.shields.io/cocoapods/l/ModernAVPlayer2.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2010.0%2B%2C%20tvOS%2012.0%2B-blue.svg)

``ModernAVPlayer2`` is a persistence ``AVPlayer`` wrapper with comprehensive safe duration handling

#### ++ Cool features ++
- Get 9 nice and relevant player states (playing, buffering, loading, loaded...)
- Persistence player to resume playback after bad network connection ~~even in background mode~~  (bug from version 1.5.1)
- Manage headphone interactions, call & siri interruptions, now playing informations
- Add your own plug-in to manage tracking, events...
- RxSwift compatible
- Loop mode
- Log available by domain
- **NEW**: Safe duration handling with configurable URL metadata fallback
- **NEW**: Media metadata duration support for precise playback control
- **NEW**: Automatic playback termination at media duration limits
***

### Known issue
From version 1.5.1, resume playback from background mode failed. If you have any suggestion, please help. 

``Use of  mixWithOther AVAudiosession CategoryOptions is not a solution.``
***

## Menu
- [Requirements](#requirements)
- [Installation](#installation)
- [Getting started](#getting-started)
- [Advanced](#advanced)
    - [Custom Configuration](#custom-configuration)
    - [Remote Command](#remote-command)
    - [Plugin](#plugin)
    - [RxSwift](#rxswift)
- [Communication](#communication)

## Requirements

- iOS 10.0+
- tvOS 12.0+

> In order to support background mode, append the following to your ``Info.plist``:
```
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Installation

### Swift Package Manager

Supported version: ``swift-tools-version:5.0``

```swift
// Package.swift

import PackageDescription

let package = Package(
    name: "Sample",
    dependencies: [
        .package(url: "https://github.com/noreasonprojects/ModernAVPlayer", from: "X.X.X")
    ],
    targets: [
        .target(name: "Sample", dependencies: ["ModernAVPlayer"])
    ]
)
```

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.3+ is required to build ModernAVPlayer2.

To integrate ``ModernAVPlayer2`` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'ModernAVPlayer2'
end
```

For RxSwift support, use:
```ruby
pod 'ModernAVPlayer2/RxSwift'
```

Then, run the following command:

```bash
$ pod install
```

## Getting started

> Create media from URL
```swift
let media = ModernAVPlayerMedia(url: URL, type: MediaType)
```
> Create media from AVPlayerItem
```swift
let media = ModernAVPlayerMediaItem(item: AVPlayerItem, type: MediaType, metadata: PlayerMediaMetadata)
```

> Instanciate the wrapper
```swift
let player = ModernAVPlayer()
```
> Load and play the media
```swift
player.load(media: media, autostart: true)
```
> Track on repeat
```swift
player.loopMode = true
```

| ↓ State / Command → | loadMedia | play | pause | stop | seek |
|:---------|:---------:|:--------:|:--------:|:--------:|:--------:|
| Init  | O | X | O | O | X
| Loading  | O | X | O | O | X
| Loaded  | O | O | O | O | O
| Buffering  | O | X | O | O | O
| Playing  | O | X | O | O | O
| Paused  | O | O | X | O | O
| Stopped  | O | O | O | X | O
| WaitingNetwork  | O | X | O | O | X
| Failed  | O | O | X | X | X

## Advanced 

### Safe Duration Handling

ModernAVPlayer2 provides safe duration handling through a configurable 3-tier fallback system to prevent crashes from invalid CMTime values:

**Duration Fallback Priority:**
1. **URL Metadata** - Extracts duration from streaming URL parameters (e.g., `dur=180.5`)
2. **Media Metadata** - Uses duration from `PlayerMediaMetadata` if available
3. **AVAsset/AVPlayerItem** - Falls back to standard player item duration

**Enabling URL Metadata Fallback:**
```swift
ModernAVPlayerDurationConfig.useURLMetadataFallback = true
```

**Safe Duration Access:**
```swift
// Safe optional access (returns nil for invalid CMTime)
let duration = player.itemDuration  // Double?

// Direct safe conversion methods
let safeDuration = avPlayerItem.safeDuration  // Double?
let assetDuration = avAsset.safeDuration      // Double?
```

**Media Metadata with Duration:**
```swift
let metadata = ModernAVPlayerMediaMetadata(
    title: "Song Title",
    artist: "Artist Name",
    duration: 180.5  // Duration in seconds
)
let media = ModernAVPlayerMediaItem(
    item: playerItem,
    type: .audio,
    metadata: metadata
)
```

---

### Custom configuration

All player configuration are available from `PlayerConfiguration` protocol.  
A default implementation `ModernAVPlayerConfiguration` is provided with documentation

---

### Remote command

If using default configuration file ( `swift useDefaultRemoteCommand = true`), ModernAVPlayer use **automatically** all commands created by `ModernAVPlayerRemoteCommandFactory` class
Documention available in  `ModernAVPlayerRemoteCommandFactory.swift` file

#### Custom command

> Use your own `PlayerConfiguration` implementation with 
```swift
...
useDefaultRemoteCommand = false
...
```

> Create an array of  commands conforming to  `ModernAVPlayerRemoteCommand` protocol. 
```swift
let player = ModernAVPlayer(config: YourConfigImplementation())
let commands: [ModernAVPlayerRemoteCommand] = YourRemoteCommandFactory.commands
player.remoteCommands = commands
```

You can use existing commands from public `ModernAVPlayerRemoteCommandFactory` class.

---

### Plugin

Use `PlayerPlugin` protocol to create your own plugin system, like tracking Plugin.

---

### RxSwift

Instead of using delegate pattern, you can use rx to bind player attributes.

> Setup

Use `pod 'ModernAVPlayer/RxSwift'` in the Podfile

> Usage
```swift
let player = ModernAVPlayer()
let state: Observable<ModernAVPlayer.State> = player.rx.state
```

## Communication

- If you **found a bug**, make a pull request using `Simple Audio` template in the example section to demonstrate.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

---

## Version History

### v1.7.8 (Current)
- Enhanced README with safe duration handling documentation
- Clarified URL metadata fallback system
- Updated author attribution
- tvOS 12.0+ support
- iOS 10.0+ support

### v1.7.7
- Added tvOS 12.0+ deployment target support
- Fixed platform compatibility issues
- Implemented iOS 9.1+ availability checks

### v1.7.6
- Corrected pod name to ModernAVPlayer2
- Updated RxSwift to 6.0 compatibility

### v1.7.5
- Introduced safe duration extensions
- Implemented 3-tier duration fallback system
- Added URL metadata extraction support
- Added media metadata duration support

---

## Author

**mdfalcon104** - Safe duration handling implementation and platform support

ModernAVPlayer2 is maintained and distributed under the MIT License.
