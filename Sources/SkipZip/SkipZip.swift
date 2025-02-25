// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
import SkipFFI

private let zlib = ZlibLibrary()
private let minizip = MiniZipLibrary()

/// Checks the return code to ensure it is `ZIP_OK`, throwing an error otherwise
fileprivate func check(_ status: Int32) throws {
    if status != 0 {
        throw ZipError(code: status)
    }
}

/// A zip file reader
public final class ZipReader {
    let file: unzFile

    public init?(path: String) {
        guard let file = minizip.unzOpen64(path: path) else {
            return nil
        }
        self.file = file
    }

    public func close() throws {
        try check(minizip.unzClose(file: file))
    }

    /// Move to the first file in the zip file.
    public func first() throws {
        try check(minizip.unzGoToFirstFile(file: file))
    }

    /// Move to the next file in the zip file, returning false if the zip file is at the end
    public func next() throws -> Bool {
        let res = minizip.unzGoToNextFile(file: file)
        if res == -100 { // MZ_END_OF_LIST
            return false
        }
        try check(res)
        return true
    }

    public var currentOffset: Int64 {
        minizip.unzGetOffsetArch(file: file)
    }

    private var currentEntryInfo: ZipEntryInfo {
        get throws {
            if is32Bit {
                return try currentEntryInfo32
            } else {
                return try currentEntryInfo64
            }
        }
    }

    private var currentEntryInfo64: unz_file_info64 {
        get throws {
            #if SKIP
            let fileInfoPtr = unz_file_info64()
            #else
            let fileInfoPtr = unz_file_info64_ptr()
            #endif
            try check(minizip.unzGetCurrentFileInfo64(file: file, pfile_info: fileInfoPtr, filename: nil, filename_size: 0, extrafield: nil, extrafield_size: 0, comment: nil, comment_size: 0))
            #if SKIP
            fileInfoPtr.read()
            return fileInfoPtr
            #else
            return fileInfoPtr.pointee
            #endif
        }
    }

    private var currentEntryInfo32: unz_file_info {
        get throws {
            #if SKIP
            let fileInfoPtr = unz_file_info()
            #else
            let fileInfoPtr = unz_file_info_ptr()
            #endif
            try check(minizip.unzGetCurrentFileInfo(file: file, pfile_info: fileInfoPtr, filename: nil, filename_size: 0, extrafield: nil, extrafield_size: 0, comment: nil, comment_size: 0))
            #if SKIP
            fileInfoPtr.read()
            return fileInfoPtr
            #else
            return fileInfoPtr.pointee
            #endif
        }
    }


    /// Returns the CRC32 for the current entry
    public var currentEntryCRC32: UInt32 {
        get throws {
            try currentEntryInfo.crc32
        }
    }

    /// Returns the name of the current entry
    public var currentEntryName: String? {
        get throws {
            let fileInfo = try self.currentEntryInfo
            let len = fileInfo.filenameSize
            if len == UInt16(0) {
                return nil
            }

            return try withFFIStringPointer(size: Int(len)) { nameBuffer in
                is64Bit 
                ? try check(minizip.unzGetCurrentFileInfo64(file: file, pfile_info: nil, filename: nameBuffer, filename_size: FFIUInt(len), extrafield: nil, extrafield_size: 0, comment: nil, comment_size: 0))
                : try check(minizip.unzGetCurrentFileInfo(file: file, pfile_info: nil, filename: nameBuffer, filename_size: FFIUInt(len), extrafield: nil, extrafield_size: 0, comment: nil, comment_size: 0))
            }
        }
    }

    /// Returns the comment for the current entry
    public var currentEntryComment: String? {
        get throws {
            let fileInfo = try self.currentEntryInfo
            let len = fileInfo.commentSize
            if len == UInt16(0) {
                return nil
            }
            return try withFFIStringPointer(size: Int(len)) { commentBuffer in
                is64Bit
                ? try check(minizip.unzGetCurrentFileInfo64(file: file, pfile_info: nil, filename: nil, filename_size: 0, extrafield: nil, extrafield_size: 0, comment: commentBuffer, comment_size: FFIUInt(len)))
                : try check(minizip.unzGetCurrentFileInfo(file: file, pfile_info: nil, filename: nil, filename_size: 0, extrafield: nil, extrafield_size: 0, comment: commentBuffer, comment_size: FFIUInt(len)))
            }
        }
    }

    /// Returns the data for the current entry
    public var currentEntryData: Data? {
        get throws {
            let fileInfo = try self.currentEntryInfo
            if fileInfo.uncompressedSize > UInt32.max {
                throw ZipError(code: -2) // too large to fit in a single Data
            }

            let len = FFIUInt32(fileInfo.uncompressedSize)
            if len == FFIUInt32(0) {
                return nil
            }

            try check(minizip.unzOpenCurrentFile(file: file))
            defer { try? check(minizip.unzCloseCurrentFile(file: file)) }
            return withFFIDataPointer(size: Int(len)) { buf in
                minizip.unzReadCurrentFile(file: file, buf: buf, len: len)
            }
        }
    }
}


/// A zip file writer
public final class ZipWriter {
    let file: zipFile

    public init?(path: String, append: Bool) {
        guard let file = minizip.zipOpenArch(path: path, append: append ? 1 : 0) else {
            return nil
        }
        self.file = file
    }
    
    public func close() throws {
        try check(minizip.zipCloseArch(file: file, comment: nil))
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

public struct ZipError : Error, LocalizedError {
    public let code: Int32

    public init(code: Int32) {
        self.code = code
    }

    public var errorDescription: String? {
        switch self.code {
        case -102: return "UNZ_PARAMERROR"
        case -103: return "UNZ_BADZIPFILE"
        case -104: return "UNZ_INTERNALERROR"
        case -105: return "UNZ_CRCERROR"
        case -106: return "UNZ_BADPASSWORD"
        default: return "Unknown error (\(self.code))"
        }
    }
}


public enum CompressionMethod : Int32 {
    /// `MZ_COMPRESS_METHOD_STORE`
    case store = 0
    /// `MZ_COMPRESS_METHOD_DEFLATE`
    case deflate = 8
    /// `MZ_COMPRESS_METHOD_BZIP2`
    //case bzip2 = 12 // unsupported
    /// `MZ_COMPRESS_METHOD_LZMA`
    //case lzma = 14 // unsupported
    /// `MZ_COMPRESS_METHOD_ZSTD`
    //case zstd = 93 // unsupported
    /// `MZ_COMPRESS_METHOD_XZ`
    //case xz = 95 // unsupported
    /// `MZ_COMPRESS_METHOD_AES`
    //case aes = 99 // unsupported
}
