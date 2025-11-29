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
    /// Returns nil if the time is invalid, indefinite, or NaN.
    /// Per Apple documentation: checks isValid, isNumeric, and !isIndefinite
    var safeSeconds: Double? {
        guard isValid, isNumeric, !isIndefinite else { return nil }
        return seconds
    }
}

extension AVPlayerItem {
    /// Safely returns the duration in seconds if available.
    /// Returns nil if duration is not loaded or is invalid.
    /// Priority: URL metadata first (if enabled), then AVPlayerItem duration
    var safeDuration: Double? {
        // Try URL metadata first if enabled (from underlying asset)
        if ModernAVPlayerDurationConfig.useURLMetadataFallback,
           let asset = asset as? AVURLAsset {
            if let urlDuration = asset.durationFromURLMetadata() {
                return urlDuration
            }
        }
        
        // Fall back to AVPlayerItem duration
        return duration.safeSeconds
    }
}

extension AVAsset {
    /// Safely returns the duration in seconds if available.
    /// Returns nil if duration is not loaded or is invalid.
    /// Priority: URL metadata first (if enabled), then AVAsset duration
    var safeDuration: Double? {
        // Try URL metadata first if enabled
        if ModernAVPlayerDurationConfig.useURLMetadataFallback {
            if let urlDuration = durationFromURLMetadata() {
                return urlDuration
            }
        }
        
        // Fall back to AVAsset duration
        return duration.safeSeconds
    }
    
    /// Extracts duration from URL metadata (e.g., 'dur' query parameter).
    /// Useful for streaming URLs where AVAsset parsing may be inaccurate.
    /// - Returns: Duration in seconds from URL metadata, or nil if not available
    func durationFromURLMetadata() -> Double? {
        guard let url = (self as? AVURLAsset)?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        // Try to find 'dur' query parameter (common in streaming URLs)
        if let durItem = queryItems.first(where: { $0.name == "dur" }),
           let durValue = durItem.value,
           let duration = Double(durValue) {
            return duration
        }
        
        return nil
    }
    
    /// Returns duration with URL metadata priority.
    /// Note: The global flag ModernAVPlayerDurationConfig.useURLMetadataFallback controls whether URL metadata is checked first.
    /// - Parameter useURLMetadataFallback: If provided, overrides the global config flag
    /// - Returns: Duration in seconds, or nil if unavailable
    func safeDuration(useURLMetadataFallback: Bool? = nil) -> Double? {
        let shouldUseURLMetadata = useURLMetadataFallback ?? ModernAVPlayerDurationConfig.useURLMetadataFallback
        
        // Try URL metadata first (if enabled)
        if shouldUseURLMetadata {
            if let urlDuration = durationFromURLMetadata() {
                return urlDuration
            }
        }
        
        // Fall back to AVAsset duration
        return duration.safeSeconds
    }
}

