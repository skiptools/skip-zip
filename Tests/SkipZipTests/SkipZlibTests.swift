// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import XCTest
import OSLog
import Foundation
@testable import SkipZip

@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
final class SkipZlibTests: XCTestCase {
    let zlib: ZlibLibrary = ZlibLibrary()

    func testZlib() throws {
        // 1.2.11 for Android and macOS 13, 1.2.12 for more recent versions
        XCTAssertTrue(zlib.zlibVersion().hasPrefix("1.2."), "unexpected zlib version: \(zlib.zlibVersion())")

        XCTAssertEqual(zlib.zError(code: -1), "file error")
        XCTAssertEqual(zlib.zError(code: -2), "stream error")
        XCTAssertEqual(zlib.zError(code: -3), "data error")
        XCTAssertEqual(zlib.zError(code: -4), "insufficient memory")
        XCTAssertEqual(zlib.zError(code: -5), "buffer error")

        XCTAssertEqual(zlib.Z_OK, 0)
        XCTAssertEqual(zlib.Z_FINISH, 4)
        XCTAssertEqual(zlib.Z_DEFLATED, 8)
        XCTAssertEqual(zlib.Z_NO_FLUSH, 0)
        XCTAssertEqual(zlib.Z_MEM_ERROR, -4)
        XCTAssertEqual(zlib.Z_NEED_DICT, 2)
        XCTAssertEqual(zlib.Z_STREAM_END, 1)
        XCTAssertEqual(zlib.Z_DEFLATED, 8)
        XCTAssertEqual(zlib.MAX_WBITS, 15)
        XCTAssertEqual(zlib.Z_DEFAULT_STRATEGY, 0)
        XCTAssertEqual(zlib.Z_DEFAULT_COMPRESSION, -1)


        let stream = ZlibLibrary.z_stream()
    }
}

