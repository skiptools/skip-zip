// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import XCTest
import OSLog
import Foundation
import CryptoKit
import SkipZip

let logger: Logger = Logger(subsystem: "SkipZip", category: "Tests")

@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
final class SkipZipTests: XCTestCase {
    func testDeflateInflate() throws {
        logger.log("running test")
        let bytes = [0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04].map({ UInt8($0) })
        let data: Data = Data(bytes)

        func check(level: Int, crc32: UInt32? = nil, wrap: Bool) throws -> String {
            let (crc, compressed) = try data.deflate(level: level, wrap: wrap)
            if let crc32 = crc32 {
                XCTAssertEqual(crc, crc32)
            }

            let (crc2, decompressed) = try compressed.inflate(wrapped: wrap)
            XCTAssertEqual(data, decompressed)
            if let crc32 = crc32 {
                XCTAssertEqual(crc2, crc32)
            }

            return compressed.base64EncodedString()
        }

        // check the behavior of various zip compression levels
        _ = try check(level: 0, crc32: UInt32(1403640103), wrap: false)
        XCTAssertEqual("AbwAQ/8BAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAQIDBAMEAQIDBAMEAQIDBAMEAQIDBAMEAQIDBAMEAQIDBAMEAQIDBAMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAQIDBA==", try check(level: 0, wrap: false))
        XCTAssertEqual("Y2RiZmHEgSEyxJC4TMAnToy5uN0GMhkA", try check(level: 1, wrap: false))
        XCTAssertEqual("Y2RiZmHEgSEyxJC4TMAnToy5uN0GMhkA", try check(level: 2, wrap: false))
        XCTAssertEqual("Y2RiZmHEgSEyxJC4TMAnToy5uN0GMhkA", try check(level: 3, wrap: false))
        XCTAssertEqual("Y2RiZmHEgYknycHEk7gwAA==", try check(level: 4, wrap: false))
        XCTAssertEqual("Y2RiZmHEgYknycHEk7gwAA==", try check(level: 5, wrap: false))
        XCTAssertEqual("Y2RiZmHEgYknycGUmw4A", try check(level: 6, wrap: false))
        XCTAssertEqual("Y2RiZmHEgYknycGUmw4A", try check(level: 7, wrap: false))
        XCTAssertEqual("Y2RiZmHEgYknycGUmw4A", try check(level: 8, wrap: false))
        XCTAssertEqual("Y2RiZmHEgYknycGUmw4A", try check(level: 9, wrap: false))

        XCTAssertEqual("eAEBvABD/wECAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQDBAECAwQDBAECAwQDBAECAwQDBAECAwQDBAECAwQDBAECAwQDBAECAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAwQBAgMEAQIDBAECAwQBAgMEAQIDBAECAwQBAgMEt8IB8w==", try check(level: 0, wrap: true))
        XCTAssertEqual("eAFjZGJmYcSBITLEkLhMwCdOjLm43QYyGQC3wgHz", try check(level: 1, wrap: true))
        //XCTAssertEqual("eAFjZGJmYcSBITLEkLhMwCdOjLm43QYyGQC3wgHz", try check(level: 2, wrap: true))
        //XCTAssertEqual("eAFjZGJmYcSBITLEkLhMwCdOjLm43QYyGQC3wgHz", try check(level: 3, wrap: true))
        //XCTAssertEqual("eAFjZGJmYcSBiSfJwcSTuDAAt8IB8w==", try check(level: 4, wrap: true))
        #if SKIP
        XCTAssertEqual("eF5jZGJmYcSBiSfJwcSTuDAAt8IB8w==", try check(level: 5, wrap: true))
        #else
        XCTAssertEqual("eAFjZGJmYcSBiSfJwcSTuDAAt8IB8w==", try check(level: 5, wrap: true))
        #endif
        //XCTAssertEqual("eNpjZGJmYcSBiSfJwZSbDgC3wgHz", try check(level: 6, wrap: true))
        //XCTAssertEqual("eNpjZGJmYcSBiSfJwZSbDgC3wgHz", try check(level: 7, wrap: true))
        //XCTAssertEqual("eNpjZGJmYcSBiSfJwZSbDgC3wgHz", try check(level: 8, wrap: true))
        XCTAssertEqual("eNpjZGJmYcSBiSfJwZSbDgC3wgHz", try check(level: 9, wrap: true))
    }

