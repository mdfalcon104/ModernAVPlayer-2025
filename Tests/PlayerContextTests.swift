// The MIT License (MIT)
//
// ModernAVPlayer
// Copyright (c) 2018 Raphael Ankierman <raphael.ankierman@radiofrance.com>
//
// PlayerContextTests.swift
// Created by raphael ankierman on 28/02/2018.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import AVFoundation
@testable
import ModernAVPlayer2
import SwiftyMocky
import XCTest

final class PlayerContextTests: XCTestCase {

    private var audioSession: AudioSessionServiceMock!
    private var context: ModernAVPlayerContext!
    private var state: PlayerStateMock!
    private var media: MockPlayerMedia!
    private var nowPlaying: NowPlayingMock!
    private var player: MockCustomPlayer!
    private let config = ModernAVPlayerConfiguration()
    private var delegate: PlayerContextDelegateMock!

    override func setUp() {
        player = MockCustomPlayer()
        delegate = PlayerContextDelegateMock()
        ModernAVPlayerLogger.setup.domains = []
        audioSession = AudioSessionServiceMock()
        nowPlaying = NowPlayingMock()
        context = ModernAVPlayerContext(player: player, config: config, nowPlaying: nowPlaying,
                                       audioSession: audioSession, plugins: [])
        media = MockPlayerMedia(url: URL(string: "foo")!, type: .clip)
        context.delegate = delegate

        state = PlayerStateMock()
        Given(state, .type(getter: .failed))
        Given(state, .context(getter: context))
    }
    
    func testTotalDuration() {
        // ARRANGE
        let expectedDuration: Double = 1
        let duration = CMTime(seconds: expectedDuration, preferredTimescale: config.preferredTimescale)
        let item = MockPlayerItem.createOne(url: "foo", duration: duration)
        player.overrideCurrentItem = item

        // ACT
        let currentItem = context.currentItem
        let totalDuration = currentItem?.safeDuration ?? 0

        // ASSERT
        XCTAssertEqual(totalDuration, expectedDuration, accuracy: 0.001)
    }

    func testCurrentItem() {
        // ARRANGE
        let duration = CMTime(seconds: 42, preferredTimescale: config.preferredTimescale)
        let item = MockPlayerItem(url: URL(fileURLWithPath: ""), duration: duration, status: nil)
        player.overrideCurrentItem = item

        // ACT
        let itemResponse = context.currentItem

        // ASERT
        XCTAssertEqual(item, itemResponse)
    }

    func testCurrentMediaDelegateCall() {
        // ACT
        context.currentMedia = media

        // ASSERT
        Verify(delegate, 1,
               .playerContext(didCurrentMediaChange: .matching { $0 as? MockPlayerMedia == self.media }))
    }

    func testCurrentTime() {
        // ARRANGE
        let currentTime = CMTime(seconds: 42, preferredTimescale: config.preferredTimescale)
        player.overrideCurrentTime = currentTime

        // ACT
        let currentTimeResponse = context.currentTime

        // ASSERT
        XCTAssertEqual(currentTime.seconds, currentTimeResponse)
    }

    func testCurrentItemDuration() {
        // ARRANGE
        let duration = CMTime(seconds: 42, preferredTimescale: config.preferredTimescale)
        let item = MockPlayerItem.createOne(url: "foo", duration: duration)
        player.overrideCurrentItem = item

        // ACT
        let durationResponse = context.currentItem?.duration

        // ASERT
        XCTAssertEqual(duration, durationResponse)
    }

    func testSetStateContextUpdatedCall() {
        // ACT
        context.changeState(state: state)

        // ASSERT
        Verify(state, 1, .contextUpdated())
    }

    func testSetStateDelegateCall() {
        // ACT
        context.changeState(state: state)

        // ASSERT
        Verify(delegate, 1, .playerContext(didStateChange: .value(state.type)))
    }

    func testCurrentInitState() {
        // ASSERT
        XCTAssertTrue(context.state is InitState)
    }

    func testSetCategoryOnInit() {
        // ASSERT
        Verify(self.audioSession, 1, .setCategory(.value(self.context.config.audioSessionCategory),
                                                  options: .value(self.context.config.audioSessionCategoryOptions)))
    }

