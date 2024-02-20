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
    func testArchive() throws {
        let path = NSTemporaryDirectory() + "/SkipZipTests-\(UUID().uuidString).zip"
        logger.log("testing zip archive at: \(path)")

        XCTAssertNil(ZipArchive(pathForWriting: path, append: true), "append to non-existent file should return nil")
        XCTAssertNotNil(ZipArchive(pathForWriting: path, append: false), "non-append open to non-existent file should not return nil")
        XCTAssertNotNil(ZipArchive(pathForWriting: path, append: true), "append to existing file should not return nil")

        do {
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: true))
            try archive.close()
            XCTAssertEqual("8739c76e681f900923b900c9df0ef75cf421d39cabb54650c4b9ad19b6a76d85", try checksum(path))
        }

        do {
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: true))
            try archive.close()
            XCTAssertEqual("fec6899e1163a2371293fe6cca0427345a0ab29da4b396924b06a6f014c2099e", try checksum(path))
        }

        do {
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: true))
            try archive.close()
            XCTAssertEqual("ca3407bb56b41a27cb80c1b768d6db0868967f25ea6d0d257afc452357b80e88", try checksum(path))
        }

        do {
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: true))
            try archive.add(path: "some_file", data: "ABC".data(using: .utf8)!, compression: 0)
            try archive.add(path: "//////some_text_with_comment", data: "QRS".data(using: .utf8)!, comment: "This is a comment", compression: 5)
            try archive.add(path: "/path/to/some_data.dat", data: String(repeating: "X", count: 1024 * 1024).data(using: .utf8)!, compression: 9)
            try archive.close()
            // FIXME!
            if isAndroid {
                XCTAssertEqual("de3a91d1a14ba12441adf49be1ccdba4069f13b5acebea63e1f218e84660e61a", try checksum(path))
            } else {
                XCTAssertEqual("6040547eccbec82c650d7e2b87c7cc0bd6a78d011ba0edfe94f13ab5c8f0a63d", try checksum(path))
            }
        }
    }

    func checksum(_ path: String) throws -> String {
        try Data(contentsOf: URL(fileURLWithPath: path)).sha256().hex()
    }
}

#if !SKIP
/// A sequence that both `Data` and `String.UTF8View` conform to.
extension Sequence where Element == UInt8 {
    public func base64() -> String { Data(self).base64EncodedString() }
    public func hex() -> String { map { String(format: "%02x", $0) }.joined() }
    public func sha256() -> SHA256.Digest { CryptoKit.SHA256.hash(data: Data(self)) }
    public func sha384() -> SHA384.Digest { CryptoKit.SHA384.hash(data: Data(self)) }
    public func sha512() -> SHA512.Digest { CryptoKit.SHA512.hash(data: Data(self)) }
}
#endif
