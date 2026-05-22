// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if !SKIP
import MiniZip
#endif

// MARK: - Configuration

/// Configuration for remote zip reader behavior, including retry and backoff settings.
public struct RemoteZipConfiguration {
    /// Maximum number of retry attempts for retryable failures (network errors, HTTP 429/502/503/504).
    public var maxRetries: Int

    /// Initial backoff interval in seconds before the first retry.
    public var initialBackoffInterval: Double

    /// Multiplier applied to the backoff interval after each retry.
    public var backoffMultiplier: Double

    /// Maximum backoff interval in seconds, capping exponential growth.
    public var maxBackoffInterval: Double

    /// Number of bytes to read from the end of the file when searching for the End of Central Directory record.
    /// Increase this if zip files have large comments. The maximum possible EOCD size is 65,557 bytes.
    public var endOfFileReadSize: Int

    public init(
        maxRetries: Int = 3,
        initialBackoffInterval: Double = 0.5,
        backoffMultiplier: Double = 2.0,
        maxBackoffInterval: Double = 30.0,
        endOfFileReadSize: Int = 65_536
    ) {
        self.maxRetries = maxRetries
        self.initialBackoffInterval = initialBackoffInterval
        self.backoffMultiplier = backoffMultiplier
        self.maxBackoffInterval = maxBackoffInterval
        self.endOfFileReadSize = endOfFileReadSize
    }
}

// MARK: - Errors

/// Errors that can occur during remote zip operations.
public enum RemoteZipError : Error, LocalizedError {
    /// The server does not advertise support for HTTP Range requests.
    case serverDoesNotSupportRangeRequests
    /// Could not determine the file size from the Content-Length header.
    case failedToGetContentLength
    /// The End of Central Directory record was not found in the archive.
    case endOfCentralDirectoryNotFound
    /// The central directory could not be parsed.
    case invalidCentralDirectory
    /// No entry with the given name exists in the archive.
    case entryNotFound(String)
    /// The compression method is not supported (only STORE and DEFLATE are supported).
    case unsupportedCompressionMethod(UInt16)
    /// The server returned a non-successful HTTP status code.
    case httpError(Int)
    /// A network-level error occurred.
    case networkError(Error)
    /// Decompression of entry data failed.
    case decompressionFailed
    /// The remote file is too small to be a valid zip archive (minimum 22 bytes for an empty archive).
    case archiveTooSmall
    /// The local file header at the entry's offset is invalid.
    case invalidLocalFileHeader
    /// All retry attempts have been exhausted.
    case retryLimitExceeded(Int, Error)

