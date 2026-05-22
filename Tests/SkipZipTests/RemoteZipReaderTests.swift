// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SkipZip

#if !SKIP

// MARK: - Mock URL Protocol

/// A mock URLProtocol that intercepts HTTP requests and serves responses from a configurable handler.
/// Used to simulate an HTTP server with Range request support for testing RemoteZipReader.
class MockZipURLProtocol: URLProtocol {
    /// Set this handler before each test to control how requests are handled.
    /// Return an (HTTPURLResponse, Data) tuple or throw an error to simulate failures.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockZipURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockZipURLProtocol", code: 0, userInfo: [NSLocalizedDescriptionKey: "No request handler configured"]))
            return
        }

        do {
            let (response, data) = try handler(request)
            #if SKIP
            client?.urlProtocol(self, didReceive: response)
            #else
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            #endif
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mock Server Helper

/// Creates a mock HTTP server that serves a local zip file with optional Range request support.
struct MockZipServer {
    let url: URL
    let fileData: Data

    /// Creates a mock server from a test resource zip file.
    /// - Parameters:
    ///   - resource: The name of the zip file in the test bundle's Resources directory.
    ///   - supportsRanges: Whether the mock server advertises and handles Range requests.
    ///   - failCountBeforeSuccess: Number of times range requests should fail with 503 before succeeding.
    init(resource: String, supportsRanges: Bool = true, failCountBeforeSuccess: Int = 0) throws {
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: resource, withExtension: nil))
        self.fileData = try Data(contentsOf: resourceURL)
        self.url = URL(string: "https://mock.example.com/\(resource)")!

        var failuresRemaining = failCountBeforeSuccess
        let mockURL = self.url
        let data = self.fileData

        MockZipURLProtocol.requestHandler = { request in
            guard request.url == mockURL else {
                throw NSError(domain: "MockZipServer", code: 404, userInfo: [NSLocalizedDescriptionKey: "Unknown URL: \(request.url?.absoluteString ?? "nil")"])
            }

            // Handle HEAD requests
            if request.httpMethod == "HEAD" {
                var headers: [String: String] = ["Content-Length": "\(data.count)"]
                if supportsRanges {
                    headers["Accept-Ranges"] = "bytes"
                }
                let response = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
                return (response, Data())
            }

            // Simulate transient failures
            if failuresRemaining > 0 {
                failuresRemaining -= 1
                let response = HTTPURLResponse(url: mockURL, statusCode: 503, httpVersion: "HTTP/1.1", headerFields: [:])!
                return (response, Data())
            }

            // Handle Range requests
            if let rangeHeader = request.value(forHTTPHeaderField: "Range"),
               rangeHeader.hasPrefix("bytes=") {
                guard supportsRanges else {
                    // Server doesn't support ranges; return full content with 200
                    let response = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Length": "\(data.count)"])!
                    return (response, data)
                }

                let rangeValue = String(rangeHeader.dropFirst(6)) // drop "bytes="
                let parts = rangeValue.split(separator: "-")
                guard parts.count == 2,
                      let start = Int(parts[0]),
                      let end = Int(parts[1]),
                      start >= 0, end >= start, end < data.count else {
                    let response = HTTPURLResponse(url: mockURL, statusCode: 416, httpVersion: "HTTP/1.1", headerFields: [:])!
                    return (response, Data())
                }

                let rangeData = data.subdata(in: start..<(end + 1))
                let response = HTTPURLResponse(url: mockURL, statusCode: 206, httpVersion: "HTTP/1.1", headerFields: [
                    "Content-Range": "bytes \(start)-\(end)/\(data.count)",
                    "Content-Length": "\(rangeData.count)"
                ])!
                return (response, rangeData)
            }

            // No Range header; return full file
            let response = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Length": "\(data.count)"])!
            return (response, data)
        }
    }
}

// MARK: - Tests

final class RemoteZipReaderTests: XCTestCase {

