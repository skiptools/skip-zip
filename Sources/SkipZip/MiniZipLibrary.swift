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
typealias unzFile = OpaquePointer
typealias zip_fileinfo = OpaquePointer
typealias unz_file_info64 = OpaquePointer
typealias zip_UInt = Int64 // Java has no native UInt
typealias zip_UInt8 = Int8 // Java has no native UInt
typealias zip_UInt16 = Int16 // Java has no native UInt
typealias zip_UInt32 = Int32 // Java has no native UInt
typealias zip_UInt64 = Int64 // Java has no native UInt
#else
typealias zipFile = MiniZip.zipFile
typealias unzFile = MiniZip.unzFile
typealias zip_fileinfo = MiniZip.zip_fileinfo
typealias unz_file_info64 = MiniZip.unz_file_info64
typealias zip_UInt = UInt
typealias zip_UInt8 = UInt8
typealias zip_UInt16 = UInt16
typealias zip_UInt32 = UInt32
typealias zip_UInt64 = UInt64
#endif

/// `MiniZipLibrary` is a Swift encapsulation of the MiniZip library
internal final class MiniZipLibrary {
    /// The singleton library instance, registered using JNA to map the Kotlin functions to their native equivalents
    static let instance = registerNatives(MiniZipLibrary(), frameworkName: "SkipZip", libraryName: "minizip")


    /* SKIP EXTERN */ public func unzOpen64(path: String) -> unzFile? {
        MiniZip.unzOpen64(path)
    }

    /* SKIP EXTERN */ public func unzClose(file: unzFile) -> Int32 {
        MiniZip.unzClose(file)
    }

    /* SKIP EXTERN */ public func unzGoToFirstFile(file: unzFile) -> Int32 {
        MiniZip.unzGoToFirstFile(file)
    }

    /* SKIP EXTERN */ public func unzGoToNextFile(file: unzFile) -> Int32 {
        MiniZip.unzGoToNextFile(file)
    }

    /* SKIP EXTERN */ public func unzGetOffset64(file: unzFile) -> Int64 {
        MiniZip.unzGetOffset64(file)
    }

    /* SKIP EXTERN */ public func unzGetCurrentFileInfo64(file: unzFile, pfile_info: UnsafeMutablePointer<unz_file_info64>?, filename: UnsafeMutablePointer<CChar>?, filename_size: zip_UInt, extrafield: UnsafeMutableRawPointer?, extrafield_size: zip_UInt, comment: UnsafeMutablePointer<CChar>?, comment_size: zip_UInt) -> Int32 {
        MiniZip.unzGetCurrentFileInfo64(file, pfile_info, filename, filename_size, extrafield, extrafield_size, comment, comment_size)
    }

    /* SKIP EXTERN */ public func zipOpen64(path: String, append: Int32) -> zipFile? {
        MiniZip.zipOpen64(path, append)
    }

    /* SKIP EXTERN */ public func zipClose_64(file: zipFile, comment: String?) -> Int32 {
        MiniZip.zipClose_64(file, comment)
    }

    /* SKIP EXTERN */ public func zipOpenNewFileInZip_64(file: zipFile, filename: String, zipfi: UnsafePointer<zip_fileinfo>?, extrafield_local: UnsafeRawPointer?, size_extrafield_local: zip_UInt16, extrafield_global: UnsafeRawPointer?, size_extrafield_global: zip_UInt16, comment: String?, compression_method: Int32, level: Int32, zip64: Int32) -> Int32 {
        MiniZip.zipOpenNewFileInZip_64(file, filename, zipfi, extrafield_local, size_extrafield_local, extrafield_global, size_extrafield_global, comment, compression_method, level, zip64)
    }

    /* SKIP EXTERN */ public func zipWriteInFileInZip(file: zipFile, buf: UnsafeRawPointer, len: zip_UInt32) -> Int32 {
        MiniZip.zipWriteInFileInZip(file, buf, len)
    }

    /* SKIP EXTERN */ public func zipCloseFileInZip64(file: zipFile) -> Int32 {
        MiniZip.zipCloseFileInZip64(file)
    }
}
