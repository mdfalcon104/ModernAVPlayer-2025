// The MIT License (MIT)
//
// ModernAVPlayer
// Copyright (c) 2025 mdfalcon104 <https://github.com/mdfalcon104>
//
// MP4DurationParser.swift
// Reads the authoritative duration from mp4/m4a container atoms (mdhd).
//
// AVFoundation can report incorrect duration for certain files, notably
// DASH-produced m4a (major_brand=dash, e.g. from Google/YouTube) where
// AVAsset.duration returns 2x the real value. This parser reads the
// ground-truth duration by traversing: moov → trak → mdia → mdhd.

import AVFoundation
import Foundation

/// Parses mp4/m4a container atoms to read the authoritative track duration.
/// For local files, this is always more reliable than AVFoundation's duration.
public struct MP4DurationParser {

    private static var cache: [String: Double] = [:]

    /// Returns the max track duration in seconds, or nil if parsing fails.
    /// Results are cached per URL.
    public static func durationFromFile(_ url: URL) -> Double? {
        let key = url.absoluteString
        if let cached = cache[key] { return cached }
        guard let duration = parseMdhd(url: url) else { return nil }
        cache[key] = duration
        return duration
    }

    public static func clearCache() {
        cache.removeAll()
    }

    /// Returns true if the file is a fragmented MP4 (has moof boxes at top level).
    public static func isFragmentedMP4(_ url: URL) -> Bool {
        guard url.isFileURL,
              let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { handle.closeFile() }
        let fileSize = handle.seekToEndOfFile()
        handle.seek(toFileOffset: 0)
        return findBox("moof", in: handle, from: 0, to: fileSize) != nil
    }

    /// Defragments a DASH fMP4 into a regular MP4 with a proper seek table.
    /// No re-encoding — passthrough remux only.
    ///
    /// - Parameters:
    ///   - source: Local fragmented MP4 file.
    ///   - destination: Output path (overwritten if exists). Use `.m4a` extension.
    ///   - completion: Called on main queue — `true` on success, `false` on failure or if not fragmented.
    public static func defragment(source: URL, destination: URL, completion: @escaping (Bool) -> Void) {
        guard source.isFileURL, isFragmentedMP4(source) else {
            completion(false)
            return
        }

        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            completion(false)
            return
        }
        try? FileManager.default.removeItem(at: destination)
        session.outputURL = destination
        session.outputFileType = .m4a
        session.exportAsynchronously {
            DispatchQueue.main.async {
                completion(session.status == .completed)
            }
        }
    }

    // MARK: - Internal

    private static func parseMdhd(url: URL) -> Double? {
        guard url.isFileURL else { return nil }
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { handle.closeFile() }

        let fileSize = handle.seekToEndOfFile()
        handle.seek(toFileOffset: 0)

        guard let moov = findBox("moov", in: handle, from: 0, to: fileSize) else { return nil }

        var maxDuration: Double = 0
        var found = false
        var offset = moov.contentStart

        while offset < moov.contentEnd {
            guard let trak = findBox("trak", in: handle, from: offset, to: moov.contentEnd) else { break }

            if let mdia = findBox("mdia", in: handle, from: trak.contentStart, to: trak.contentEnd),
               let mdhd = findBox("mdhd", in: handle, from: mdia.contentStart, to: mdia.contentEnd),
               let dur = readMdhdDuration(handle, start: mdhd.contentStart, end: mdhd.contentEnd) {
                maxDuration = max(maxDuration, dur)
                found = true
            }

            offset = trak.contentEnd
        }

        return found ? maxDuration : nil
    }

    // MARK: - Box traversal

    private struct Box {
        let contentStart: UInt64
        let contentEnd: UInt64
    }

    /// Finds the first box with the given 4-char name within [from, to).
    private static func findBox(_ name: String, in handle: FileHandle, from: UInt64, to: UInt64) -> Box? {
        var offset = from
        let nameBytes = [UInt8](name.utf8)
        guard nameBytes.count == 4 else { return nil }

        while offset + 8 <= to {
            handle.seek(toFileOffset: offset)
            guard let header = read(handle, count: 8) else { return nil }

            let size = UInt64(header.mp4_u32BE(at: 0))
            let type = [header[4], header[5], header[6], header[7]]

            var headerLen: UInt64 = 8
            var boxSize: UInt64

            if size == 1 {
                guard let ext = read(handle, count: 8) else { return nil }
                boxSize = ext.mp4_u64BE(at: 0)
                headerLen = 16
            } else if size == 0 {
                boxSize = to - offset
            } else {
                boxSize = size
            }

            guard boxSize >= headerLen else { return nil }

            if type == nameBytes {
                return Box(contentStart: offset + headerLen, contentEnd: min(offset + boxSize, to))
            }

            offset += boxSize
        }
        return nil
    }

    // MARK: - mdhd payload

    /// mdhd layout after box header:
    ///   version(1) + flags(3)
    ///   v0: creation(4) + modification(4) + timescale(4) + duration(4)
    ///   v1: creation(8) + modification(8) + timescale(4) + duration(8)
    private static func readMdhdDuration(_ handle: FileHandle, start: UInt64, end: UInt64) -> Double? {
        let size = end - start
        guard size >= 20 else { return nil }

        handle.seek(toFileOffset: start)
        guard let vf = read(handle, count: 4) else { return nil }
        let version = vf[0]

        let timescale: UInt32
        let duration: UInt64

        if version == 0 {
            guard size >= 24 else { return nil }
            guard read(handle, count: 8) != nil else { return nil }
            guard let ts = read(handle, count: 4) else { return nil }
            guard let dur = read(handle, count: 4) else { return nil }
            timescale = ts.mp4_u32BE(at: 0)
            duration = UInt64(dur.mp4_u32BE(at: 0))
        } else {
            guard size >= 36 else { return nil }
            guard read(handle, count: 16) != nil else { return nil }
            guard let ts = read(handle, count: 4) else { return nil }
            guard let dur = read(handle, count: 8) else { return nil }
            timescale = ts.mp4_u32BE(at: 0)
            duration = dur.mp4_u64BE(at: 0)
        }

        guard timescale > 0 else { return nil }
        let seconds = Double(duration) / Double(timescale)
        guard seconds.isFinite, seconds > 0 else { return nil }
        return seconds
    }

    // MARK: - I/O helper

    @discardableResult
    private static func read(_ handle: FileHandle, count: Int) -> Data? {
        let data = handle.readData(ofLength: count)
        return data.count == count ? data : nil
    }
}

// MARK: - Data big-endian helpers (prefixed to avoid collisions)

extension Data {
    func mp4_u32BE(at i: Int) -> UInt32 {
        guard i + 4 <= count else { return 0 }
        return subdata(in: i..<i+4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    }
    func mp4_u64BE(at i: Int) -> UInt64 {
        guard i + 8 <= count else { return 0 }
        return subdata(in: i..<i+8).withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
    }
}