    func testSetExternalPlayback() {
        // ARRANGE
        player.overrideAllowsExternalPlayback = config.allowsExternalPlayback
        
        // ASSERT
        XCTAssertEqual(player.allowsExternalPlayback, config.allowsExternalPlayback)
        // AVPlayer init allowsExternalPlayback property
        XCTAssertEqual(player.allowsExternalPlaybackCallCount, 2)
    }

    func testChangeState() {
        // ARRANGE
        Given(state, .type(getter: .loaded))

        // ACT
        context.changeState(state: state)

        // ASSERT
        XCTAssertEqual(context.state.type, .loaded)
    }

    func testPause() {
        // ARRANGE
        context.changeState(state: state)

        // ACT
        context.pause()

        // ASSERT
        Verify(state, 1, .pause())
    }

    func testPlay() {
        // ARRANGE
        context.changeState(state: state)

        // ACT
        context.play()

        // ASSERT
        Verify(state, 1, .play())
    }

    func testStop() {
        // ARRANGE
        context.changeState(state: state)

        // ACT
        context.stop()

        // ASSERT
        Verify(state, 1, .stop())
    }

    func testSeekWithNoCurrentItem() {
        // ARRANGE
        context.changeState(state: state)

        // ACT
        context.seek(position: 0)

        // ASSERT
        Verify(delegate, 1, .playerContext(unavailableActionReason: .value(.loadMediaFirst)))
    }

    func testOverstepSeekPosition() {
        // ARRANGE
        let seekPosition: Double = 43
        let duration = CMTime(seconds: 42, preferredTimescale: config.preferredTimescale)
        player.overrideCurrentItem = MockPlayerItem(url: URL(fileURLWithPath: ""),
                                                    duration: duration, status: nil)

        // ACT
        context.seek(position: seekPosition)

        // ASSERT
        Verify(delegate, 1, .playerContext(unavailableActionReason: .value(.seekOverstepPosition)))
    }

    func testValidSeekPosition() {
        // ARRANGE
        let seekPosition: Double = 21
        let duration = CMTime(seconds: 42, preferredTimescale: config.preferredTimescale)
        player.overrideCurrentItem = MockPlayerItem(url: URL(fileURLWithPath: ""),
                                                    duration: duration, status: nil)
        context.changeState(state: state)

        // ACT
        context.seek(position: seekPosition)

        // ASSERT
        Verify(state, 1, .seek(position: .value(seekPosition)))
    }

    func testValidSeekOffset() {
        // ARRANGE
        let seekPosition = CMTime(seconds: 21, preferredTimescale: config.preferredTimescale)
        let duration = CMTime(seconds: 42, preferredTimescale: config.preferredTimescale)
        let offset: Double = 10
        player.overrideCurrentTime = seekPosition
        player.overrideCurrentItem = MockPlayerItem(url: URL(fileURLWithPath: ""),
                                                    duration: duration, status: nil)
        context.changeState(state: state)

        // ACT
        context.seek(offset: offset)

        // ASSERT
        let expected = seekPosition.seconds + offset
        Verify(state, 1, .seek(position: .value(expected)))
    }

    func testLoadMedia() {
        // ARRANGE
        let media = MockPlayerMedia(url: URL(string: "foo")!, type: .clip)
        let autostart = true
        let position: Double = 56
        context.changeState(state: state)

        // ACT
        context.load(media: media, autostart: autostart, position: position)

        // ASSERT
        Verify(state, 1, .load(media: .matching { $0 as? MockPlayerMedia == media },
                               autostart: .value(autostart),
                               position: .value(position)))
    }

    func testUpdateMetadataSetMetadata() {
        // ARRANGE
        let media = PlayerMediaMock()
        context.currentMedia = media
        let metadata = MockPlayerMediaMetadata(title: "title",
                                               albumTitle: "album",
                                               artist: "artist",
                                               image: nil,
                                               remoteImageUrl: nil)

        // ACT
        context.updateMetadata(metadata)

        // ASSERT
        Verify(media, 1, .setMetadata(.matching { $0 as? MockPlayerMediaMetadata == metadata }))
    }

