import AVFoundation
@testable import ModernAVPlayer2
import XCTest

final class MP4DurationParserTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        MP4DurationParser.clearCache()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MP4DurationParserTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - isFragmentedMP4

    func testIsFragmentedMP4_withFragmentedFile_returnsTrue() {
        guard let url = fragmentedFileURL() else {
            XCTFail("Fragmented test file not found in bundle")
            return
        }
        XCTAssertTrue(MP4DurationParser.isFragmentedMP4(url))
    }

    func testIsFragmentedMP4_withNonFragmentedFile_returnsFalse() {
        guard let url = regularFileURL() else { return } // skip if no regular m4a in bundle
        XCTAssertFalse(MP4DurationParser.isFragmentedMP4(url))
    }

    func testIsFragmentedMP4_withNonExistentFile_returnsFalse() {
        let url = tempDir.appendingPathComponent("does_not_exist.mp3")
        XCTAssertFalse(MP4DurationParser.isFragmentedMP4(url))
    }

    func testIsFragmentedMP4_withRemoteURL_returnsFalse() {
        let url = URL(string: "https://example.com/audio.mp3")!
        XCTAssertFalse(MP4DurationParser.isFragmentedMP4(url))
    }

    // MARK: - defragment

    func testDefragment_producesNonFragmentedOutput() {
        guard let source = fragmentedFileURL() else {
            XCTFail("Fragmented test file not found in bundle")
            return
        }

        let destination = tempDir.appendingPathComponent("output.m4a")
        let expectation = expectation(description: "defragment completes")

        MP4DurationParser.defragment(source: source, destination: destination) { success in
            XCTAssertTrue(success, "Defragment should succeed")
            XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path), "Output file should exist")
            XCTAssertFalse(MP4DurationParser.isFragmentedMP4(destination), "Output should not be fragmented")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func testDefragment_preservesDuration() {
        guard let source = fragmentedFileURL() else {
            XCTFail("Fragmented test file not found in bundle")
            return
        }

        let sourceDuration = MP4DurationParser.durationFromFile(source)
        XCTAssertNotNil(sourceDuration, "Source should have parseable duration")

        let destination = tempDir.appendingPathComponent("output.m4a")
        let expectation = expectation(description: "defragment completes")

        MP4DurationParser.defragment(source: source, destination: destination) { success in
            XCTAssertTrue(success)

            // Compare via mdhd (ground truth), not AVFoundation which has DASH duration bug
            MP4DurationParser.clearCache()
            let outputDuration = MP4DurationParser.durationFromFile(destination)
            XCTAssertNotNil(outputDuration)
            XCTAssertEqual(outputDuration!, sourceDuration!, accuracy: 0.5,
                           "mdhd duration should be preserved after defragment")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func testDefragment_nonFragmentedFile_returnsFalse() {
        // Create a dummy non-mp4 file
        let source = tempDir.appendingPathComponent("plain.txt")
        try? "hello".data(using: .utf8)?.write(to: source)
        let destination = tempDir.appendingPathComponent("output.m4a")

        let expectation = expectation(description: "defragment completes")

        MP4DurationParser.defragment(source: source, destination: destination) { success in
            XCTAssertFalse(success, "Non-fragmented file should return false")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testDefragment_sourceDoesNotExist_returnsFalse() {
        let source = tempDir.appendingPathComponent("nope.mp3")
        let destination = tempDir.appendingPathComponent("output.m4a")

        let expectation = expectation(description: "defragment completes")

        MP4DurationParser.defragment(source: source, destination: destination) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    // MARK: - durationFromFile

    func testDurationFromFile_returnsCorrectDuration() {
        guard let url = fragmentedFileURL() else {
            XCTFail("Fragmented test file not found in bundle")
            return
        }

        let duration = MP4DurationParser.durationFromFile(url)
        XCTAssertNotNil(duration)
        XCTAssertEqual(duration!, 240.64, accuracy: 0.01,
                       "mdhd should report ~240.64s for the test file")
    }

    func testDurationFromFile_cacheWorks() {
        guard let url = fragmentedFileURL() else { return }

        let first = MP4DurationParser.durationFromFile(url)
        let second = MP4DurationParser.durationFromFile(url)
        XCTAssertEqual(first, second)
    }

    // MARK: - Helpers

    /// Returns the fragmented DASH test file from the test bundle or Example directory.
    private func fragmentedFileURL() -> URL? {
        // Try test bundle first
        if let path = Bundle(for: type(of: self)).path(forResource: "Take Me to Your Heart", ofType: "mp3") {
            return URL(fileURLWithPath: path)
        }
        // Fallback to project Example directory
        let projectFile = URL(fileURLWithPath: "/Users/mdlabs/Downloads/ModernAVPlayer-2025/Example/Take Me to Your Heart.mp3")
        if FileManager.default.fileExists(atPath: projectFile.path) {
            return projectFile
        }
        return nil
    }

    /// Returns a non-fragmented audio file if available.
    private func regularFileURL() -> URL? {
        if let path = Bundle(for: type(of: self)).path(forResource: "SampleA", ofType: "mp3") {
            return URL(fileURLWithPath: path)
        }
        let projectFile = URL(fileURLWithPath: "/Users/mdlabs/Downloads/ModernAVPlayer-2025/Example/SampleA.mp3")
        if FileManager.default.fileExists(atPath: projectFile.path) {
            return projectFile
        }
        return nil
    }
}
