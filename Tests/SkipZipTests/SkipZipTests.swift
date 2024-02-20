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

final class SkipZipTests: XCTestCase {
    func testArchive() throws {
        func tmpzip() -> String {
            let path = URL.temporaryDirectory.path + "/SkipZipTests-\(UUID().uuidString).zip"
            logger.log("testing zip archive at: \(path)")
            return path
        }

        do {
            let path = tmpzip()

            XCTAssertNil(ZipWriter(path: path, append: true), "append to non-existent file should return nil")
            XCTAssertNotNil(ZipWriter(path: path, append: false), "non-append open to non-existent file should not return nil")
            XCTAssertNotNil(ZipWriter(path: path, append: true), "append to existing file should not return nil")

            do {
                let writer = try XCTUnwrap(ZipWriter(path: path, append: true))
                try writer.close()
                XCTAssertEqual(Int64(22), try fileSize(path))
                XCTAssertEqual("8739c76e681f900923b900c9df0ef75cf421d39cabb54650c4b9ad19b6a76d85", try checksum(path))
            }

            do {
                let writer = try XCTUnwrap(ZipWriter(path: path, append: true))
                try writer.close()
                XCTAssertEqual(Int64(44), try fileSize(path))
                XCTAssertEqual("fec6899e1163a2371293fe6cca0427345a0ab29da4b396924b06a6f014c2099e", try checksum(path))
            }

            do {
                let writer = try XCTUnwrap(ZipWriter(path: path, append: true))
                try writer.close()
                XCTAssertEqual(Int64(66), try fileSize(path))
                XCTAssertEqual("ca3407bb56b41a27cb80c1b768d6db0868967f25ea6d0d257afc452357b80e88", try checksum(path))
            }
        }

        // Note: creating zip files on an Android device/emulator makes different checksum bytes for some reason.
        // this doesn't happen in Robolectric
        do {
            let path = tmpzip()
            let writer = try XCTUnwrap(ZipWriter(path: path, append: false))
            try writer.add(path: "some_data.dat", data: Data(), compression: 0)
            try writer.close()
            XCTAssertEqual(Int64(188), try fileSize(path))
            XCTAssertEqual("de60c56ec8dd5f84906fafff3b7044e5985b35c141bfe90b7950baf2c32e19f0", try checksum(path))
            let reader = try XCTUnwrap(ZipReader(path: path))
            try reader.close()
        }


        do {
            let path = tmpzip()
            let writer = try XCTUnwrap(ZipWriter(path: path, append: false))
            try writer.add(path: "some_data.dat", data: String(repeating: "X", count: 100).data(using: .utf8)!, compression: 0)
            try writer.close()
            XCTAssertEqual(Int64(288), try fileSize(path))
            XCTAssertEqual("7c2391484637af99fea7cba7e7125a7820fc49aa5c520b207b1cf19b0b34856a", try checksum(path))
            let reader = try XCTUnwrap(ZipReader(path: path))
            try reader.close()
        }

        do {
            let path = tmpzip()
            let writer = try XCTUnwrap(ZipWriter(path: path, append: false))
            try writer.add(path: "/path/to/some_data.dat", data: String(repeating: "X", count: 100).data(using: .utf8)!, compression: 0)
            try writer.close()
            XCTAssertEqual(Int64(306), try fileSize(path))
            XCTAssertEqual("ada02320bec7a9b0c4d7fe29d9a3ad335903823500a4e0bce7d3a281cb618449", try checksum(path))
            let reader = try XCTUnwrap(ZipReader(path: path))
            try reader.close()
        }

        do {
            let path = tmpzip()
            let writer = try XCTUnwrap(ZipWriter(path: path, append: false))
            try writer.add(path: "/path/to/some_data.dat", data: String(repeating: "Z", count: 1024).data(using: .utf8)!, compression: 5)
            try writer.close()
            XCTAssertEqual(Int64(217), try fileSize(path))
            XCTAssertEqual("7229f978740cc3d30ef44f5f8ff0423700f20f71d39137afdd55076c344765c8", try checksum(path))
            let reader = try XCTUnwrap(ZipReader(path: path))
            try reader.close()
        }

        do {
            let path = tmpzip()
            let writer = try XCTUnwrap(ZipWriter(path: path, append: false))
            try writer.add(path: "/path/to////some_data.dat", data: String(repeating: "R", count: 1024).data(using: .utf8)!, comment: "Some comment", compression: 7)
            try writer.close()
            XCTAssertEqual("a34551de2648bf4d40e291094b9cfc68e6918f39537699c90079af2f097ab583", try checksum(path))
            let reader = try XCTUnwrap(ZipReader(path: path))
            try reader.close()
        }

        do {
            let path = tmpzip()
            let writer = try XCTUnwrap(ZipWriter(path: path, append: false))
            try writer.add(path: "/path/to/some_data.dat", data: String(repeating: "官", count: 1024 * 1024).data(using: .utf8)!, compression: 9)
            try writer.close()
            XCTAssertEqual(Int64(3277), try fileSize(path))
            XCTAssertEqual("314c1575f6a59b831b4e843e1056cc7699b729e8c3378406b01ec3f97f24ce4a", try checksum(path))
            let reader = try XCTUnwrap(ZipReader(path: path))
            try reader.close()
        }

        do {
            let path = tmpzip()
            let writer = try XCTUnwrap(ZipWriter(path: path, append: false))
            try writer.add(path: "some_file", data: "ABC".data(using: .utf8)!, compression: 0)
            try writer.add(path: "//////some_text_with_comment", data: "QRS".data(using: .utf8)!, comment: "This is a comment", compression: 5)
            try writer.add(path: "/path/to/some_data.dat", data: String(repeating: "X", count: 1024 * 1024).data(using: .utf8)!, compression: 9)
            try writer.close()
            XCTAssertEqual("3836c5b75d69ee311c1aa3b92db3d72b9cadeb659258c426c904973afc38d9b4", try checksum(path))
            XCTAssertEqual(Int64(1619), try fileSize(path))

            let reader = try XCTUnwrap(ZipReader(path: path))
            XCTAssertEqual(Int64(1323), reader.currentOffset)

            try reader.first()
            XCTAssertEqual(Int64(1323), reader.currentOffset)
            XCTAssertTrue(try reader.next())
            XCTAssertEqual(Int64(1398), reader.currentOffset)
            //XCTAssertEqual("some_file", reader.currentFileName) // TODO: read file path
            //XCTAssertEqual("ABC".data(using: .utf8), reader.currentData) // TODO: read file data
            XCTAssertTrue(try reader.next())
            XCTAssertEqual(Int64(1509), reader.currentOffset)
            XCTAssertFalse(try reader.next())
            XCTAssertEqual(Int64(1597), reader.currentOffset)
            XCTAssertFalse(try reader.next())
            XCTAssertEqual(Int64(1643), reader.currentOffset)
            XCTAssertFalse(try reader.next())
            XCTAssertEqual(Int64(1689), reader.currentOffset)

            try reader.first()
            XCTAssertEqual(Int64(1323), reader.currentOffset)
            XCTAssertTrue(try reader.next())
            XCTAssertEqual(Int64(1398), reader.currentOffset)
            XCTAssertTrue(try reader.next())
            XCTAssertEqual(Int64(1509), reader.currentOffset)
            XCTAssertFalse(try reader.next())
            XCTAssertEqual(Int64(1597), reader.currentOffset)
            XCTAssertFalse(try reader.next())
            XCTAssertEqual(Int64(1643), reader.currentOffset)
            XCTAssertFalse(try reader.next())
            XCTAssertEqual(Int64(1689), reader.currentOffset)

            try reader.close()
        }
    }

    func checksum(_ path: String) throws -> String {
        try Data(contentsOf: URL(fileURLWithPath: path)).sha256().hex()
    }

    func fileSize(_ path: String) throws -> Int64? {
        try FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size] as? Int64
    }
}

#if !SKIP
/// A sequence that both `Data` and `String.UTF8View` conform to.
extension Sequence where Element == UInt8 {
    public func hex() -> String { map { String(format: "%02x", $0) }.joined() }
    public func base64() -> String { Data(self).base64EncodedString() }
    public func sha256() -> SHA256.Digest { CryptoKit.SHA256.hash(data: Data(self)) }
    public func sha384() -> SHA384.Digest { CryptoKit.SHA384.hash(data: Data(self)) }
    public func sha512() -> SHA512.Digest { CryptoKit.SHA512.hash(data: Data(self)) }
}
#endif
