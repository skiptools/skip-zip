// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Swift
import Foundation
#if SKIP
import SkipFFI
#endif

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
        minizip.unzGetOffset64(file: file)
    }

    private var currentEntryInfo: unz_file_info64 {
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

    /// Returns the name of the current entry
    public var currentEntryName: String? {
        get throws {
            let fileInfo = try self.currentEntryInfo
            let len = zip_UInt(fileInfo.size_filename)
            if len == zip_UInt(0) {
                return nil
            }

            return try withStringPointer(size: Int(len)) { nameBuffer in
                try check(minizip.unzGetCurrentFileInfo64(file: file, pfile_info: nil, filename: nameBuffer, filename_size: len, extrafield: nil, extrafield_size: 0, comment: nil, comment_size: 0))
            }
        }
    }

    /// Returns the comment for the current entry
    public var currentEntryComment: String? {
        get throws {
            let fileInfo = try self.currentEntryInfo
            let len = zip_UInt(fileInfo.size_file_comment)
            if len == zip_UInt(0) {
                return nil
            }
            return try withStringPointer(size: Int(len)) { commentBuffer in
                try check(minizip.unzGetCurrentFileInfo64(file: file, pfile_info: nil, filename: nil, filename_size: 0, extrafield: nil, extrafield_size: 0, comment: commentBuffer, comment_size: len))
            }
        }
    }

    /// Returns the data for the current entry
    public var currentEntryData: Data? {
        get throws {
            let fileInfo = try self.currentEntryInfo
            let len = zip_UInt32(fileInfo.uncompressed_size)
            if len == zip_UInt32(0) {
                return nil
            }

            try check(minizip.unzOpenCurrentFile(file: file))
            defer { try? check(minizip.unzCloseCurrentFile(file: file)) }
            return withDataPointer(size: Int(len)) { buf in
                minizip.unzReadCurrentFile(file: file, buf: buf, len: len)
            }
        }
    }
}


#if SKIP
typealias DataPointer = com.sun.jna.Memory
#else
typealias DataPointer = UnsafeMutableRawPointer
#endif

/// Allocates the given `size` of memory and then invokes the block with the pointer, then returns the contents of the null-terminated string
func withDataPointer(size: Int, block: (DataPointer) throws -> Int32) rethrows -> Data? {
    #if SKIP
    let dataPtr = DataPointer(Int64(size))
    dataPtr.clear()
    //defer { dataPtr.close() } // calls dispose() to deallocate
    #else
    let dataPtr = DataPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<UInt8>.alignment)
    //defer { dataPtr.deallocate() } // we deallocate lazily from the Data
    #endif

    // TODO: keep reading until read == size
    let read: Int32 = try block(dataPtr)

    #if SKIP
    let data = dataPtr.getByteArray(0, read)
    return Data(platformValue: data)
    #else
    let data = Data(bytesNoCopy: dataPtr, count: Int(read), deallocator: .custom({ (pointer, _) in
        pointer.deallocate()
    }))
    return data
    #endif
}


#if SKIP
typealias StringMemory = com.sun.jna.Memory
#else
typealias StringMemory = UnsafeMutablePointer<CChar>
#endif

/// Allocates the given `size` of memory and then invokes the block with the pointer, then returns the contents of the null-terminated string
func withStringPointer(size: Int, block: (StringMemory) throws -> Void) rethrows -> String? {
    #if SKIP
    // TODO: to mimic UnsafeMutablePointer<CChar>.allocate() we would need to create wrapper structs in SkipFFI (rather than raw typealiases)
    let stringMemory = StringMemory(Int64(size + 1))
    stringMemory.clear()
    defer { stringMemory.close() } // calls dispose() to deallocate
    #else
    let stringMemory = StringMemory.allocate(capacity: Int(size + 1))
    defer { stringMemory.deallocate() }
    #endif

    try block(stringMemory)

    #if SKIP
    return stringMemory.getString(0)
    #else
    let entryName = String(cString: stringMemory)
    return entryName
    #endif
}

/// A zip file writer
public final class ZipWriter {
    let file: zipFile

    public init?(path: String, append: Bool) {
        guard let file = minizip.zipOpen64(path: path, append: append ? 1 : 0) else {
            return nil
        }
        self.file = file
    }
    
    public func close() throws {
        try check(minizip.zipClose_64(file: file, comment: nil))
    }

    /// Adds the given data to an open zip file with the specified compression method
    /// - Parameters:
    ///   - path: the path in the zip file to write to
    ///   - data: the data to add
    ///   - comment: an optional comment for the entry
    ///   - compression: the compression mode
    ///   - level: the compression level to use
    public func add(path: String, data: Data, comment: String? = nil, compression: Int?) throws {
        try check(minizip.zipOpenNewFileInZip_64(file: file, filename: path, zipfi: nil, extrafield_local: nil, size_extrafield_local: zip_UInt16(0), extrafield_global: nil, size_extrafield_global: zip_UInt16(0), comment: comment, compression_method: compression == nil ? CompressionMethod.store.rawValue : CompressionMethod.deflate.rawValue, level: Int32(compression ?? 0), zip64: Int32(1)))

        let len = zip_UInt32(data.count)

        let success = data.withUnsafeBytes { buf in
            minizip.zipWriteInFileInZip(file: file, buf: buf.baseAddress!, len: len)
        }

        try check(minizip.zipCloseFileInZip64(file: file))
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
