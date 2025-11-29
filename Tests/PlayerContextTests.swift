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
import ModernAVPlayer
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
        print("current", currentItem?.duration.seconds)
        let totalDuration = currentItem?.duration.seconds ?? 0

        // ASSERT
        XCTAssertEqual(totalDuration, expectedDuration, accuracy: 0.001)
    }

    func testTotalDurationFromRealURL() {
        // ARRANGE
        let url = "https://rr3---sn-8qj-jmgl.googlevideo.com/videoplayback?expire=1764442810&ei=Wu4qacDSOvOW1d8Pua6eiAo&ip=123.19.25.115&id=o-AE6unX5b7ujkP0zUXdVG9yoZQnncst365PEnBj3Tp6SM&itag=140&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&cps=301&met=1764421210,&mh=wp&mm=31,29&mn=sn-8qj-jmgl,sn-i3belne6&ms=au,rdu&mv=m&mvi=3&pl=25&rms=au,au&gcr=vn&initcwndbps=2507500&bui=AdEuB5RzaWCz0Wp_39nUuofu5nVhocxmqs0ejaGLhMuZqW6yeHRg2m0zTNza0U_HfNZYU098vrzEYHgd&vprv=1&svpuc=1&mime=audio/mp4&ns=O68K2G26rQmiqwF_hZeHDOcQ&rqh=1&gir=yes&clen=3896503&dur=240.639&lmt=1761961515347015&mt=1764420796&fvip=5&keepalive=yes&lmw=1&fexp=51557447,51565116,51565682,51580970&c=TVHTML5&sefc=1&txp=5532534&n=4s40YI3cCOgH4A&sparams=expire,ei,ip,id,itag,source,requiressl,xpc,gcr,bui,vprv,svpuc,mime,ns,rqh,gir,clen,dur,lmt&lsparams=cps,met,mh,mm,mn,ms,mv,mvi,pl,rms,initcwndbps&lsig=APaTxxMwRAIgQ9RI8oKEBUsS2rWXeaq-ViPGuDql6Op0gIguQ-gm1hkCIEV5C-APwR6Yo66zNixcrMSPONDJl-1EiPOYu0HAuJUE&sig=AJfQdSswRgIhAOmlSkmtLu27WbVGJ5CCW-MA7xwzbLIjZ0UgCyjdjzHjAiEA3NTJT1MnmuUpYSCXYSRbhJ3G23ujvkr06VW_C3wNQgY%3D"
        guard let mediaURL = URL(string: url) else {
            XCTFail("Invalid URL")
            return
        }
        
        let expectation = XCTestExpectation(description: "Duration loaded from URL")
        let asset = AVAsset(url: mediaURL)
        
        // ACT & ASSERT
        asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            
            DispatchQueue.main.async {
                XCTAssertEqual(status, .loaded, "Duration key should be loaded")
                XCTAssertNil(error, "Should have no error loading duration")
                
                let duration = asset.duration.seconds
                print("Real URL duration: \(duration) seconds (\(Int(duration / 60))m \(Int(duration.truncatingRemainder(dividingBy: 60)))s)")
                
                // Verify duration is valid
                XCTAssertGreaterThan(duration, 0, "Duration should be greater than 0")
                XCTAssertLessThan(duration, 3600, "Duration should be less than 1 hour")
                XCTAssertGreaterThan(duration, 240, "Duration should be more than 240 seconds")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
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
}
