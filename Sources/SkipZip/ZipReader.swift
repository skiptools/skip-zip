// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
import SkipFFI

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
    @discardableResult public func next() throws -> Bool {
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
                return is64Bit
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

    public var currentEntryIsSymbolicLink: Bool {
        get throws {
            try self.currentEntryInfo.isSymbolicLink
        }
    }

    public var currentEntryIsDirectory: Bool {
        get throws {
            try self.currentEntryInfo.isDirectory
        }
    }
}

public struct ZipError : Error, LocalizedError {
    public let code: Int32

    public init(code: Int32) {
        self.code = code
    }

    public var errorDescription: String? {
        switch self.code {
        case -102: return "MZ_PARAM_ERROR"
        case -103: return "MZ_FORMAT_ERROR"
        case -104: return "MZ_INTERNAL_ERROR"
        case -105: return "MZ_CRC_ERROR"
        case -106: return "MZ_CRYPT_ERROR"
        case -107: return "MZ_EXIST_ERROR"
        case -108: return "MZ_PASSWORD_ERROR"
        case -109: return "MZ_SUPPORT_ERROR"
        case -110: return "MZ_HASH_ERROR"
        case -111: return "MZ_OPEN_ERROR"
        case -112: return "MZ_CLOSE_ERROR"
        case -113: return "MZ_SEEK_ERROR"
        case -114: return "MZ_TELL_ERROR"
        case -115: return "MZ_READ_ERROR"
        case -116: return "MZ_WRITE_ERROR"
        case -117: return "MZ_SIGN_ERROR"
        case -118: return "MZ_SYMLINK_ERROR"
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
