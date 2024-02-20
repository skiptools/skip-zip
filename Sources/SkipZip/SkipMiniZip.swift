// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
import SkipFFI
#if !SKIP
import MiniZip
#endif

#if SKIP
typealias zipFile = OpaquePointer
typealias zip_fileinfo = OpaquePointer
typealias zip_UInt8 = Int8 // Java has no native UInt
typealias zip_UInt16 = Int16 // Java has no native UInt
typealias zip_UInt32 = Int32 // Java has no native UInt
typealias zip_UInt64 = Int64 // Java has no native UInt
#else
typealias zipFile = MiniZip.zipFile
typealias zip_fileinfo = MiniZip.zip_fileinfo
typealias zip_UInt8 = UInt8
typealias zip_UInt16 = UInt16
typealias zip_UInt32 = UInt32
typealias zip_UInt64 = UInt64
#endif

/// `MiniZipLibrary` is a Swift encapsulation of the MiniZip library
internal final class MiniZipLibrary {
    /// The singleton library instance, registered using JNA to map the Kotlin functions to their native equivalents
    static let instance = registerNatives(MiniZipLibrary(), frameworkName: "SkipZip", libraryName: "minizip")

    /* SKIP EXTERN */ public func zipOpen(path: String, append: Int32) -> zipFile? {
        MiniZip.zipOpen(path, append)
    }

    /* SKIP EXTERN */ public func zipClose(file: zipFile, comment: String?) -> Int32 {
        MiniZip.zipClose(file, comment)
    }

    /* SKIP EXTERN */ public func zipOpenNewFileInZip(file: zipFile, filename: String, zipfi: UnsafePointer<zip_fileinfo>?, extrafield_local: UnsafeRawPointer?, size_extrafield_local: zip_UInt16, extrafield_global: UnsafeRawPointer?, size_extrafield_global: zip_UInt16, comment: String?, compression_method: Int32, level: Int32) -> Int32 {
        MiniZip.zipOpenNewFileInZip(file, filename, zipfi, extrafield_local, size_extrafield_local, extrafield_global, size_extrafield_global, comment, compression_method, level)
    }

    /* SKIP EXTERN */ public func zipWriteInFileInZip(file: zipFile, buf: UnsafeRawPointer, len: zip_UInt32) -> Int32 {
        MiniZip.zipWriteInFileInZip(file, buf, len)
    }

    /* SKIP EXTERN */ public func zipCloseFileInZip(file: zipFile) -> Int32 {
        MiniZip.zipCloseFileInZip(file)
    }
}