    public var errorDescription: String? {
        switch self {
        case .serverDoesNotSupportRangeRequests:
            return "The server does not support HTTP Range requests (Accept-Ranges header is missing or set to 'none'). Remote zip reading requires a server that supports range requests."
        case .failedToGetContentLength:
            return "Failed to determine the size of the remote zip file. The server must provide a Content-Length header."
        case .endOfCentralDirectoryNotFound:
            return "Could not find the End of Central Directory record. The file may not be a valid zip archive."
        case .invalidCentralDirectory:
            return "The central directory of the zip file is invalid or corrupted."
        case .entryNotFound(let name):
            return "No entry named '\(name)' was found in the zip archive."
        case .unsupportedCompressionMethod(let method):
            return "Unsupported compression method \(method). Only STORE (0) and DEFLATE (8) are supported."
        case .httpError(let code):
            return "HTTP error: status code \(code)."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decompressionFailed:
            return "Failed to decompress the entry data."
        case .archiveTooSmall:
            return "The remote file is too small to be a valid zip archive (minimum 22 bytes)."
        case .invalidLocalFileHeader:
            return "The local file header at the entry offset is invalid or missing the expected signature."
        case .retryLimitExceeded(let count, let error):
            return "Operation failed after \(count) retry attempts. Last error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Entry

/// Represents an entry in a remote zip archive's central directory.
public struct RemoteZipEntry {
    /// The file name (path) of the entry within the archive.
    public let name: String
    /// The size of the entry's data after compression.
    public let compressedSize: UInt64
    /// The size of the entry's data before compression.
    public let uncompressedSize: UInt64
    /// The CRC-32 checksum of the uncompressed data.
    public let crc32: UInt32
    /// The compression method used (0 = STORE, 8 = DEFLATE).
    public let compressionMethod: UInt16
    /// The byte offset of the local file header in the archive.
    public let localFileHeaderOffset: UInt64
    /// An optional comment associated with the entry.
    public let comment: String
    /// Whether the entry represents a directory.
    public let isDirectory: Bool
    /// The external file attributes of the entry.
    public let externalFileAttributes: UInt32
}

// MARK: - Reader

/// A reader for remote zip archives that uses HTTP Range requests to efficiently
/// access individual entries without downloading the entire archive.
///
/// `RemoteZipReader` works by:
/// 1. Sending a HEAD request to determine the file size and verify Range request support
/// 2. Fetching the End of Central Directory (EOCD) record from the end of the file
/// 3. Fetching and parsing the Central Directory to build the entry list
/// 4. Allowing individual entries to be fetched and decompressed on demand
///
/// Example usage:
/// ```swift
/// let reader = try await RemoteZipReader.open(url: archiveURL)
/// for entry in reader.entries {
///     print("\(entry.name): \(entry.uncompressedSize) bytes")
/// }
/// let data = try await reader.data(forEntryNamed: "README.md")
/// ```
public final class RemoteZipReader {
    /// The URL of the remote zip archive.
    public let url: URL
    /// All entries found in the archive's central directory.
    public let entries: [RemoteZipEntry]
    /// The total size of the remote zip file in bytes.
    public let totalSize: Int64

    private let session: URLSession
    private let configuration: RemoteZipConfiguration

    private init(url: URL, entries: [RemoteZipEntry], totalSize: Int64, session: URLSession, configuration: RemoteZipConfiguration) {
        self.url = url
        self.entries = entries
        self.totalSize = totalSize
        self.session = session
        self.configuration = configuration
    }

    /// Opens a remote zip archive and reads its central directory.
    ///
    /// This method sends a HEAD request followed by one or two Range requests to read
    /// the archive's metadata. The archive itself is never downloaded in full.
    ///
    /// - Parameters:
    ///   - url: The URL of the remote zip archive.
    ///   - session: The URLSession to use for HTTP requests. Defaults to `.shared`.
    ///   - configuration: Configuration for retry behavior and read sizes.
    /// - Returns: A `RemoteZipReader` with the archive's entry list populated.
    /// - Throws: `RemoteZipError` if the server does not support range requests,
    ///   the file is not a valid zip archive, or a network error occurs.
    public static func open(
        url: URL,
        session: URLSession = URLSession.shared,
        configuration: RemoteZipConfiguration = RemoteZipConfiguration()
    ) async throws -> RemoteZipReader {
        // Step 1: HEAD request to get content length and verify range support
        let (contentLength, supportsRanges) = try await getFileInfo(url: url, session: session, configuration: configuration)

        guard supportsRanges else {
            throw RemoteZipError.serverDoesNotSupportRangeRequests
        }

        guard contentLength >= 22 else {
            throw RemoteZipError.archiveTooSmall
        }

        // Step 2: Read end of file to find EOCD
        let readSize = min(Int64(configuration.endOfFileReadSize), contentLength)
        let endData = try await fetchRange(url: url, start: contentLength - readSize, end: contentLength - 1, session: session, configuration: configuration)

        // Step 3: Parse EOCD to locate central directory
        let eocdResult = try parseEOCD(data: endData, fileSize: contentLength)

        // Step 4: Fetch central directory (may already be in endData)
        let cdData: Data
        let cdEnd = eocdResult.cdOffset + eocdResult.cdSize
        let endDataStart = contentLength - readSize
        if eocdResult.cdOffset >= endDataStart && cdEnd <= contentLength {
            let localStart = Int(eocdResult.cdOffset - endDataStart)
            let localEnd = Int(cdEnd - endDataStart)
            cdData = extractBytes(from: endData, start: localStart, count: localEnd - localStart)
        } else {
            cdData = try await fetchRange(url: url, start: eocdResult.cdOffset, end: cdEnd - 1, session: session, configuration: configuration)
        }

        // Step 5: Parse central directory entries
        let entries = try parseCentralDirectory(data: cdData, entryCount: eocdResult.entryCount)

        return RemoteZipReader(url: url, entries: entries, totalSize: contentLength, session: session, configuration: configuration)
    }

    /// Reads and decompresses the data for a specific entry.
    ///
    /// This method fetches the entry's local file header and compressed data via
    /// HTTP Range requests, then decompresses the data if necessary.
    ///
    /// - Parameter entry: The entry to read.
    /// - Returns: The decompressed data for the entry.
    /// - Throws: `RemoteZipError` if the entry cannot be read or decompressed.
    public func data(for entry: RemoteZipEntry) async throws -> Data {
        if entry.isDirectory || entry.uncompressedSize == UInt64(0) {
            return Data()
        }

        // Fetch the 30-byte fixed local file header to get variable-length field sizes
        let headerStart = Int64(entry.localFileHeaderOffset)
        let headerData = try await Self.fetchRange(
            url: url,
            start: headerStart,
            end: headerStart + 29,
            session: session,
            configuration: configuration
        )

        guard headerData.count >= 30 else {
            throw RemoteZipError.invalidLocalFileHeader
        }

        let sig = readUInt32LE(headerData, at: 0)
        guard sig == UInt32(0x04034b50) else {
            throw RemoteZipError.invalidLocalFileHeader
        }

        let filenameLength = Int64(readUInt16LE(headerData, at: 26))
        let extraLength = Int64(readUInt16LE(headerData, at: 28))
        let dataOffset = headerStart + 30 + filenameLength + extraLength

        guard entry.compressedSize > UInt64(0) else {
            return Data()
        }

        // Fetch compressed data
        let compressedData = try await Self.fetchRange(
            url: url,
            start: dataOffset,
            end: dataOffset + Int64(entry.compressedSize) - 1,
            session: session,
            configuration: configuration
        )

        let method = Int(entry.compressionMethod)
        if method == 0 { // STORE
            return compressedData
        } else if method == 8 { // DEFLATE
            return try decompressRawDeflate(compressedData, uncompressedSize: Int(entry.uncompressedSize))
        } else {
            throw RemoteZipError.unsupportedCompressionMethod(entry.compressionMethod)
        }
    }

    /// Reads and decompresses the data for the entry with the given name.
    ///
    /// - Parameter name: The exact name of the entry to find.
    /// - Returns: The decompressed data for the entry.
    /// - Throws: `RemoteZipError.entryNotFound` if no entry matches the name.
    public func data(forEntryNamed name: String) async throws -> Data {
        guard let entry = entries.first(where: { $0.name == name }) else {
            throw RemoteZipError.entryNotFound(name)
        }
        return try await data(for: entry)
    }

    // MARK: - Network helpers

    private static func getFileInfo(url: URL, session: URLSession, configuration: RemoteZipConfiguration) async throws -> (contentLength: Int64, supportsRanges: Bool) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let (_, response) = try await performRequest(request, session: session, configuration: configuration)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteZipError.failedToGetContentLength
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw RemoteZipError.httpError(httpResponse.statusCode)
        }

        let contentLengthStr = httpResponse.value(forHTTPHeaderField: "Content-Length") ?? ""
        let contentLength = Int64(contentLengthStr) ?? Int64(-1)
        guard contentLength > 0 else {
            throw RemoteZipError.failedToGetContentLength
        }

        let acceptRanges = (httpResponse.value(forHTTPHeaderField: "Accept-Ranges") ?? "").lowercased()
        let supportsRanges = acceptRanges.contains("bytes")

        return (contentLength, supportsRanges)
    }

    private static func fetchRange(url: URL, start: Int64, end: Int64, session: URLSession, configuration: RemoteZipConfiguration) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")

        let (data, response) = try await performRequest(request, session: session, configuration: configuration)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteZipError.networkError(NSError(domain: "RemoteZip", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))
        }

