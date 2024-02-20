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
        let tmpzip = { NSTemporaryDirectory() + "/SkipZipTests-\(UUID().uuidString).zip" }
        let path = tmpzip()
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

        // Note: creating zip files on an Android device/emulator makes different checksum bytes for some reason.
        // this doesn't happen in Robolectric
        do {
            let path = tmpzip()
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: false))
            try archive.add(path: "some_data.dat", data: Data(), compression: 0)
            try archive.close()

            if isAndroid {
                XCTAssertEqual("642ee30cac228a4538457446d25f66d172ac111e6893ab3d1bdef4a80ef06f63", try checksum(path))
            } else {
                XCTAssertEqual("c455b4bc51accc2bf848194cdd10baa1b6492d79bc27f88dcd365464c04180f8", try checksum(path))
            }
        }


        do {
            let path = tmpzip()
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: false))
            try archive.add(path: "some_data.dat", data: String(repeating: "X", count: 100).data(using: .utf8)!, compression: 0)
            try archive.close()

            if isAndroid {
                XCTAssertEqual("9f778c1d4becd04fe327c13a3db37b12fb5a1cf9ca7a7062e5dfd02ffeaa46f1", try checksum(path))
            } else {
                XCTAssertEqual("3ed31b12d827318ea678b1adf8ef05ca52dcc9c75209f14c64cb5e3a4c2b5be2", try checksum(path))
            }
        }

        do {
            let path = tmpzip()
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: false))
            try archive.add(path: "/path/to/some_data.dat", data: String(repeating: "X", count: 100).data(using: .utf8)!, compression: 0)
            try archive.close()

            if isAndroid {
                XCTAssertEqual("05e52fb26e62b60b12dcd9839965e29f8db7e5c7750f59da00979002cc5849bf", try checksum(path))
            } else {
                XCTAssertEqual("ce93ab75d2c1057669ec2e55a760fb85fde3324a8da7d698fcb6bbcda359ea98", try checksum(path))
            }
        }

        do {
            let path = tmpzip()
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: false))
            try archive.add(path: "/path/to/some_data.dat", data: String(repeating: "Z", count: 1024).data(using: .utf8)!, compression: 5)
            try archive.close()

            if isAndroid {
                XCTAssertEqual("c93cc57102e583def79bbf31bb5385f7ff6d964edaa603054e1f7bd27fc0615c", try checksum(path))
            } else {
                XCTAssertEqual("56115d21accbc3cf13916927bfddf94d3c64aadc5fbb1b374d14e295a77c0cc3", try checksum(path))
            }
        }

        do {
            let path = tmpzip()
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: false))
            try archive.add(path: "/path/to/some_data.dat", data: String(repeating: "R", count: 1024).data(using: .utf8)!, comment: "Some comment", compression: 7)
            try archive.close()

            if isAndroid {
                XCTAssertEqual("cba09d90b2aae0d0b833c52a578dd0059830c523e718e9a1bdfd36ddffec99ee", try checksum(path))
            } else {
                XCTAssertEqual("8388ee330a69a5badb74dd0713ffd73b97671d7c25304aa51c5b1d74cff93ff1", try checksum(path))
            }
        }

        do {
            let path = tmpzip()
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: false))
            try archive.add(path: "/path/to/some_data.dat", data: String(repeating: "Q", count: 1024 * 1024).data(using: .utf8)!, compression: 9)
            try archive.close()

            if isAndroid {
                XCTAssertEqual("b4309b6c4ba78a7466dfbb98d34f12f868c3005cff1cea7f519c9f463dee607c", try checksum(path))
            } else {
                XCTAssertEqual("d7c50875f4ca98658e69016dd6245599b76e2368719b477ca80c7f934c7c2cfb", try checksum(path))
            }
        }

        do {
            let path = tmpzip()
            let archive = try XCTUnwrap(ZipArchive(pathForWriting: path, append: false))
            try archive.add(path: "some_file", data: "ABC".data(using: .utf8)!, compression: 0)
            try archive.add(path: "//////some_text_with_comment", data: "QRS".data(using: .utf8)!, comment: "This is a comment", compression: 5)
            try archive.add(path: "/path/to/some_data.dat", data: String(repeating: "X", count: 1024 * 1024).data(using: .utf8)!, compression: 9)
            try archive.close()

            if isAndroid {
                XCTAssertEqual("6715381108a66dcfe9be6c41565e66dd2fa1e43cc8897a43c21d56ffbccdb702", try checksum(path))
            } else {
                XCTAssertEqual("f527567e6463f98c209d68fbea0fb71690611b3eb3cd8778449e3c245ef4cbb8", try checksum(path))
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