    func testArchive() throws {
        #if SKIP
        throw XCTSkip("TODO: skip version of ZipArchive and necessary FS support")
        #endif

        /// Create a temporary directory
        func mktmp(baseName: String = "SkipZipTests") throws -> String {
            let tempDir = [NSTemporaryDirectory(), baseName, UUID().uuidString].joined(separator: "/")
            try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
            return tempDir
        }

        /// Zero the creation and mod time for consistent zipping
        func zeroTimes(url: URL) throws {
            //try FileManager.default.setAttributes([.creationDate: Date(timeIntervalSince1970: 0.0)], ofItemAtPath: url.path)
            try FileManager.default.setAttributes([FileAttributeKey.modificationDate: Date(timeIntervalSince1970: 0.0)], ofItemAtPath: url.path)
        }

        @discardableResult func createFileSystem(root: String? = nil, paths: [(path: String, data: Data)]) throws -> URL {
            let dir = try URL(fileURLWithPath: root ?? mktmp(), isDirectory: true)
            for (subpath, data) in paths {
                let fileURL = URL(fileURLWithPath: subpath, relativeTo: dir)
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: fileURL, options: .atomic)
            }
            #if !SKIP
            if let pathEnumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) {
                for path in pathEnumerator {
                    if let url = path as? URL {
                        try zeroTimes(url: url)
                    }
                }
            }
            #endif
            return dir
        }

        func roundtrip(checksum: String? = nil, level compressionLevel: Int = 5, _ contents: [(path: String, data: Data)]) throws {
            let dir = try createFileSystem(paths: contents)
            let archive = dir.appendingPathExtension("zip")
            #if !SKIP
            try FileManager.default.zipItem(at: dir, to: archive, shouldKeepParent: false, compressionLevel: compressionLevel, progress: nil)
            let unzipPath = dir.appendingPathExtension("unzip")
            try FileManager.default.unzipItem(at: archive, to: unzipPath)
            let size = try FileManager.default.attributesOfItem(atPath: archive.path)[FileAttributeKey.size]
            print("created archive: \(archive.path) \(size ?? 0)")
            for (path, data) in contents {
                //print("  checking path: \(path)")
                try XCTAssertEqual(Data(contentsOf: unzipPath.appendingPathComponent(path)), data, "contents differed for: \(path)")
            }

            if let checksum = checksum {
                XCTAssertEqual(checksum, try Data(contentsOf: archive).sha256().hex())
            }
            #endif
        }

        try roundtrip(checksum: "473a681c5ff0b3e3e72c092c69f48ac4adc946395c64618c50f8437f21fef946", level: 0, [ ("X", Data()) ])
        try roundtrip(checksum: "1ba21cfbe072b5fbfe7e4748d9ee864c9de5ed466523b96766b944b7c3b574d4", level: 5, [ ("X", Data()) ])
        try roundtrip(checksum: "1ba21cfbe072b5fbfe7e4748d9ee864c9de5ed466523b96766b944b7c3b574d4", level: 1, [ ("X", Data()) ])
        try roundtrip(checksum: "1ba21cfbe072b5fbfe7e4748d9ee864c9de5ed466523b96766b944b7c3b574d4", level: 9, [ ("X", Data()) ])

        func readme(count: Int) -> Data {
            var data = Data()
            for _ in 1...count {
                data.append(contentsOf: Data("The contents of the readme file".utf8))
            }

            return data
        }

        try roundtrip(checksum: "d20cc7bbf3e17485ca7eb02c183a18a9baf6ea733aaab8760964ea5dec4f2e69", level: 5, [
            ("README.md", readme(count: 1)),
            ("some/path/to/data.dat", Data([0x01, 0x02, 0x03].map({ UInt8($0) }))),
        ])

        try roundtrip(checksum: "d20cc7bbf3e17485ca7eb02c183a18a9baf6ea733aaab8760964ea5dec4f2e69", level: 9, [
            ("README.md", readme(count: 1)),
            ("some/path/to/data.dat", Data([0x01, 0x02, 0x03].map({ UInt8($0) }))),
        ])

        try roundtrip(checksum: "315617462cf786158d1ac3ed279022f44f4471310aa82436fa1632e783483299", level: 0, [
            ("README.md", readme(count: 1)),
            ("some/path/to/data.dat", Data([0x01, 0x02, 0x03].map({ UInt8($0) }))),
        ])


        try roundtrip(checksum: "dfed7b76aad31a6add75d0c4be0d56444836ecb7972e7ecbaa8d0a364b991ef8", level: 9, [
            ("README.md", readme(count: 10_000)),
            ("some/path/to/data.dat", Data([0x01, 0x02, 0x03].map({ UInt8($0) }))),
        ])
    }
}

#if !SKIP
/// A sequence that both `Data` and `String.UTF8View` conform to.
extension Sequence where Element == UInt8 {
    /// Returns this data as a base-64 encoded string
    public func base64() -> String {
        Foundation.Data(self).base64EncodedString()
    }

    /// Returns the contents of the Data as a hex string
    public func hex() -> String {
        map { String(format: "%02x", $0) }.joined()
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func sha256() -> SHA256.Digest {
        CryptoKit.SHA256.hash(data: Foundation.Data(self))
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func sha384() -> SHA384.Digest {
        CryptoKit.SHA384.hash(data: Foundation.Data(self))
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func sha512() -> SHA512.Digest {
        CryptoKit.SHA512.hash(data: Foundation.Data(self))
    }
}
#endif
