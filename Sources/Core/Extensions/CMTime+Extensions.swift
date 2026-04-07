// The MIT License (MIT)
//
// ModernAVPlayer
// Copyright (c) 2018 Raphael Ankierman <raphael.ankierman@radiofrance.com>
//
// CMTime+Extensions.swift
// Created by raphael ankierman on 17/03/2018.
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
import Foundation

extension CMTime {
    /// Safely converts CMTime to seconds if the time is valid and normal.
    var safeSeconds: Double? {
        guard isValid, isNumeric, !isIndefinite else { return nil }
        return seconds
    }
}

extension AVPlayerItem {
    /// Duration for player mechanics (slider, seeking, end-time detection).
    /// Must use AVFoundation's duration to stay consistent with currentTime timeline.
    var safeDuration: Double? {
        if ModernAVPlayerDurationConfig.useURLMetadataFallback,
           let asset = asset as? AVURLAsset {
            if let urlDuration = asset.durationFromURLMetadata() {
                return urlDuration
            }
        }

        return duration.safeSeconds
    }

    /// Duration for UI display only. Reads mp4 mdhd atom for local files
    /// (ground truth — AVFoundation reports 2x for DASH-produced files).
    /// Falls through to safeDuration if parsing fails.
    public var displayDuration: Double? {
        if let asset = asset as? AVURLAsset, asset.url.isFileURL {
            if let mdhdDuration = MP4DurationParser.durationFromFile(asset.url) {
                return mdhdDuration
            }
        }
        return safeDuration
    }
}

extension AVAsset {
    /// Duration for player mechanics. Uses AVFoundation to match currentTime timeline.
    var safeDuration: Double? {
        if ModernAVPlayerDurationConfig.useURLMetadataFallback {
            if let urlDuration = durationFromURLMetadata() {
                return urlDuration
            }
        }

        return duration.safeSeconds
    }

    /// Duration for UI display only. Reads mp4 mdhd atom for local files.
    public var displayDuration: Double? {
        if let urlAsset = self as? AVURLAsset, urlAsset.url.isFileURL {
            if let mdhdDuration = MP4DurationParser.durationFromFile(urlAsset.url) {
                return mdhdDuration
            }
        }
        return safeDuration
    }

    /// Extracts duration from URL metadata (e.g., 'dur' query parameter).
    func durationFromURLMetadata() -> Double? {
        guard let url = (self as? AVURLAsset)?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        if let durItem = queryItems.first(where: { $0.name == "dur" }),
           let durValue = durItem.value,
           let duration = Double(durValue) {
            return duration
        }

        return nil
    }

    /// Returns duration with URL metadata priority.
    func safeDuration(useURLMetadataFallback: Bool? = nil) -> Double? {
        let shouldUseURLMetadata = useURLMetadataFallback ?? ModernAVPlayerDurationConfig.useURLMetadataFallback

        if shouldUseURLMetadata {
            if let urlDuration = durationFromURLMetadata() {
                return urlDuration
            }
        }

        return duration.safeSeconds
    }
}