        // 206 Partial Content is expected; 200 means server ignored Range header
        if httpResponse.statusCode == 200 {
            throw RemoteZipError.serverDoesNotSupportRangeRequests
        }
        guard httpResponse.statusCode == 206 else {
            throw RemoteZipError.httpError(httpResponse.statusCode)
        }

        return data
    }

    private static func performRequest(_ request: URLRequest, session: URLSession, configuration: RemoteZipConfiguration) async throws -> (Data, URLResponse) {
        var lastError: Error = NSError(domain: "RemoteZip", code: -1, userInfo: nil)
        var backoff = configuration.initialBackoffInterval

        for attempt in 0...configuration.maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    let isRetryable = code == 429 || code == 502 || code == 503 || code == 504
                    if isRetryable {
                        lastError = RemoteZipError.httpError(code)
                        if attempt < configuration.maxRetries {
                            try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                            backoff = min(backoff * configuration.backoffMultiplier, configuration.maxBackoffInterval)
                            continue
                        }
                        throw RemoteZipError.retryLimitExceeded(configuration.maxRetries, lastError)
                    }
                }

                return (data, response)
            } catch {
                if error is CancellationError {
                    throw error
                }
                lastError = error
                if attempt < configuration.maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    backoff = min(backoff * configuration.backoffMultiplier, configuration.maxBackoffInterval)
                    continue
                }
            }
        }

        throw RemoteZipError.retryLimitExceeded(configuration.maxRetries, lastError)
    }

    // MARK: - Zip format parsing

    private struct EOCDResult {
        let cdOffset: Int64
        let cdSize: Int64
        let entryCount: Int
    }

    private static func parseEOCD(data: Data, fileSize: Int64) throws -> EOCDResult {
        let eocdSignature = UInt32(0x06054b50)
        let minEOCDSize = 22

        guard data.count >= minEOCDSize else {
            throw RemoteZipError.endOfCentralDirectoryNotFound
        }

        // Search backwards for the EOCD signature
        var eocdOffset = -1
        let searchLimit = max(0, data.count - 65557)
        for i in stride(from: data.count - minEOCDSize, through: searchLimit, by: -1) {
            if readUInt32LE(data, at: i) == eocdSignature {
                eocdOffset = i
                break
            }
        }

        guard eocdOffset >= 0 else {
            throw RemoteZipError.endOfCentralDirectoryNotFound
        }

        var entryCount = Int(readUInt16LE(data, at: eocdOffset + 10))
        var cdSize = Int64(readUInt32LE(data, at: eocdOffset + 12))
        var cdOffset = Int64(readUInt32LE(data, at: eocdOffset + 16))

        // Check for ZIP64 End of Central Directory Locator (appears 20 bytes before EOCD)
        let zip64LocatorSignature = UInt32(0x07064b50)
        if eocdOffset >= 20 {
            let locatorOffset = eocdOffset - 20
            if readUInt32LE(data, at: locatorOffset) == zip64LocatorSignature {
                let zip64EOCDAbsoluteOffset = Int64(readUInt64LE(data, at: locatorOffset + 8))
                let dataStartOffset = fileSize - Int64(data.count)
                let localZip64Offset = Int(zip64EOCDAbsoluteOffset - dataStartOffset)

                if localZip64Offset >= 0 && localZip64Offset + 56 <= data.count {
                    let zip64Sig = UInt32(0x06064b50)
                    if readUInt32LE(data, at: localZip64Offset) == zip64Sig {
                        entryCount = Int(readUInt64LE(data, at: localZip64Offset + 32))
                        cdSize = Int64(readUInt64LE(data, at: localZip64Offset + 40))
                        cdOffset = Int64(readUInt64LE(data, at: localZip64Offset + 48))
                    }
                }
            }
        }

        return EOCDResult(cdOffset: cdOffset, cdSize: cdSize, entryCount: entryCount)
    }

    private static func parseCentralDirectory(data: Data, entryCount: Int) throws -> [RemoteZipEntry] {
        var entries: [RemoteZipEntry] = []
        var offset = 0
        let cdSignature = UInt32(0x02014b50)

        for _ in 0..<entryCount {
            guard offset + 46 <= data.count else {
                throw RemoteZipError.invalidCentralDirectory
            }

            guard readUInt32LE(data, at: offset) == cdSignature else {
                throw RemoteZipError.invalidCentralDirectory
            }

            let compressionMethod = readUInt16LE(data, at: offset + 10)
            let crc32 = readUInt32LE(data, at: offset + 16)
            var compressedSize = UInt64(readUInt32LE(data, at: offset + 20))
            var uncompressedSize = UInt64(readUInt32LE(data, at: offset + 24))
            let filenameLength = Int(readUInt16LE(data, at: offset + 28))
            let extraLength = Int(readUInt16LE(data, at: offset + 30))
            let commentLength = Int(readUInt16LE(data, at: offset + 32))
            let externalAttributes = readUInt32LE(data, at: offset + 38)
            var localHeaderOffset = UInt64(readUInt32LE(data, at: offset + 42))

            let totalVariableLen = filenameLength + extraLength + commentLength
            guard offset + 46 + totalVariableLen <= data.count else {
                throw RemoteZipError.invalidCentralDirectory
            }

            let nameData = extractBytes(from: data, start: offset + 46, count: filenameLength)
            let name = String(data: nameData, encoding: .utf8) ?? ""

            let comment: String
            if commentLength > 0 {
                let commentStart = offset + 46 + filenameLength + extraLength
                let commentData = extractBytes(from: data, start: commentStart, count: commentLength)
                comment = String(data: commentData, encoding: .utf8) ?? ""
            } else {
                comment = ""
            }

            // Parse ZIP64 extended information extra field if sizes are 0xFFFFFFFF
            if compressedSize == UInt64(0xFFFFFFFF) || uncompressedSize == UInt64(0xFFFFFFFF) || localHeaderOffset == UInt64(0xFFFFFFFF) {
                let extraStart = offset + 46 + filenameLength
                var extraOffset = extraStart
                while extraOffset + 4 <= extraStart + extraLength {
                    let tag = readUInt16LE(data, at: extraOffset)
                    let fieldSize = Int(readUInt16LE(data, at: extraOffset + 2))
                    if tag == UInt16(0x0001) { // ZIP64 extended information
                        var fieldOffset = extraOffset + 4
                        let fieldEnd = extraOffset + 4 + fieldSize
                        if uncompressedSize == UInt64(0xFFFFFFFF) && fieldOffset + 8 <= fieldEnd {
                            uncompressedSize = readUInt64LE(data, at: fieldOffset)
                            fieldOffset += 8
                        }
                        if compressedSize == UInt64(0xFFFFFFFF) && fieldOffset + 8 <= fieldEnd {
                            compressedSize = readUInt64LE(data, at: fieldOffset)
                            fieldOffset += 8
                        }
                        if localHeaderOffset == UInt64(0xFFFFFFFF) && fieldOffset + 8 <= fieldEnd {
                            localHeaderOffset = readUInt64LE(data, at: fieldOffset)
                        }
                        break
                    }
                    extraOffset += 4 + fieldSize
                }
            }

            entries.append(RemoteZipEntry(
                name: name,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                crc32: crc32,
                compressionMethod: compressionMethod,
                localFileHeaderOffset: localHeaderOffset,
                comment: comment,
                isDirectory: name.hasSuffix("/"),
                externalFileAttributes: externalAttributes
            ))

            offset += 46 + totalVariableLen
        }

        return entries
    }
}

