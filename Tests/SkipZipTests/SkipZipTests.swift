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
            XCTAssertEqual("some_file", try reader.currentEntryName)
            XCTAssertEqual(nil, try reader.currentEntryComment)

            XCTAssertTrue(try reader.next())
            XCTAssertEqual(Int64(1398), reader.currentOffset)
            XCTAssertEqual("//////some_text_with_comment", try reader.currentEntryName)
            XCTAssertEqual("This is a comment", try reader.currentEntryComment)
            XCTAssertEqual("QRS".data(using: .utf8)!, try reader.currentEntryData)

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

    func tmpzip(named: String? = nil) -> String {
        let path = URL.temporaryDirectory.path + "/" + (named ?? "SkipZipTests-\(UUID().uuidString).zip")
        logger.log("testing zip archive \(named ?? "NONE") at: \(path)")
        return path
    }

    func testSampleZipFiles() throws {

        func check(_ zipPath: String, _ expectedCount: Int, _ expectedEntries: [(name: String, contents: Data?)]? = nil) throws {
            let url = try XCTUnwrap(Bundle.module.url(forResource: zipPath, withExtension: nil))
            let path = tmpzip(named: zipPath)
            try Data(contentsOf: url).write(to: URL(fileURLWithPath: path)) // need to copy out the file, since Android resources are stored in the apk
            let reader = try XCTUnwrap(ZipReader(path: path))

            var entryIndex = 0
            // e.g., fails on CorruptSymbolicLinkErrorConditions
            while true {
                if let expectedEntries = expectedEntries, expectedEntries.count > entryIndex {
                    let (expectedName, expectedContents) = expectedEntries[entryIndex]
                    let currentEntryName = try reader.currentEntryName
                    XCTAssertEqual(expectedName, currentEntryName, "unexpected entry name for \(zipPath) #\(entryIndex) [size=\(currentEntryName?.count ?? -1)]: \(currentEntryName ?? "NONE")")
                    if let expectedContents = expectedContents {
                        // TODO: extract and compare contents
                    }
                }
                entryIndex += 1
                if (try? reader.next()) != true {
                    break
                }
            }
            try reader.close()

            if let expectedEntries = expectedEntries {
                XCTAssertEqual(entryIndex, expectedEntries.count, "zip file at \(zipPath) entry mismatch: \(entryIndex) vs. \(expectedEntries.count)")
            }
            XCTAssertEqual(expectedCount, entryIndex, "zip file at \(zipPath) entry mismatch: \(expectedCount) vs. \(entryIndex)")

        }

        //try check("Empty.zip", 1, [("", nil)]) // TODO: handle empty archives
        try check("hello.zip", 1, [("hello", "hello".data(using: .utf8))])
        try check("AESPasswordArchive.zip", 2, [("README.md", nil), ("LICENSE.txt", nil)])
        try check("AddDirectoryToArchiveWithZIP64LFHOffset.zip", 1, [("data.random", nil)])
        try check("AddEntryToArchiveWithZIP64LFHOffset.zip", 1, [("data.random", nil)])
        try check("Archive.zip", 2, [("LICENSE", nil), ("Readme.markdown", nil)])
        try check("ExtractPreferredEncoding.zip", 3, [("data/", nil), ("data/pic👨‍👩‍👧‍👦🎂.jpg", nil), ("data/Benoît.txt", nil)])

        try check("DetectEntryType.zip", 2, [("META-INF/", nil), ("META-INF/container.xml", nil)])
        try check("ArchiveAddCompressedEntryProgress.zip", 4, [(".DS_Store", nil), ("dir/", nil), ("original", nil), ("symlink", nil)])
        try check("ArchiveAddUncompressedEntryProgress.zip", 4, [(".DS_Store", nil), ("dir/", nil), ("original", nil), ("symlink", nil)])
        try check("ArchiveIteratorErrorConditions.zip", 1, [("test.txt", nil)])
        try check("CRC32Check.zip", 4, [(".DS_Store", nil), ("dir/", nil), ("original", nil), ("symlink", nil)])

        try check("ExtractUncompressedDataDescriptorArchive.zip", 1, [("empty.txt", nil)])
        try check("ExtractUncompressedEmptyFile.zip", 1, [("empty.txt", nil)])
        try check("ExtractUncompressedEntryCancelation.zip", 4, [(".DS_Store", nil), ("dir/", nil), ("original", nil), ("symlink", nil)])
        try check("ExtractUncompressedFolderEntries.zip", 4, [(".DS_Store", nil), ("dir/", nil), ("original", nil), ("symlink", nil)])
        try check("ExtractUncompressedFolderEntriesFromMemory.zip", 4, [(".DS_Store", nil), ("dir/", nil), ("original", nil), ("symlink", nil)])
        try check("ExtractUncompressedZIP64Entries.zip", 1, [("testExtractUncompressedZIP64Entries.png", nil)])
        try check("EntryIsCompressed.zip", 2, [("uncompressed", nil), ("compressed", nil)])
        try check("ExtractCompressedDataDescriptorArchive.zip", 2, [("-", nil), ("second.txt", nil)])
        try check("ExtractCompressedEntryCancelation.zip", 1, [("random", nil)])
        try check("ExtractCompressedZIP64Entries.zip", 1, [("testExtractCompressedZIP64Entries.png", nil)])
        try check("ExtractEncryptedArchiveErrorConditions.zip", 1, [("zip64/test.txt", nil)])
        try check("ExtractEntryWithZIP64DataDescriptor.zip", 1, [("simple.data", nil)])
        try check("ExtractErrorConditions.zip", 2, [("testZipItem.png", nil), ("testZipItemLink", nil)])
        try check("ExtractInvalidBufferSizeErrorConditions.zip", 1, [("text.txt", nil)])
        try check("ExtractMSDOSArchive.zip", 1, [("test.txt", nil)])

        try check("PasswordArchive.zip", 2, [("LICENSE", nil), ("Readme.markdown", nil)])
        try check("ProgressHelpers.zip", 12)
        try check("RelativeSymbolicLink.zip", 4, [("symlinkedFile", nil), ("symlinkedFolder/", nil), ("symlinks/fileSymlink", nil), ("symlinks/folderSymlink", nil)])
        try check("RemoveDataDescriptorCompressedEntry.zip", 2, [("-", nil), ("second.txt", nil)])
        try check("RemoveEntryFromArchiveWithZIP64EOCD.zip", 2, [("data1.random", nil), ("data2.random", nil)])
        try check("RemoveEntryWithZIP64ExtendedInformation.zip", 4, [("data1.random", nil), ("data2.random", nil), ("data3.random", nil), ("data4.random", nil)])
        try check("RemoveZIP64EntryFromArchiveWithZIP64EOCD.zip", 2, [("data1.random", nil), ("data2.random", nil)])
        try check("SymbolicLink.zip", 2, [("SymbolicLink/", nil), ("SymbolicLink/Xcode.app", nil)])
        try check("Unicode.zip", 2, [("Accént.txt", nil), ("Fólder/Nothing.txt", nil)])
        try check("UnzipItemErrorConditions.zip", 12)
        try check("UnzipItemWithPreferredEncoding.zip", 3, [("data/", nil), ("data/pic👨‍👩‍👧‍👦🎂.jpg", nil), ("data/Benoît.txt", nil)])
        try check("UnzipItemWithZIP64DataDescriptor.zip", 1, [("simple.data", nil)])
        try check("UpdateArchiveRemoveUncompressedEntryFromMemory.zip", 3, [("symlink", nil), ("original", nil), ("dir/", nil)])
        try check("ZIP64ArchiveAddEntryProgress.zip", 2, [("data1.random", nil), ("data2.random", nil)])

        try check("CorruptSymbolicLinkErrorConditions.zip", 1, [("s", nil)])
        try check("TraversalAttack.zip", 1, [("../testTraversalAttackABC/EVIL_HERE", nil)])
        try check("PathTraversal.zip", 1, [("../../../../../../../../../../../tmp/test.txt", nil)])
        try check("IncorrectHeaders.zip", 5, [("IncorrectHeaders/", nil), ("IncorrectHeaders/Readme.txt", nil), ("__MACOSX/", nil), ("__MACOSX/IncorrectHeaders/", nil), ("__MACOSX/IncorrectHeaders/._Readme.txt", nil)])
        try check("InvalidCompressionMethodErrorConditions.zip", 4, [(".DS_Store", nil), ("dir/", nil), ("original", nil), ("symlink", nil)])
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