    var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockZipURLProtocol.self]
        session = URLSession(configuration: config)
    }

    override func tearDown() {
        MockZipURLProtocol.requestHandler = nil
        session = nil
        super.tearDown()
    }

    // Use fast retries for tests
    var fastConfig: RemoteZipConfiguration {
        RemoteZipConfiguration(maxRetries: 3, initialBackoffInterval: 0.01, backoffMultiplier: 1.0, maxBackoffInterval: 0.01)
    }

    // MARK: - Basic functionality tests

    func testReadSimpleZip() async throws {
        let server = try MockZipServer(resource: "hello.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.entries.count, 1)
        XCTAssertEqual(reader.entries[0].name, "hello")
        XCTAssertFalse(reader.entries[0].isDirectory)

        let data = try await reader.data(for: reader.entries[0])
        XCTAssertEqual(String(data: data, encoding: .utf8), "hello")
    }

    func testReadMultiEntryZip() async throws {
        let server = try MockZipServer(resource: "Archive.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.entries.count, 2)
        XCTAssertEqual(reader.entries[0].name, "LICENSE")
        XCTAssertEqual(reader.entries[1].name, "Readme.markdown")

        // CRC32 values should match expected
        XCTAssertEqual(reader.entries[0].crc32, UInt32(3911215856))
        XCTAssertEqual(reader.entries[1].crc32, UInt32(3219512633))
    }

    func testReadCompressedEntries() async throws {
        let server = try MockZipServer(resource: "EntryIsCompressed.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.entries.count, 2)
        XCTAssertEqual(reader.entries[0].name, "uncompressed")
        XCTAssertEqual(reader.entries[1].name, "compressed")

        let expectedContent = "This is just some test data that might be compressed or not"

        let uncompressedData = try await reader.data(forEntryNamed: "uncompressed")
        XCTAssertEqual(String(data: uncompressedData, encoding: .utf8), expectedContent)

        let compressedData = try await reader.data(forEntryNamed: "compressed")
        XCTAssertEqual(String(data: compressedData, encoding: .utf8), expectedContent)

        // Both should have the same CRC32
        XCTAssertEqual(reader.entries[0].crc32, reader.entries[1].crc32)
    }

    func testReadUnicodeEntries() async throws {
        let server = try MockZipServer(resource: "Unicode.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.entries.count, 2)
        XCTAssertEqual(reader.entries[0].name, "Acc\u{00E9}nt.txt")
        XCTAssertEqual(reader.entries[1].name, "F\u{00F3}lder/Nothing.txt")

        let data0 = try await reader.data(for: reader.entries[0])
        XCTAssertEqual(String(data: data0, encoding: .utf8), "Hello.\n")

        let data1 = try await reader.data(for: reader.entries[1])
        XCTAssertEqual(String(data: data1, encoding: .utf8), "Nothing to see here. Move along.\n")
    }

    func testReadDirectoryEntries() async throws {
        let server = try MockZipServer(resource: "DetectEntryType.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.entries.count, 2)

        let dirEntry = reader.entries[0]
        XCTAssertEqual(dirEntry.name, "META-INF/")
        XCTAssertTrue(dirEntry.isDirectory)

        let fileEntry = reader.entries[1]
        XCTAssertEqual(fileEntry.name, "META-INF/container.xml")
        XCTAssertFalse(fileEntry.isDirectory)

        // Reading a directory entry should return empty data
        let dirData = try await reader.data(for: dirEntry)
        XCTAssertEqual(dirData.count, 0)
    }

    func testDataForEntryNamed() async throws {
        let server = try MockZipServer(resource: "hello.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        let data = try await reader.data(forEntryNamed: "hello")
        XCTAssertEqual(String(data: data, encoding: .utf8), "hello")
    }

    func testEntryNotFound() async throws {
        let server = try MockZipServer(resource: "hello.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        do {
            _ = try await reader.data(forEntryNamed: "nonexistent")
            XCTFail("Expected entryNotFound error")
        } catch let error as RemoteZipError {
            if case .entryNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent")
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testTotalSize() async throws {
        let server = try MockZipServer(resource: "hello.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.totalSize, Int64(server.fileData.count))
    }

    // MARK: - ZIP64 tests

    func testReadZIP64Archive() async throws {
        let server = try MockZipServer(resource: "ExtractCompressedZIP64Entries.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.entries.count, 1)
        XCTAssertEqual(reader.entries[0].name, "testExtractCompressedZIP64Entries.png")
        XCTAssertEqual(reader.entries[0].crc32, UInt32(3693714359))
    }

    // MARK: - Error scenario tests

    func testServerDoesNotSupportRangeRequests() async throws {
        let server = try MockZipServer(resource: "hello.zip", supportsRanges: false)

        do {
            _ = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)
            XCTFail("Expected serverDoesNotSupportRangeRequests error")
        } catch let error as RemoteZipError {
            switch error {
            case .serverDoesNotSupportRangeRequests:
                break // expected
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testHTTPErrorResponse() async throws {
        let mockURL = URL(string: "https://mock.example.com/error.zip")!
        MockZipURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: mockURL, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: [:])!
            return (response, Data())
        }

        do {
            _ = try await RemoteZipReader.open(url: mockURL, session: session, configuration: fastConfig)
            XCTFail("Expected httpError")
        } catch let error as RemoteZipError {
            if case .httpError(let code) = error {
                XCTAssertEqual(code, 404)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testMissingContentLength() async throws {
        let mockURL = URL(string: "https://mock.example.com/nolength.zip")!
        MockZipURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Accept-Ranges": "bytes"])!
            return (response, Data())
        }

        do {
            _ = try await RemoteZipReader.open(url: mockURL, session: session, configuration: fastConfig)
            XCTFail("Expected failedToGetContentLength error")
        } catch let error as RemoteZipError {
            if case .failedToGetContentLength = error {
                // expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testNetworkError() async throws {
        let mockURL = URL(string: "https://mock.example.com/network-fail.zip")!
        MockZipURLProtocol.requestHandler = { _ in
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }

        let noRetryConfig = RemoteZipConfiguration(maxRetries: 0)
        do {
            _ = try await RemoteZipReader.open(url: mockURL, session: session, configuration: noRetryConfig)
            XCTFail("Expected network error")
        } catch let error as RemoteZipError {
            if case .retryLimitExceeded = error {
                // expected: retries exhausted with the network error
            } else if case .networkError = error {
                // also acceptable
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    // MARK: - Retry / flaky network tests

    func testRetryOnTransientFailure() async throws {
        // Server fails twice with 503, then succeeds
        let server = try MockZipServer(resource: "hello.zip", failCountBeforeSuccess: 2)

        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)
        XCTAssertEqual(reader.entries.count, 1)
        XCTAssertEqual(reader.entries[0].name, "hello")
    }

    func testRetryExhausted() async throws {
        // Server always fails with 503
        let mockURL = URL(string: "https://mock.example.com/always-fail.zip")!
        MockZipURLProtocol.requestHandler = { request in
            if request.httpMethod == "HEAD" {
                let response = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
                    "Content-Length": "1000",
                    "Accept-Ranges": "bytes"
                ])!
                return (response, Data())
            }
            let response = HTTPURLResponse(url: mockURL, statusCode: 503, httpVersion: "HTTP/1.1", headerFields: [:])!
            return (response, Data())
        }

        let limitedConfig = RemoteZipConfiguration(maxRetries: 2, initialBackoffInterval: 0.01, backoffMultiplier: 1.0, maxBackoffInterval: 0.01)
        do {
            _ = try await RemoteZipReader.open(url: mockURL, session: session, configuration: limitedConfig)
            XCTFail("Expected retryLimitExceeded error")
        } catch let error as RemoteZipError {
            if case .retryLimitExceeded(let count, _) = error {
                XCTAssertEqual(count, 2)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testIntermittentNetworkFailureDuringDataFetch() async throws {
        // Open succeeds, but data fetch for an entry has transient failures
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: "hello.zip", withExtension: nil))
        let fileData = try Data(contentsOf: resourceURL)
        let mockURL = URL(string: "https://mock.example.com/flaky-data.zip")!

        var dataRequestCount = 0
        MockZipURLProtocol.requestHandler = { request in
            if request.httpMethod == "HEAD" {
                let response = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
                    "Content-Length": "\(fileData.count)",
                    "Accept-Ranges": "bytes"
                ])!
                return (response, Data())
            }

            if let rangeHeader = request.value(forHTTPHeaderField: "Range"),
               rangeHeader.hasPrefix("bytes=") {
                dataRequestCount += 1

                // Fail the 4th and 5th range requests (entry data fetches) with 502
                if dataRequestCount == 4 || dataRequestCount == 5 {
                    let response = HTTPURLResponse(url: mockURL, statusCode: 502, httpVersion: "HTTP/1.1", headerFields: [:])!
                    return (response, Data())
                }

                let rangeValue = String(rangeHeader.dropFirst(6))
                let parts = rangeValue.split(separator: "-")
                let start = Int(parts[0])!
                let end = Int(parts[1])!
                let rangeData = fileData.subdata(in: start..<(end + 1))
                let response = HTTPURLResponse(url: mockURL, statusCode: 206, httpVersion: "HTTP/1.1", headerFields: [
                    "Content-Range": "bytes \(start)-\(end)/\(fileData.count)",
                    "Content-Length": "\(rangeData.count)"
                ])!
                return (response, rangeData)
            }

            throw NSError(domain: "Mock", code: 0)
        }

        let reader = try await RemoteZipReader.open(url: mockURL, session: session, configuration: fastConfig)
        XCTAssertEqual(reader.entries.count, 1)

        // Data fetch should succeed despite transient failures (retry kicks in)
        let data = try await reader.data(for: reader.entries[0])
        XCTAssertEqual(String(data: data, encoding: .utf8), "hello")
    }

    // MARK: - Cross-validation with ZipReader

    func testCrossValidateWithZipReader() async throws {
        // Verify that RemoteZipReader produces the same entries and data as ZipReader
        let resourceName = "EntryIsCompressed.zip"
        let server = try MockZipServer(resource: resourceName)

        let remoteReader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        // Compare with local ZipReader
        let tmpPath = URL.temporaryDirectory.path + "/RemoteZipTest-\(UUID().uuidString).zip"
        try server.fileData.write(to: URL(fileURLWithPath: tmpPath))
        defer { try? FileManager.default.removeItem(atPath: tmpPath) }

        let localReader = try XCTUnwrap(ZipReader(path: tmpPath))

        // Collect local entries
        var localEntries: [(name: String, crc32: UInt32, data: Data?)] = []
        while true {
            let name = try localReader.currentEntryName
            let crc = try localReader.currentEntryCRC32
            let data = try localReader.currentEntryData
            localEntries.append((name: name ?? "", crc32: crc, data: data))
            if !(try localReader.next()) { break }
        }
        try localReader.close()

        XCTAssertEqual(remoteReader.entries.count, localEntries.count)

        for (i, remoteEntry) in remoteReader.entries.enumerated() {
            XCTAssertEqual(remoteEntry.name, localEntries[i].name)
            XCTAssertEqual(remoteEntry.crc32, localEntries[i].crc32)

            if let localData = localEntries[i].data {
                let remoteData = try await remoteReader.data(for: remoteEntry)
                XCTAssertEqual(remoteData, localData, "Data mismatch for entry '\(remoteEntry.name)'")
            }
        }
    }

    // MARK: - Multiple sample zip files

    func testVariousSampleZipFiles() async throws {
        // Test opening various sample zip files to verify central directory parsing
        let samples: [(resource: String, expectedCount: Int)] = [
            ("hello.zip", 1),
            ("Archive.zip", 2),
            ("DetectEntryType.zip", 2),
            ("Unicode.zip", 2),
            ("ExtractMSDOSArchive.zip", 1),
            ("ProgressHelpers.zip", 12),
            ("IncorrectHeaders.zip", 5),
        ]

        for (resource, expectedCount) in samples {
            let server = try MockZipServer(resource: resource)
            let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)
            XCTAssertEqual(reader.entries.count, expectedCount, "Entry count mismatch for \(resource)")
        }
    }

    func testReadMSDOSArchiveData() async throws {
        let server = try MockZipServer(resource: "ExtractMSDOSArchive.zip")
        let reader = try await RemoteZipReader.open(url: server.url, session: session, configuration: fastConfig)

        XCTAssertEqual(reader.entries.count, 1)
        XCTAssertEqual(reader.entries[0].name, "test.txt")
        XCTAssertEqual(reader.entries[0].crc32, UInt32(3632233996))

        let data = try await reader.data(forEntryNamed: "test.txt")
        XCTAssertEqual(String(data: data, encoding: .utf8), "test")
    }

    // MARK: - Error description tests

    func testErrorDescriptions() {
        let errors: [RemoteZipError] = [
            .serverDoesNotSupportRangeRequests,
            .failedToGetContentLength,
            .endOfCentralDirectoryNotFound,
            .invalidCentralDirectory,
            .entryNotFound("test.txt"),
            .unsupportedCompressionMethod(99),
            .httpError(500),
            .decompressionFailed,
            .archiveTooSmall,
            .invalidLocalFileHeader,
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
        }
    }
}
#endif