// MARK: - Binary reading helpers

/// Extracts a range of bytes from Data, compatible with SkipFoundation.
private func extractBytes(from data: Data, start: Int, count: Int) -> Data {
    var bytes: [UInt8] = []
    for i in 0..<count {
        bytes.append(data[start + i])
    }
    return Data(bytes)
}

private func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
    let b0 = Int(data[offset]) & 0xFF
    let b1 = Int(data[offset + 1]) & 0xFF
    return UInt16(b0 | (b1 << 8))
}

private func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
    let b0 = Int(data[offset]) & 0xFF
    let b1 = Int(data[offset + 1]) & 0xFF
    let b2 = Int(data[offset + 2]) & 0xFF
    let b3 = Int(data[offset + 3]) & 0xFF
    return UInt32(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
}

private func readUInt64LE(_ data: Data, at offset: Int) -> UInt64 {
    let lo = Int64(readUInt32LE(data, at: offset)) & 0xFFFFFFFF
    let hi = Int64(readUInt32LE(data, at: offset + 4)) & 0xFFFFFFFF
    return UInt64(lo | (hi << 32))
}

// MARK: - Decompression

private func decompressRawDeflate(_ compressedData: Data, uncompressedSize: Int) throws -> Data {
    guard uncompressedSize > 0 else { return Data() }

    #if SKIP
    /* SKIP INSERT:
        val inflater = java.util.zip.Inflater(true)
        try {
            inflater.setInput(compressedData.platformValue)
            val output = ByteArray(uncompressedSize)
            val resultLength = inflater.inflate(output)
            inflater.end()
            if (resultLength != uncompressedSize) throw RemoteZipError.decompressionFailed
            return Data(platformValue = output)
        } catch (e: java.util.zip.DataFormatException) {
            throw RemoteZipError.decompressionFailed
        }
     */
    fatalError("unreachable")
    #else
    var decompressed = Data(count: uncompressedSize)
    let result = compressedData.withUnsafeBytes { srcBuffer -> Int32 in
        decompressed.withUnsafeMutableBytes { dstBuffer -> Int32 in
            var destLen = UInt(uncompressedSize)
            let ret = MiniZip.mz_inflate_raw(
                srcBuffer.baseAddress!,
                UInt(compressedData.count),
                dstBuffer.baseAddress!,
                &destLen
            )
            return ret
        }
    }
    guard result == 0 else { // Z_OK == 0
        throw RemoteZipError.decompressionFailed
    }
    return decompressed
    #endif
}
