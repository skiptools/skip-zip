// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
import SkipFFI
#if !SKIP
import MiniZip
#endif

/// Information about a zip file entry, abstracted across 32-bit and 64-bit systems
protocol ZipEntryInfo {
    //var version: FFIUInt16 { get }
    //var version_needed: FFIUInt16 { get }
    //var flag: FFIUInt16 { get }
    //var compression_method: FFIUInt16 { get }
    //var dos_date: FFIUInt32 { get }
    //var tmu_date: tm { get }
    //var crc: FFIUInt32 { get }
    //var size_filename: FFIUInt16 { get }
    //var size_file_comment: FFIUInt16 { get }
    //var size_file_extra: FFIUInt16 { get }

    var filenameSize: UInt16 { get }
    var commentSize: UInt16 { get }
    var crc32: UInt32 { get }
    var compressedSize: UInt64 { get }
    var uncompressedSize: UInt64 { get }

}


#if !SKIP
let is64Bit = Int.bitWidth == Int64.bitWidth
let is32Bit = Int.bitWidth == Int32.bitWidth

typealias zipFile = MiniZip.zipFile
typealias unzFile = MiniZip.unzFile
typealias zip_fileinfo = MiniZip.zip_fileinfo
typealias unz_file_info = MiniZip.unz_file_info
typealias unz_file_info_ptr = UnsafeMutablePointer<unz_file_info>
typealias unz_file_info64 = MiniZip.unz_file_info64
typealias unz_file_info64_ptr = UnsafeMutablePointer<unz_file_info64>


extension unz_file_info_ptr {
    init() {
        self = unz_file_info_ptr.allocate(capacity: MemoryLayout<unz_file_info_ptr>.size)
    }
}

extension unz_file_info64_ptr {
    init() {
        self = unz_file_info64_ptr.allocate(capacity: MemoryLayout<unz_file_info64>.size)
    }
}

#else
let is64Bit = com.sun.jna.Native.POINTER_SIZE == 8
let is32Bit = com.sun.jna.Native.POINTER_SIZE == 4

typealias zipFile = OpaquePointer
typealias unzFile = OpaquePointer
typealias zip_fileinfo = OpaquePointer

// 32-bit structure for file info
typealias unz_file_info_ptr = unz_file_info


// SKIP INSERT: @com.sun.jna.Structure.FieldOrder("version", "version_needed", "flag", "compression_method", "dos_date", "tmu_date", "crc", "compressed_size", "uncompressed_size", "size_filename", "size_file_extra", "size_file_comment", "disk_num_start", "internal_fa", "external_fa", "disk_offset", "size_file_extra_internal")
public final class unz_file_info : SkipFFIStructure {
    /* SKIP INSERT: @JvmField */ public var version: FFIUInt16 = 0 /* version made by 2 bytes */
    /* SKIP INSERT: @JvmField */ public var version_needed: FFIUInt16 = 0 /* version needed to extract 2 bytes */
    /* SKIP INSERT: @JvmField */ public var flag: FFIUInt16 = 0 /* general purpose bit flag 2 bytes */
    /* SKIP INSERT: @JvmField */ public var compression_method: FFIUInt16 = 0 /* compression method 2 bytes */
    /* SKIP INSERT: @JvmField */ public var dos_date: FFIUInt32 = 0 /* last mod file date in Dos fmt 4 bytes */
    /* SKIP INSERT: @JvmField */ public var tmu_date: tm = tm()
    /* SKIP INSERT: @JvmField */ public var crc: FFIUInt32 = 0 /* crc-32 4 bytes */
    /* SKIP INSERT: @JvmField */ public var compressed_size: FFIUInt32 = 0 /* compressed size 8 bytes */
    /* SKIP INSERT: @JvmField */ public var uncompressed_size: FFIUInt32 = 0 /* uncompressed size 8 bytes */
    /* SKIP INSERT: @JvmField */ public var size_filename: FFIUInt16 = 0 /* filename length 2 bytes */
    /* SKIP INSERT: @JvmField */ public var size_file_extra: FFIUInt16 = 0 /* extra field length 2 bytes */
    /* SKIP INSERT: @JvmField */ public var size_file_comment: FFIUInt16 = 0 /* file comment length 2 bytes */