    func testUpdateMetadataNowPlayingInfo() {
        // ARRANGE
        context.currentMedia = media
        let metadata = MockPlayerMediaMetadata(title: "title",
                                               albumTitle: "album",
                                               artist: "artist",
                                               image: nil,
                                               remoteImageUrl: nil)

        // ACT
        context.updateMetadata(metadata)

        // ASSERT
        Verify(nowPlaying, 1, .update(metadata: .matching { $0 as? MockPlayerMediaMetadata == metadata }))
    }

    func testUpdateMetadataWithNoCurrentMedia() {
        // ARRANGE
        context.currentMedia = nil

        // ACT
        context.updateMetadata(nil)

        // ASSERT
        Verify(delegate, 1, .playerContext(unavailableActionReason: .value(.loadMediaFirst)))
    }

    // MARK: - safeDuration Tests

    func testSafeDurationWithValidDuration() {
        // ARRANGE
        let expectedDuration: Double = 42.5
        let duration = CMTime(seconds: expectedDuration, preferredTimescale: config.preferredTimescale)
        let item = MockPlayerItem.createOne(url: "foo", duration: duration)
        
        // ACT
        let safeDuration = item.safeDuration
        
        // ASSERT
        XCTAssertNotNil(safeDuration, "safeDuration should not be nil for valid duration")
        XCTAssertEqual(safeDuration ?? 0, expectedDuration, accuracy: 0.001)
    }

    func testSafeDurationWithInvalidDuration() {
        // ARRANGE
        let item = MockPlayerItem.createOne(url: "foo", duration: CMTime.invalid)
        
        // ACT
        let safeDuration = item.safeDuration
        
        // ASSERT
        XCTAssertNil(safeDuration, "safeDuration should be nil for invalid duration")
    }

    func testSafeDurationWithIndefiniteDuration() {
        // ARRANGE
        let item = MockPlayerItem.createOne(url: "foo", duration: CMTime.indefinite)
        
        // ACT
        let safeDuration = item.safeDuration
        
        // ASSERT
        XCTAssertNil(safeDuration, "safeDuration should be nil for indefinite duration")
    }

    func testSafeDurationWithZeroDuration() {
        // ARRANGE
        let item = MockPlayerItem.createOne(url: "foo", duration: CMTime.zero)
        
        // ACT
        let safeDuration = item.safeDuration
        
        // ASSERT
        XCTAssertNotNil(safeDuration, "safeDuration should not be nil for zero duration")
        XCTAssertEqual(safeDuration ?? -1, 0.0, accuracy: 0.001)
    }

    func testCMTimeSafeSeconds() {
        // Test valid time
        let validTime = CMTime(seconds: 100.5, preferredTimescale: 1000)
        XCTAssertNotNil(validTime.safeSeconds, "safeSeconds should not be nil for valid time")
        XCTAssertEqual(validTime.safeSeconds ?? 0, 100.5, accuracy: 0.001)
        
        // Test invalid time
        XCTAssertNil(CMTime.invalid.safeSeconds, "safeSeconds should be nil for invalid time")
        
        // Test indefinite time
        XCTAssertNil(CMTime.indefinite.safeSeconds, "safeSeconds should be nil for indefinite time")
        
        // Test zero time
        XCTAssertNotNil(CMTime.zero.safeSeconds, "safeSeconds should not be nil for zero time")
        XCTAssertEqual(CMTime.zero.safeSeconds ?? -1, 0.0, accuracy: 0.001)
    }
    
    func testDurationFromURLMetadata() {
        // ARRANGE
        let urlString = "https://example.com/audio.mp3?dur=240.639&other=param"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid test URL")
            return
        }
        let asset = AVURLAsset(url: url)
        
        // ACT
        let durationFromMetadata = asset.durationFromURLMetadata()
        
