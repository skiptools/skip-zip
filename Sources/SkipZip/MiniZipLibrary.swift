// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
import SkipFFI
#if !SKIP
import MiniZip
#endif

#if !SKIP
typealias zipFile = MiniZip.zipFile
typealias unzFile = MiniZip.unzFile
typealias zip_fileinfo = MiniZip.zip_fileinfo
typealias zip_UInt = UInt
typealias zip_UInt8 = UInt8
typealias zip_UInt16 = UInt16
typealias zip_UInt32 = UInt32
typealias zip_UInt64 = UInt64
typealias unz_file_info64 = MiniZip.unz_file_info64
typealias unz_file_info64_ptr = UnsafeMutablePointer<unz_file_info64>
#else
typealias zipFile = OpaquePointer
typealias unzFile = OpaquePointer
typealias zip_fileinfo = OpaquePointer
typealias zip_UInt = Int64 // Java has no native UInt
typealias zip_UInt8 = Int8 // Java has no native UInt
typealias zip_UInt16 = Int16 // Java has no native UInt
typealias zip_UInt32 = Int32 // Java has no native UInt
typealias zip_UInt64 = Int64 // Java has no native UInt
//typealias unz_file_info64 = OpaquePointer

// SKIP INSERT: @com.sun.jna.Structure.FieldOrder("version", "version_needed", "flag", "compression_method", "dos_date", "tmu_date", "crc", "compressed_size", "uncompressed_size", "size_filename", "size_file_extra", "size_file_comment", "disk_num_start", "internal_fa", "external_fa", "disk_offset", "size_file_extra_internal")
public final class unz_file_info64_ptr : SkipFFIStructure {
    /* SKIP INSERT: @JvmField */ public var version: zip_UInt16 /* version made by 2 bytes */
    /* SKIP INSERT: @JvmField */ public var version_needed: zip_UInt16 /* version needed to extract 2 bytes */
    /* SKIP INSERT: @JvmField */ public var flag: zip_UInt16 /* general purpose bit flag 2 bytes */
    /* SKIP INSERT: @JvmField */ public var compression_method: zip_UInt16 /* compression method 2 bytes */
    /* SKIP INSERT: @JvmField */ public var dos_date: zip_UInt32 /* last mod file date in Dos fmt 4 bytes */
    /* SKIP INSERT: @JvmField */ public var tmu_date: tm
    /* SKIP INSERT: @JvmField */ public var crc: zip_UInt32 /* crc-32 4 bytes */
    /* SKIP INSERT: @JvmField */ public var compressed_size: zip_UInt16 /* compressed size 8 bytes */
    /* SKIP INSERT: @JvmField */ public var uncompressed_size: zip_UInt16 /* uncompressed size 8 bytes */
    /* SKIP INSERT: @JvmField */ public var size_filename: zip_UInt16 /* filename length 2 bytes */
    /* SKIP INSERT: @JvmField */ public var size_file_extra: zip_UInt16 /* extra field length 2 bytes */
    /* SKIP INSERT: @JvmField */ public var size_file_comment: zip_UInt16 /* file comment length 2 bytes */

    /* SKIP INSERT: @JvmField */ public var disk_num_start: zip_UInt32 /* disk number start 4 bytes */
    /* SKIP INSERT: @JvmField */ public var internal_fa: zip_UInt16 /* internal file attributes 2 bytes */
    /* SKIP INSERT: @JvmField */ public var external_fa: zip_UInt32 /* external file attributes 4 bytes */

    /* SKIP INSERT: @JvmField */ public var disk_offset: zip_UInt64

    /* SKIP INSERT: @JvmField */ public var size_file_extra_internal: zip_UInt16

    init(version: zip_UInt16, version_needed: zip_UInt16, flag: zip_UInt16, compression_method: zip_UInt16, dos_date: zip_UInt32, tmu_date: tm, crc: zip_UInt32, compressed_size: zip_UInt16, uncompressed_size: zip_UInt16, size_filename: zip_UInt16, size_file_extra: zip_UInt16, size_file_comment: zip_UInt16, disk_num_start: zip_UInt32, internal_fa: zip_UInt16, external_fa: zip_UInt32, disk_offset: zip_UInt64, size_file_extra_internal: zip_UInt16) {
        self.version = version
        self.version_needed = version_needed
        self.flag = flag
        self.compression_method = compression_method
        self.dos_date = dos_date
        self.tmu_date = tmu_date
        self.crc = crc
        self.compressed_size = compressed_size
        self.uncompressed_size = uncompressed_size
        self.size_filename = size_filename
        self.size_file_extra = size_file_extra
        self.size_file_comment = size_file_comment
        self.disk_num_start = disk_num_start
        self.internal_fa = internal_fa
        self.external_fa = external_fa
        self.disk_offset = disk_offset
        self.size_file_extra_internal = size_file_extra_internal
    }
}

// SKIP INSERT: @com.sun.jna.Structure.FieldOrder("tm_sec", "tm_min", "tm_hour", "tm_mday", "tm_mon", "tm_year", "tm_wday", "tm_yday", "tm_isdst", "tm_gmtoff", "tm_zone")
public final class tm : SkipFFIStructure {
    public var tm_sec: Int32 /* seconds after the minute [0-60] */
    public var tm_min: Int32 /* minutes after the hour [0-59] */
    public var tm_hour: Int32 /* hours since midnight [0-23] */
    public var tm_mday: Int32 /* day of the month [1-31] */
    public var tm_mon: Int32 /* months since January [0-11] */
    public var tm_year: Int32 /* years since 1900 */
    public var tm_wday: Int32 /* days since Sunday [0-6] */
    public var tm_yday: Int32 /* days since January 1 [0-365] */
    public var tm_isdst: Int32 /* Daylight Savings Time flag */
    public var tm_gmtoff: Int64 /* offset from UTC in seconds */
    public var tm_zone: String /* timezone abbreviation */

    init(tm_sec: Int32, tm_min: Int32, tm_hour: Int32, tm_mday: Int32, tm_mon: Int32, tm_year: Int32, tm_wday: Int32, tm_yday: Int32, tm_isdst: Int32, tm_gmtoff: Int64, tm_zone: String) {
        self.tm_sec = tm_sec
        self.tm_min = tm_min
        self.tm_hour = tm_hour
        self.tm_mday = tm_mday
        self.tm_mon = tm_mon
        self.tm_year = tm_year
        self.tm_wday = tm_wday
        self.tm_yday = tm_yday
        self.tm_isdst = tm_isdst
        self.tm_gmtoff = tm_gmtoff
        self.tm_zone = tm_zone
    }
}
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

    /* SKIP EXTERN */ public func unzGetCurrentFileInfo64(file: unzFile, pfile_info: unz_file_info64_ptr?, filename: UnsafeMutablePointer<CChar>?, filename_size: zip_UInt, extrafield: UnsafeMutableRawPointer?, extrafield_size: zip_UInt, comment: UnsafeMutablePointer<CChar>?, comment_size: zip_UInt) -> Int32 {
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