    /* SKIP INSERT: @JvmField */ public var disk_num_start: FFIUInt16 = 0 /* disk number start 4 bytes */
    /* SKIP INSERT: @JvmField */ public var internal_fa: FFIUInt16 = 0 /* internal file attributes 2 bytes */
    /* SKIP INSERT: @JvmField */ public var external_fa: FFIUInt32 = 0 /* external file attributes 4 bytes */

    /* SKIP INSERT: @JvmField */ public var disk_offset: FFIUInt64 = 0
}


// 64-bit structure for file info
typealias unz_file_info64_ptr = unz_file_info64

// SKIP INSERT: @com.sun.jna.Structure.FieldOrder("version", "version_needed", "flag", "compression_method", "dos_date", "tmu_date", "crc", "compressed_size", "uncompressed_size", "size_filename", "size_file_extra", "size_file_comment", "disk_num_start", "internal_fa", "external_fa", "disk_offset", "size_file_extra_internal")
public final class unz_file_info64 : SkipFFIStructure {
    /* SKIP INSERT: @JvmField */ public var version: FFIUInt16 = 0 /* version made by 2 bytes */
    /* SKIP INSERT: @JvmField */ public var version_needed: FFIUInt16 = 0 /* version needed to extract 2 bytes */
    /* SKIP INSERT: @JvmField */ public var flag: FFIUInt16 = 0 /* general purpose bit flag 2 bytes */
    /* SKIP INSERT: @JvmField */ public var compression_method: FFIUInt16 = 0 /* compression method 2 bytes */
    /* SKIP INSERT: @JvmField */ public var dos_date: FFIUInt32 = 0 /* last mod file date in Dos fmt 4 bytes */
    /* SKIP INSERT: @JvmField */ public var tmu_date: tm = tm()
    /* SKIP INSERT: @JvmField */ public var crc: FFIUInt32 = 0 /* crc-32 4 bytes */
    /* SKIP INSERT: @JvmField */ public var compressed_size: FFIUInt64 = 0 /* compressed size 8 bytes */
    /* SKIP INSERT: @JvmField */ public var uncompressed_size: FFIUInt64 = 0 /* uncompressed size 8 bytes */
    /* SKIP INSERT: @JvmField */ public var size_filename: FFIUInt16 = 0 /* filename length 2 bytes */
    /* SKIP INSERT: @JvmField */ public var size_file_extra: FFIUInt16 = 0 /* extra field length 2 bytes */
    /* SKIP INSERT: @JvmField */ public var size_file_comment: FFIUInt16 = 0 /* file comment length 2 bytes */

    /* SKIP INSERT: @JvmField */ public var disk_num_start: FFIUInt32 = 0 /* disk number start 4 bytes */
    /* SKIP INSERT: @JvmField */ public var internal_fa: FFIUInt16 = 0 /* internal file attributes 2 bytes */
    /* SKIP INSERT: @JvmField */ public var external_fa: FFIUInt32 = 0 /* external file attributes 4 bytes */

    /* SKIP INSERT: @JvmField */ public var disk_offset: FFIUInt64 = 0

    /* SKIP INSERT: @JvmField */ public var size_file_extra_internal: FFIUInt16 = 0
}

// SKIP INSERT: @com.sun.jna.Structure.FieldOrder("tm_sec", "tm_min", "tm_hour", "tm_mday", "tm_mon", "tm_year", "tm_wday", "tm_yday", "tm_isdst", "tm_gmtoff", "tm_zone")
public final class tm : SkipFFIStructure {
    /* SKIP INSERT: @JvmField */ public var tm_sec: Int32 = Int32(0) /* seconds after the minute [0-60] */
    /* SKIP INSERT: @JvmField */ public var tm_min: Int32 = Int32(0) /* minutes after the hour [0-59] */
    /* SKIP INSERT: @JvmField */ public var tm_hour: Int32 = Int32(0) /* hours since midnight [0-23] */
    /* SKIP INSERT: @JvmField */ public var tm_mday: Int32 = Int32(0) /* day of the month [1-31] */
    /* SKIP INSERT: @JvmField */ public var tm_mon: Int32 = Int32(0) /* months since January [0-11] */
    /* SKIP INSERT: @JvmField */ public var tm_year: Int32 = Int32(0) /* years since 1900 */
    /* SKIP INSERT: @JvmField */ public var tm_wday: Int32 = Int32(0) /* days since Sunday [0-6] */
    /* SKIP INSERT: @JvmField */ public var tm_yday: Int32 = Int32(0) /* days since January 1 [0-365] */
    /* SKIP INSERT: @JvmField */ public var tm_isdst: Int32 = Int32(0) /* Daylight Savings Time flag */
    /* SKIP INSERT: @JvmField */ public var tm_gmtoff: Int64 = Int64(0) /* offset from UTC in seconds */
    /* SKIP INSERT: @JvmField */ public var tm_zone: OpaquePointer? = nil /* timezone abbreviation */
}