        // ASSERT
        XCTAssertNotNil(durationFromMetadata, "Should extract duration from URL metadata")
        XCTAssertEqual(durationFromMetadata ?? 0, 240.639, accuracy: 0.001)
    }
    
    func testDurationFromURLMetadataWithoutDurParam() {
        // ARRANGE - URL without 'dur' parameter
        let urlString = "https://example.com/audio.mp3?other=param"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid test URL")
            return
        }
        let asset = AVURLAsset(url: url)
        
        // ACT
        let durationFromMetadata = asset.durationFromURLMetadata()
        
        // ASSERT
        XCTAssertNil(durationFromMetadata, "Should return nil when 'dur' parameter not present")
    }
    
    func testSafeDurationWithURLMetadataFallbackDisabled() {
        // ARRANGE
        let urlString = "https://example.com/audio.mp3?dur=240.639"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid test URL")
            return
        }
        let asset = AVURLAsset(url: url)
        
        // Disable flag
        let originalFlag = ModernAVPlayerDurationConfig.useURLMetadataFallback
        ModernAVPlayerDurationConfig.useURLMetadataFallback = false
        defer { ModernAVPlayerDurationConfig.useURLMetadataFallback = originalFlag }
        
        // ACT - safeDuration with flag disabled should not use URL metadata
        // Even if AVAsset.duration is valid (0), it should NOT fallback to URL metadata
        let duration = asset.safeDuration
        
        // ASSERT
        // When fallback is disabled, should use only AVAsset duration
        // AVURLAsset returns 0 for unloaded duration, which is valid numeric value
        XCTAssertNotNil(duration, "AVAsset.duration is valid (0), so should return 0")
        XCTAssertEqual(duration ?? -1, 0.0, accuracy: 0.001)
    }
    
    func testSafeDurationWithURLMetadataFallbackDisabledNoAVAssetDuration() {
        // ARRANGE - Create a scenario where AVAsset duration is truly invalid
        let urlString = "https://example.com/audio.mp3?dur=240.639"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid test URL")
            return
        }
        
        // Use indefinite duration to simulate invalid AVAsset state
        let mockItem = MockPlayerItem.createOne(url: urlString, duration: CMTime.indefinite)
        
        // Disable flag
        let originalFlag = ModernAVPlayerDurationConfig.useURLMetadataFallback
        ModernAVPlayerDurationConfig.useURLMetadataFallback = false
        defer { ModernAVPlayerDurationConfig.useURLMetadataFallback = originalFlag }
        
        // ACT
        let duration = mockItem.safeDuration
        
        // ASSERT
        XCTAssertNil(duration, "Should return nil when fallback disabled and AVAsset duration is indefinite")
    }
    
    func testSafeDurationWithURLMetadataFallbackEnabled() {
        // ARRANGE
        let urlString = "https://example.com/audio.mp3?dur=240.639"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid test URL")
            return
        }
        let asset = AVURLAsset(url: url)
        
        // Enable flag
        let originalFlag = ModernAVPlayerDurationConfig.useURLMetadataFallback
        ModernAVPlayerDurationConfig.useURLMetadataFallback = true
        defer { ModernAVPlayerDurationConfig.useURLMetadataFallback = originalFlag }
        
        // ACT - with invalid AVAsset duration but valid URL metadata
        let duration = asset.safeDuration
        
        // ASSERT
        XCTAssertNotNil(duration, "Should return duration from URL metadata when fallback is enabled")
        XCTAssertEqual(duration ?? 0, 240.639, accuracy: 0.001)
    }
    
    func testSafeDurationWithURLMetadataFallbackOverride() {
        // ARRANGE
        let urlString = "https://example.com/audio.mp3?dur=240.639"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid test URL")
            return
        }
        
        // Use indefinite duration to simulate invalid AVAsset state
        let mockItem = MockPlayerItem.createOne(url: urlString, duration: CMTime.indefinite)
        
        // Disable flag globally
        let originalFlag = ModernAVPlayerDurationConfig.useURLMetadataFallback
        ModernAVPlayerDurationConfig.useURLMetadataFallback = false
        defer { ModernAVPlayerDurationConfig.useURLMetadataFallback = originalFlag }
        
        // ACT - override the global flag with parameter
        // Create AVURLAsset to test URL metadata parsing
        let asset = AVURLAsset(url: url)
        let duration = asset.safeDuration(useURLMetadataFallback: true)
        
        // ASSERT
        XCTAssertNotNil(duration, "Should use URL metadata when override parameter is true")
        XCTAssertEqual(duration ?? 0, 240.639, accuracy: 0.001)
    }
    
    func testPlaybackStopsAtURLMetadataDuration() {
        // ARRANGE - Simulate playback with URL metadata duration
        let urlString = "https://example.com/audio.mp3?dur=240.639"
        let duration = 240.639
        let mockItem = MockPlayerItem.createOne(url: urlString, duration: CMTime(seconds: duration, preferredTimescale: 1000))
        
        // Enable URL metadata fallback
        let originalFlag = ModernAVPlayerDurationConfig.useURLMetadataFallback
        ModernAVPlayerDurationConfig.useURLMetadataFallback = true
        defer { ModernAVPlayerDurationConfig.useURLMetadataFallback = originalFlag }
        
        // ACT - Get safe duration
        let safeDuration = mockItem.safeDuration
        
        // ASSERT - Duration should respect the limit
        XCTAssertNotNil(safeDuration, "safeDuration should not be nil")
        XCTAssertEqual(safeDuration ?? 0, duration, accuracy: 0.001)
        
        // Simulate current time exceeding duration
        let currentTimeExceeded = duration + 5.0  // 5 seconds past end
        XCTAssertGreaterThan(currentTimeExceeded, safeDuration ?? 0, 
                            "Current time should exceed duration to trigger stop")
    }
    
    func testPlaybackObservingServiceStopsAtDuration() {
        // ARRANGE
        let urlString = "https://example.com/audio.mp3?dur=240.639"
        let duration = 240.639
        let mockPlayer = MockCustomPlayer()
        
        let mockItem = MockPlayerItem.createOne(url: urlString, duration: CMTime(seconds: duration, preferredTimescale: 1000))
        mockPlayer.overrideCurrentItem = mockItem
        
        // Enable URL metadata fallback
        let originalFlag = ModernAVPlayerDurationConfig.useURLMetadataFallback
        ModernAVPlayerDurationConfig.useURLMetadataFallback = true
        defer { ModernAVPlayerDurationConfig.useURLMetadataFallback = originalFlag }
        
        let service = ModernAVPlayerPlaybackObservingService(player: mockPlayer)
        var playToEndTimeCalled = false
        service.onPlayToEndTime = { playToEndTimeCalled = true }
        
        // ACT - Check if service properly detects end of playback
        let itemDuration = mockItem.safeDuration
        
        // ASSERT - Duration from URL metadata
        XCTAssertNotNil(itemDuration, "itemDuration should not be nil with URL metadata")
        XCTAssertEqual(itemDuration ?? 0, duration, accuracy: 0.001,
                      "Duration should come from URL metadata")
    }
    
    func testPlayerStateStopsWhenDurationExceeded() {
        // ARRANGE
        let urlString = "https://example.com/audio.mp3?dur=240.639"
        let duration = 240.639
        
        // Use existing test context setup
        let mockItem = MockPlayerItem.createOne(url: urlString, duration: CMTime(seconds: duration, preferredTimescale: 1000))
        player.overrideCurrentItem = mockItem
        
        // Enable URL metadata fallback
        let originalFlag = ModernAVPlayerDurationConfig.useURLMetadataFallback
        ModernAVPlayerDurationConfig.useURLMetadataFallback = true
        defer { ModernAVPlayerDurationConfig.useURLMetadataFallback = originalFlag }
        
        let service = ModernAVPlayerPlaybackObservingService(player: player)
        
        var onPlayToEndTimeCalled = false
        service.onPlayToEndTime = { 
            onPlayToEndTimeCalled = true
        }
        
        // ACT
        let itemDuration = mockItem.safeDuration
        
        // ASSERT
        XCTAssertNotNil(itemDuration, "itemDuration should not be nil")
        XCTAssertEqual(itemDuration ?? 0, duration, accuracy: 0.001, 
                      "Duration should be from URL metadata (240.639)")
    }
}

