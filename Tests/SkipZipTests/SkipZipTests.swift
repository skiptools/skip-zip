// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import XCTest
import OSLog
import Foundation
import SkipZip

let logger: Logger = Logger(subsystem: "SkipZip", category: "Tests")

@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
final class SkipZipTests: XCTestCase {
    func testSkipZip() throws {
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
}