/// Fake the cString call, since we are using JNA's String/pointer conversions
//func String(cString: ctmbstr) -> String {
//    //cString.getString(0)
//    cString
//}

#endif

extension unz_file_info : ZipEntryInfo {
    var filenameSize: UInt16 { UInt16(size_filename) }
    var commentSize: UInt16 { UInt16(size_file_comment) }
    var crc32: UInt32 { UInt32(crc) }
    var compressedSize: UInt64 { UInt64(compressed_size) }
    var uncompressedSize: UInt64 { UInt64(uncompressed_size) }
}

extension unz_file_info64 : ZipEntryInfo {
    var filenameSize: UInt16 { UInt16(size_filename) }
    var commentSize: UInt16 { UInt16(size_file_comment) }
    var crc32: UInt32 { UInt32(crc) }
    var compressedSize: UInt64 { UInt64(compressed_size) }
    var uncompressedSize: UInt64 { UInt64(uncompressed_size) }
}


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

    /* SKIP EXTERN */ public func unzGetCurrentFileInfo64(file: unzFile, pfile_info: unz_file_info64_ptr?, filename: FFIStringPointer?, filename_size: FFIUInt, extrafield: UnsafeMutableRawPointer?, extrafield_size: FFIUInt, comment: FFIStringPointer?, comment_size: FFIUInt) -> Int32 {
        MiniZip.unzGetCurrentFileInfo64(file, pfile_info, filename, filename_size, extrafield, extrafield_size, comment, comment_size)
    }

    /* SKIP EXTERN */ public func unzGetCurrentFileInfo(file: unzFile, pfile_info: unz_file_info_ptr?, filename: FFIStringPointer?, filename_size: FFIUInt, extrafield: UnsafeMutableRawPointer?, extrafield_size: FFIUInt, comment: FFIStringPointer?, comment_size: FFIUInt) -> Int32 {
        MiniZip.unzGetCurrentFileInfo(file, pfile_info, filename, filename_size, extrafield, extrafield_size, comment, comment_size)
    }

    /* SKIP EXTERN */ public func unzOpenCurrentFile(file: unzFile) -> Int32 {
        MiniZip.unzOpenCurrentFile(file)
    }

    /* SKIP EXTERN */ public func unzReadCurrentFile(file: unzFile, buf: FFIDataPointer, len: FFIUInt32) -> Int32 {
        MiniZip.unzReadCurrentFile(file, buf, len)
    }

    /* SKIP EXTERN */ public func unzCloseCurrentFile(file: unzFile) -> Int32 {
        MiniZip.unzCloseCurrentFile(file)
    }

    /* SKIP EXTERN */ public func zipOpen64(path: String, append: Int32) -> zipFile? {
        MiniZip.zipOpen64(path, append)
    }

    /* SKIP EXTERN */ public func zipClose_64(file: zipFile, comment: String?) -> Int32 {
        MiniZip.zipClose_64(file, comment)
    }

    /* SKIP EXTERN */ public func zipOpenNewFileInZip_64(file: zipFile, filename: String, zipfi: UnsafePointer<zip_fileinfo>?, extrafield_local: UnsafeRawPointer?, size_extrafield_local: FFIUInt16, extrafield_global: UnsafeRawPointer?, size_extrafield_global: FFIUInt16, comment: String?, compression_method: Int32, level: Int32, zip64: Int32) -> Int32 {
        MiniZip.zipOpenNewFileInZip_64(file, filename, zipfi, extrafield_local, size_extrafield_local, extrafield_global, size_extrafield_global, comment, compression_method, level, zip64)
    }

    /* SKIP EXTERN */ public func zipWriteInFileInZip(file: zipFile, buf: UnsafeRawPointer, len: FFIUInt32) -> Int32 {
        MiniZip.zipWriteInFileInZip(file, buf, len)
    }

    /* SKIP EXTERN */ public func zipCloseFileInZip64(file: zipFile) -> Int32 {
        MiniZip.zipCloseFileInZip64(file)
    }
}
