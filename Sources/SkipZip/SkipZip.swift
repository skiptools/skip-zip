// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Swift
import Foundation

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

//    public var currentFileSize: Int64 {
//        let res = minizip.unzGetCurrentFileInfo64(file: <#T##unzFile#>, pfile_info: <#T##unz_file_info64_ptr?#>, filename: <#T##UnsafeMutablePointer<CChar>?#>, filename_size: <#T##zip_UInt#>, extrafield: <#T##UnsafeMutableRawPointer?#>, extrafield_size: <#T##zip_UInt#>, comment: <#T##UnsafeMutablePointer<CChar>?#>, comment_size: <#T##zip_UInt#>)
//
//
//    }
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

        let success = data.withBytes { buf in
            minizip.zipWriteInFileInZip(file: file, buf: buf.baseAddress!, len: len)
        }

        try check(minizip.zipCloseFileInZip64(file: file))
        try check(success) // check the result code after we close the internal file
    }
}

public struct ZipError : Error {
    public let code: Int32

    public init(code: Int32) {
        self.code = code
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

#if SKIP
import SkipFFI

extension com.sun.jna.ptr.PointerByReference {
    var baseAddress: OpaquePointer {
        value
    }
}
#endif

extension Data {
    /// Cover for `withUnsafeBytes`; we cannot call it `withUnsafeBytes`, since Skip won't be able to disambiguate against Foundation's stub
    public func withBytes<ResultType>(_ body: (UnsafeRawBufferPointer) throws -> ResultType) rethrows -> ResultType {
        #if !SKIP
        try withUnsafeBytes { try body($0) }
        #else
        let buf = java.nio.ByteBuffer.allocateDirect(self.count)
        buf.put(self.kotlin(nocopy: true))
        let ptr = com.sun.jna.Native.getDirectBufferPointer(buf)
        return body(com.sun.jna.ptr.PointerByReference(ptr))
        #endif
    }
}
