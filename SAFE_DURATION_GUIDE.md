# Safe Duration Usage Guide

## Khi nào dùng `safeDuration` (default behavior)

**Dùng `asset.safeDuration` KHÔNG có parameter khi:**

1. **Lấy duration từ AVPlayerItem (recommended)**
   ```swift
   let duration = player.currentItem?.safeDuration
   ```
   - ✅ AVPlayerItem đã được load bởi AVPlayer
   - ✅ Duration là chính xác từ media file parsing
   - ✅ Không cần fallback

2. **Load AVAsset + await completion**
   ```swift
   asset.loadValuesAsynchronously(forKeys: ["duration"]) {
       let duration = asset.safeDuration  // Đã load xong
   }
   ```
   - ✅ Duration đã được load từ file
   - ✅ Chính xác 100%

3. **Tất cả file-based URLs**
   ```swift
   let fileURL = Bundle.main.url(forResource: "audio", withExtension: "mp3")!
   let asset = AVURLAsset(url: fileURL)
   // Synchronously sau khi load
   let duration = asset.safeDuration
   ```

4. **Streaming URLs khi AVAsset parse được metadata**
   ```swift
   // Sau khi server gửi complete MP4 headers
   let duration = asset.safeDuration
   ```

---

## Khi nào enable `useURLMetadataFallback` flag

**Enable flag khi streaming URL có query parameter duration:**

### 1. **Enable Globally** (nếu hầu hết URLs đều có `dur` param)
```swift
// App startup / AppDelegate
ModernAVPlayerDurationConfig.useURLMetadataFallback = true

// Sau đó tất cả safeDuration calls tự động fallback
let duration = asset.safeDuration  // Sẽ dùng URL metadata nếu cần
```

**Use case:** YouTube streaming URLs, HLS playlists with duration params
```
https://rr3---sn-8qj-jmgl.googlevideo.com/videoplayback?...&dur=240.639&...
```

### 2. **Enable Per-Call** (selective usage)
```swift
// Chỉ cho streaming URL này
let duration = streamingAsset.safeDuration(useURLMetadataFallback: true)

// File URL không cần fallback
let fileDuration = fileAsset.safeDuration  // Dùng default (no fallback)
```

**Use case:** Mix của file URLs và streaming URLs
```swift
if url.scheme == "https" || url.scheme == "http" {
    // Streaming URL - enable fallback
    return asset.safeDuration(useURLMetadataFallback: true)
} else {
    // File URL - no fallback needed
    return asset.safeDuration
}
```

---

## Priority & Fallback Logic

```
safeDuration(useURLMetadataFallback: true/false/nil)
    ↓
1️⃣ Try AVAsset.duration (if valid and numeric) → Return it ✅
    ↓ FAILED
2️⃣ If fallback ENABLED → Try URL "dur" parameter → Return it ✅
    ↓ FAILED
3️⃣ Return nil ❌
```

### Ví dụ:

```swift
let url = "https://example.com/audio.mp3?dur=240.639"
let asset = AVURLAsset(url: url)

// Scenario A: AVAsset.duration VALID (e.g., 480)
asset.safeDuration(useURLMetadataFallback: true)  // → 480 (use AVAsset)

// Scenario B: AVAsset.duration INVALID (e.g., indefinite), fallback ENABLED
asset.safeDuration(useURLMetadataFallback: true)  // → 240.639 (use URL)

// Scenario C: AVAsset.duration INVALID, fallback DISABLED
asset.safeDuration(useURLMetadataFallback: false) // → nil (no fallback)

// Scenario D: Both AVAsset and URL metadata exist, use AVAsset priority
asset.safeDuration(useURLMetadataFallback: true)  // → AVAsset value (priority)
```

---

## Current Project Usage

| File | Usage | Reason |
|------|-------|--------|
| `PlayerContext.swift` | `safeDuration` (no param) | AVPlayerItem always from player |
| `PlaybackObservingService.swift` | `safeDuration` (no param) | Duration already loaded by player |
| `ModernAVPlayerSeekService.swift` | `safeDuration` (no param) | Seek validation after load |
| `LoadedState.swift` | `safeDuration` (no param) | Media already loaded |
| Tests | Both modes tested | Verify fallback works |

---

## Decision Tree

```
START: Need to get duration?
    ↓
Is it AVPlayerItem (already playing)?
    YES → Use: item.safeDuration ✅
    ↓
    NO → Is it a streaming URL with 'dur' param?
        YES → Use: asset.safeDuration(useURLMetadataFallback: true) ✅
        ↓
        NO → Is it a file URL?
            YES → Use: asset.safeDuration ✅
            ↓
            NO → Uncertain format?
                → Use global flag + safeDuration ✅
```

---

## Recommendation

### For ModernAVPlayer library:
- **Default:** Keep `ModernAVPlayerDurationConfig.useURLMetadataFallback = false` (safer, no surprises)
- **Allow override:** Apps can enable globally if they know all URLs have `dur` param
- **Per-call override:** Maximum flexibility for edge cases

### Example in Application:
```swift
// App knows streaming URLs have dur parameter
ModernAVPlayerDurationConfig.useURLMetadataFallback = true

// Or selectively:
let duration = asset.safeDuration(useURLMetadataFallback: isStreamingURL)
```
