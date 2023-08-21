// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import XCTest
import OSLog
import Foundation

let logger: Logger = Logger(subsystem: "SkipZip", category: "Tests")

@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
final class SkipZipTests: XCTestCase {
    func testSkipZip() throws {
        logger.log("running test")
        XCTAssertEqual(1 + 2, 3, "basic test")
    }
}
