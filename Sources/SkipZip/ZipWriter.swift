// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
import SkipFFI

/// A zip file writer
public final class ZipWriter {
    let file: zipFile
    var closed: Bool

    public init?(path: String, append: Bool) {
        guard let file = minizip.zipOpenArch(path: path, append: append ? 1 : 0) else {
            return nil
        }
        self.file = file
        self.closed = false
    }

    deinit {
        try? close()
    }

    public func close() throws {
        if !closed {
            try check(minizip.zipCloseArch(file: file, comment: nil))
            closed = true
        }
    }

    /// Adds the given data to an open zip file with the specified compression method
    /// - Parameters:
    ///   - path: the path in the zip file to write to
    ///   - data: the data to add
    ///   - comment: an optional comment for the entry
    ///   - compression: the compression level to use, where 0 is no compression (STORE), and 1-9 is in order of increasing compression (DEFLATE), and -1 is the default level (6)
    public func add(path: String, data: Data, comment: String? = nil, compression: Int?) throws {
        try check(minizip.zipOpenNewFileInZip_64(file: file, filename: path, zipfi: nil, extrafield_local: nil, size_extrafield_local: FFIUInt16(0), extrafield_global: nil, size_extrafield_global: FFIUInt16(0), comment: comment, compression_method: compression == nil ? CompressionMethod.store.rawValue : CompressionMethod.deflate.rawValue, level: Int32(compression ?? 0), zip64: Int32(1)))

        let len = FFIUInt32(data.count)

        let success = data.withUnsafeBytes { buf in
            minizip.zipWriteInFileInZip(file: file, buf: buf.baseAddress!, len: len)
        }

        try check(minizip.zipCloseFileInZipArch(file: file))
        try check(success) // check the result code after we close the internal file
    }
}
