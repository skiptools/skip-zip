import XCTest
import OSLog
import Foundation

let logger: Logger = Logger(subsystem: "SkipZip", category: "Tests")

@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
final class SkipZipTests: XCTestCase {
    func testSkipZip() throws {
        logger.log("running test")
        XCTAssertEqual(1 + 2, 4, "basic test")
    }
}
