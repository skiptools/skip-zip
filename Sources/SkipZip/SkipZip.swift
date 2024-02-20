// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Swift
import Foundation

private let zlib = ZlibLibrary()
private let minizip = MiniZipLibrary()

/// An unsigned 32-Bit Integer representing a checksum.
public typealias CRC32 = UInt32

public class ZipArchive {
    let file: zipFile

    public init?(pathForWriting path: String, append: Bool) {
        guard let file = minizip.zipOpen(path: path, append: append ? 1 : 0) else {
            return nil
        }
        self.file = file
    }
    
    /// Adds the given data to an open zip file with the specified compression method
    /// - Parameters:
    ///   - path: the path in the zip file to write to
    ///   - data: the data to add
    ///   - comment: an optional comment for the entry
    ///   - compression: the compression mode
    ///   - level: the compression level to use
    public func add(path: String, data: Data, comment: String? = nil, compression: Int?) throws {
        let f = minizip.zipOpenNewFileInZip(file: file, filename: path, zipfi: nil, extrafield_local: nil, size_extrafield_local: zip_UInt16(0), extrafield_global: nil, size_extrafield_global: zip_UInt16(0), comment: comment, compression_method: compression == nil ? CompressionMethod.store.rawValue : CompressionMethod.deflate.rawValue, level: Int32(compression ?? 0))

        let len = zip_UInt32(data.count)
        #if SKIP
        let buf = java.nio.ByteBuffer.allocateDirect(len)
        buf.put(data.kotlin(nocopy: true))
        let ptr = com.sun.jna.Native.getDirectBufferPointer(buf)
        let success = minizip.zipWriteInFileInZip(file: file, buf: ptr, len: len)
        #else
        let success = try data.withUnsafeBytes { buf in
            minizip.zipWriteInFileInZip(file: file, buf: buf, len: len)
        }
        #endif

        try check(minizip.zipCloseFileInZip(file: file))
        try check(success) // check the result code after we close the internal file
    }

    public func close() throws {
        try check(minizip.zipClose(file: file, comment: nil))
    }

    /// Checks the return code to ensure it is `ZIP_OK`, throwing an error otherwise
    func check(_ status: Int32) throws {
        if status != 0 {
            throw ZipError(code: status)
        }
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

