// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Swift
import Foundation
#if SKIP
import SkipFFI
#else
import zlib
#endif

/// `ZlibLibrary` is an encapsulation of `libz` functions and structures.
public final class ZlibLibrary {
    public typealias z_streamp = UnsafeMutablePointer<z_stream> // zlib.z_streamp

    public init() {
        #if SKIP
        com.sun.jna.Native.register((ZlibLibrary.self as kotlin.reflect.KClass).java, "z")
        #endif
    }

    public var Z_OK: Int32 {
        #if !SKIP
        assert(zlib.Z_OK == 0, "\(zlib.Z_OK)")
        #endif
        return 0
    }

    public var Z_FINISH: Int32 {
        #if !SKIP
        assert(zlib.Z_FINISH == 4, "\(zlib.Z_FINISH)")
        #endif
        return 4
    }

    public var Z_NO_FLUSH: Int32 {
        #if !SKIP
        assert(zlib.Z_NO_FLUSH == 0, "\(zlib.Z_NO_FLUSH)")
        #endif
        return 0
    }

    public var Z_STREAM_END: Int32 {
        #if !SKIP
        assert(zlib.Z_STREAM_END == 1, "\(zlib.Z_STREAM_END)")
        #endif
        return 1
    }

    public var Z_MEM_ERROR: Int32 {
        #if !SKIP
        assert(zlib.Z_MEM_ERROR == -4, "\(zlib.Z_MEM_ERROR)")
        #endif
        return -4
    }

    public var Z_DATA_ERROR: Int32 {
        #if !SKIP
        assert(zlib.Z_DATA_ERROR == -3, "\(zlib.Z_DATA_ERROR)")
        #endif
        return -3
    }

    public var Z_NEED_DICT: Int32 {
        #if !SKIP
        assert(zlib.Z_NEED_DICT == 2, "\(zlib.Z_NEED_DICT)")
        #endif
        return 2
    }

    public var Z_DEFAULT_COMPRESSION: Int32 {
        #if !SKIP
        assert(zlib.Z_DEFAULT_COMPRESSION == -1, "\(zlib.Z_DEFAULT_COMPRESSION)")
        #endif
        return -1
    }

    public var Z_DEFLATED: Int32 {
        #if !SKIP
        assert(zlib.Z_DEFLATED == 8, "\(zlib.Z_DEFLATED)")
        #endif
        return 8
    }

    public var MAX_WBITS: Int32 {
        #if !SKIP
        assert(zlib.MAX_WBITS == 15, "\(zlib.MAX_WBITS)")
        #endif
        return 15
    }

    public var Z_DEFAULT_STRATEGY: Int32 {
        #if !SKIP
        assert(zlib.Z_DEFAULT_STRATEGY == 0, "\(zlib.Z_DEFAULT_STRATEGY)")
        #endif
        return 0
    }

//    public var Z_NO_FLUSH: Int32 { get }
//    public var Z_PARTIAL_FLUSH: Int32 { get }
//    public var Z_SYNC_FLUSH: Int32 { get }
//    public var Z_FULL_FLUSH: Int32 { get }
//    public var Z_FINISH: Int32 { get }
//    public var Z_BLOCK: Int32 { get }
//    public var Z_TREES: Int32 { get }
//    /* Allowed flush values; see deflate() and inflate() below for details */
//
//    public var Z_OK: Int32 { get }
//    public var Z_STREAM_END: Int32 { get }
//    public var Z_NEED_DICT: Int32 { get }
//    public var Z_ERRNO: Int32 { get }
//    public var Z_STREAM_ERROR: Int32 { get }
//    public var Z_DATA_ERROR: Int32 { get }
//    public var Z_MEM_ERROR: Int32 { get }
//    public var Z_BUF_ERROR: Int32 { get }
//    public var Z_VERSION_ERROR: Int32 { get }
//    /* Return codes for the compression/decompression functions. Negative values
//     * are errors, positive values are used for special but normal events.
//     */
//
//    public var Z_NO_COMPRESSION: Int32 { get }
//    public var Z_BEST_SPEED: Int32 { get }
//    public var Z_BEST_COMPRESSION: Int32 { get }
//    public var Z_DEFAULT_COMPRESSION: Int32 { get }
//    /* compression levels */
//
//    public var Z_FILTERED: Int32 { get }
//    public var Z_HUFFMAN_ONLY: Int32 { get }
//    public var Z_RLE: Int32 { get }
//    public var Z_FIXED: Int32 { get }
//    public var Z_DEFAULT_STRATEGY: Int32 { get }
//    /* compression strategy; see deflateInit2() below for details */
//
//    public var Z_BINARY: Int32 { get }
//    public var Z_TEXT: Int32 { get }
//    public var Z_ASCII: Int32 { get } /* for compatibility with 1.2.2 and earlier */
//    public var Z_UNKNOWN: Int32 { get }
//    /* Possible values of the data_type field for deflate() */
//
//    public var Z_DEFLATED: Int32 { get }
//    /* The deflate compression method (the only one supported in this version) */
//
//    public var Z_NULL: Int32 { get } /* for initializing zalloc, zfree, opaque */

    public var ZLIB_VERSION: String {
        return zlibVersion()
    }


    // SKIP EXTERN
    public func zlibVersion() -> String {
        String(cString: zlib.zlibVersion()!)
    }

    // SKIP EXTERN
    public func zError(code: Int32) -> String {
        String(cString: zlib.zError(code)!)
    }


    #if !SKIP
    public typealias z_stream = zlib.z_stream
    #else
    // SKIP INSERT: @com.sun.jna.Structure.FieldOrder("next_in", "avail_in", "total_in", "next_out", "avail_out", "total_out", "msg", "state", "zalloc", "zfree", "opaque", "data_type", "adler", "reserved")
    public final class z_stream : SkipFFIStructure {
        // otherwise: "JvmField cannot be applied to a property with a custom accessor" due to accessor being created for this type
        // SKIP REPLACE: @JvmField var next_in: OpaquePointer?
        public var next_in: OpaquePointer?
        // SKIP INSERT: @JvmField
        public var avail_in: Int32
        // SKIP INSERT: @JvmField
        public var total_in: Int64

        // SKIP REPLACE: @JvmField var next_out: OpaquePointer?
        public var next_out: OpaquePointer?
        // SKIP INSERT: @JvmField
        public var avail_out: Int32
        // SKIP INSERT: @JvmField
        public var total_out: Int64

        // SKIP INSERT: @JvmField
        public var msg: String?
        // SKIP REPLACE: @JvmField var state: OpaquePointer?
        public var state: OpaquePointer?

        // SKIP REPLACE: @JvmField var zalloc: OpaquePointer?
        public var zalloc: OpaquePointer?
        // SKIP REPLACE: @JvmField var zfree: OpaquePointer?
        public var zfree: OpaquePointer?
        // SKIP REPLACE: @JvmField var opaque: OpaquePointer?
        public var opaque: OpaquePointer?

        // SKIP INSERT: @JvmField
        public var data_type: Int32
        // SKIP INSERT: @JvmField
        public var adler: Int32
        // SKIP INSERT: @JvmField
        public var reserved: Int64

        public init(next_in: OpaquePointer? = nil, avail_in: Int32 = 0, total_in: Int64 = 0, next_out: OpaquePointer? = nil, avail_out: Int32 = 0, total_out: Int64 = 0, msg: String? = nil, state: OpaquePointer? = nil, zalloc: OpaquePointer? = nil, zfree: OpaquePointer? = nil, opaque: OpaquePointer? = nil, data_type: Int32 = 0, adler: Int32 = 0, reserved: Int64 = 0) {
            self.next_in = next_in
            self.avail_in = avail_in
            self.total_in = total_in
            self.next_out = next_out
            self.avail_out = avail_out
            self.total_out = total_out
            self.msg = msg
            self.state = state
            self.zalloc = zalloc
            self.zfree = zfree
            self.opaque = opaque
            self.data_type = data_type
            self.adler = adler
            self.reserved = reserved
        }
    }
    #endif

    /*
         gzip header information passed to and from zlib routines.  See RFC 1952
      for more details on the meanings of these fields.
    */
//    public struct gz_header_s {
//        public init()
//        public init(text: Int32, time: UInt64, xflags: Int32, os: Int32, extra: UnsafeMutablePointer<UInt8>!, extra_len: UInt32, extra_max: UInt32, name: UnsafeMutablePointer<UInt8>!, name_max: UInt32, comment: UnsafeMutablePointer<UInt8>!, comm_max: UInt32, hcrc: Int32, done: Int32)
//        public var text: Int32 /* true if compressed data believed to be text */
//        public var time: UInt64 /* modification time */
//        public var xflags: Int32 /* extra flags (not used when writing a gzip file) */
//        public var os: Int32 /* operating system */
//        public var extra: UnsafeMutablePointer<UInt8>! /* pointer to extra field or Z_NULL if none */
//        public var extra_len: UInt32 /* extra field length (valid if extra != Z_NULL) */
//        public var extra_max: UInt32 /* space at extra (only when reading header) */
//        public var name: UnsafeMutablePointer<UInt8>! /* pointer to zero-terminated file name or Z_NULL */
//        public var name_max: UInt32 /* space at name (only when reading header) */
//        public var comment: UnsafeMutablePointer<UInt8>! /* pointer to zero-terminated comment or Z_NULL */
//        public var comm_max: UInt32 /* space at comment (only when reading header) */
//        public var hcrc: Int32 /* true if there was or will be a header crc */
//        public var done: Int32 /* true when done reading gzip header (not used when writing a gzip file) */
//    }
//    public typealias gz_header = gz_header_s
//    public typealias gz_headerp = UnsafeMutablePointer<gz_header>

    #if SKIP
    // SKIP INSERT: @com.sun.jna.Structure.FieldOrder("have", "next", "pos")
    public final class gzFile_s : SkipFFIStructure {
        // SKIP REPLACE: @JvmField var have: Int // Unsigned types use the same mappings as signed types
        public var have: UInt32
        // SKIP REPLACE: @JvmField var next: com.sun.jna.ptr.PointerByReference
        public var next: UnsafeMutablePointer<UInt8>!
        // SKIP REPLACE: @JvmField var pos: Long
        public var pos: Int64

        init(have: Int, next: UnsafeMutablePointer<UInt8>!, pos: Int64) {
            self.have = have
            self.next = next
            self.pos = pos
        }
    }

    public typealias gzFile = UnsafeMutablePointer<gzFile_s> /* semi-opaque gzip file descriptor */
    #endif

//    public typealias in_func = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?) -> UInt32
//
//    public typealias out_func = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UInt8>?, UInt32) -> Int32

    // SKIP EXTERN
    public func zlibCompileFlags() -> ZUInt { return zlib.zlibCompileFlags() }

    #if SKIP
    // needed for JNA mappings to line up
    public typealias ZUInt = Int
    public typealias ZUInt32 = Int
    #else
    public typealias ZUInt = UInt
    public typealias ZUInt32 = UInt32
    #endif


    // SKIP EXTERN
    public func adler32(_ adler: ZUInt, _ buf: UnsafePointer<UInt8>!, _ len: ZUInt32) -> ZUInt { return zlib.adler32(adler, buf, len) }
    // SKIP EXTERN
    public func adler32_z(_ adler: ZUInt, _ buf: UnsafePointer<UInt8>!, _ len: Int) -> ZUInt { return zlib.adler32_z(adler, buf, len) }
    // SKIP EXTERN
    public func crc32(_ crc: ZUInt, _ buf: UnsafePointer<UInt8>!, _ len: ZUInt32) -> ZUInt { return zlib.crc32(crc, buf, len) }
    // SKIP EXTERN
    public func crc32_z(_ crc: ZUInt, _ buf: UnsafePointer<UInt8>!, _ len: Int) -> ZUInt { return zlib.crc32_z(crc, buf, len) }
    // SKIP EXTERN
    //public func crc32_combine_op(_ crc1: UInt64, _ crc2: UInt64, _ op: UInt64) -> UInt64 { return zlib.crc32_combine_op(crc1, crc2, op) }
    // SKIP EXTERN
    public func adler32_combine(_ a1: ZUInt, _ a2: ZUInt, _ a3: Int) -> ZUInt { return zlib.adler32_combine(a1, a2, a3) }
    // SKIP EXTERN
    public func crc32_combine(_ a1: ZUInt, _ a2: ZUInt, _ a3: Int) -> ZUInt { return zlib.crc32_combine(a1, a2, a3) }
    // SKIP EXTERN
//    public func crc32_combine_gen(_ a1: Int) -> ZUInt { return zlib.crc32_combine_gen(a1) }

    // MARK: one-shot compress/uncompress

    // SKIP EXTERN
    public func compress(_ dest: UnsafeMutablePointer<UInt8>!, _ destLen: UnsafeMutablePointer<UInt>!, _ source: UnsafePointer<UInt8>!, _ sourceLen: ZUInt) -> Int32 { return zlib.compress(dest, destLen, source, sourceLen) }
    // SKIP EXTERN
    public func compress2(_ dest: UnsafeMutablePointer<UInt8>!, _ destLen: UnsafeMutablePointer<UInt>!, _ source: UnsafePointer<UInt8>!, _ sourceLen: ZUInt, _ level: Int32) -> Int32 { return zlib.compress2(dest, destLen, source, sourceLen, level) }
    // SKIP EXTERN
    public func compressBound(_ sourceLen: ZUInt) -> ZUInt { return zlib.compressBound(sourceLen) }


    // SKIP EXTERN
    public func uncompress(_ dest: UnsafeMutablePointer<UInt8>!, _ destLen: UnsafeMutablePointer<UInt>!, _ source: UnsafePointer<UInt8>!, _ sourceLen: ZUInt) -> Int32 { return zlib.uncompress(dest, destLen, source, sourceLen) }
    // SKIP EXTERN
    public func uncompress2(_ dest: UnsafeMutablePointer<UInt8>!, _ destLen: UnsafeMutablePointer<UInt>!, _ source: UnsafePointer<UInt8>!, _ sourceLen: UnsafeMutablePointer<UInt>!) -> Int32 { return zlib.uncompress2(dest, destLen, source, sourceLen) }

    // SKIP EXTERN
    public func deflate(_ strm: z_streamp!, _ flush: Int32) -> Int32 { return zlib.deflate(strm, flush) }
    // SKIP EXTERN
    public func deflateEnd(_ strm: z_streamp!) -> Int32 { return zlib.deflateEnd(strm) }
    // SKIP EXTERN
    public func inflate(_ strm: z_streamp!, _ flush: Int32) -> Int32 { return zlib.inflate(strm, flush) }
    // SKIP EXTERN
    public func inflateEnd(_ strm: z_streamp!) -> Int32 { return zlib.inflateEnd(strm) }
    // SKIP EXTERN
    public func deflateSetDictionary(_ strm: z_streamp!, _ dictionary: UnsafePointer<UInt8>!, _ dictLength: ZUInt32) -> Int32 { return zlib.deflateSetDictionary(strm, dictionary, dictLength) }
    // SKIP EXTERN
    public func deflateGetDictionary(_ strm: z_streamp!, _ dictionary: UnsafeMutablePointer<UInt8>!, _ dictLength: UnsafeMutablePointer<UInt32>!) -> Int32 { return zlib.deflateGetDictionary(strm, dictionary, dictLength) }
    // SKIP EXTERN
    public func deflateCopy(_ dest: z_streamp!, _ source: z_streamp!) -> Int32 { return zlib.deflateCopy(dest, source) }
    // SKIP EXTERN
    public func deflateReset(_ strm: z_streamp!) -> Int32 { return zlib.deflateReset(strm) }
    // SKIP EXTERN
    public func deflateParams(_ strm: z_streamp!, _ level: Int32, _ strategy: Int32) -> Int32 { return zlib.deflateParams(strm, level, strategy) }
    // SKIP EXTERN
    public func deflateTune(_ strm: z_streamp!, _ good_length: Int32, _ max_lazy: Int32, _ nice_length: Int32, _ max_chain: Int32) -> Int32 { return zlib.deflateTune(strm, good_length, max_lazy, nice_length, max_chain) }
    // SKIP EXTERN
    public func deflateBound(_ strm: z_streamp!, _ sourceLen: ZUInt) -> ZUInt { return zlib.deflateBound(strm, sourceLen) }
    // SKIP EXTERN
    public func deflatePending(_ strm: z_streamp!, _ pending: UnsafeMutablePointer<UInt32>!, _ bits: UnsafeMutablePointer<Int32>!) -> Int32 { return zlib.deflatePending(strm, pending, bits) }
    // SKIP EXTERN
    public func deflatePrime(_ strm: z_streamp!, _ bits: Int32, _ value: Int32) -> Int32 { return zlib.deflatePrime(strm, bits, value) }
    // SKIP EXTERN
//    public func deflateSetHeader(_ strm: z_streamp!, _ head: gz_headerp!) -> Int32 { return zlib.deflateSetHeader(strm, head) }


    // SKIP EXTERN
    public func deflateInit_(_ strm: z_streamp!, _ level: Int32, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 { return zlib.deflateInit_(strm, level, version, stream_size) }
    // SKIP EXTERN
    public func inflateInit_(_ strm: z_streamp!, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 { return zlib.inflateInit_(strm, version, stream_size) }


    // SKIP EXTERN
    public func deflateInit2_(_ strm: z_streamp!, _ level: Int32, _ method: Int32, _ windowBits: Int32, _ memLevel: Int32, _ strategy: Int32, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 { return zlib.deflateInit2_(strm, level, method, windowBits, memLevel, strategy, version, stream_size) }
    // SKIP EXTERN
    public func inflateInit2_(_ strm: z_streamp!, _ windowBits: Int32, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 { return zlib.inflateInit2_(strm, windowBits, version, stream_size) }


    // SKIP EXTERN
    public func inflateBackInit_(_ strm: z_streamp!, _ windowBits: Int32, _ window: UnsafeMutablePointer<UInt8>!, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 { return zlib.inflateBackInit_(strm, windowBits, window, version, stream_size) }

    // SKIP EXTERN
    public func inflateSyncPoint(_ a1: z_streamp!) -> Int32 { return zlib.inflateSyncPoint(a1) }
    // SKIP EXTERN
    public func inflateUndermine(_ a1: z_streamp!, _ a2: Int32) -> Int32 { return zlib.inflateUndermine(a1, a2) }
    // SKIP EXTERN
    public func inflateValidate(_ a1: z_streamp!, _ a2: Int32) -> Int32 { return zlib.inflateValidate(a1, a2) }
    // SKIP EXTERN
    public func inflateCodesUsed(_ a1: z_streamp!) -> ZUInt { return zlib.inflateCodesUsed(a1) }
    // SKIP EXTERN
    public func inflateResetKeep(_ a1: z_streamp!) -> Int32 { return zlib.inflateResetKeep(a1) }
    // SKIP EXTERN
    public func deflateResetKeep(_ a1: z_streamp!) -> Int32 { return zlib.deflateResetKeep(a1) }

    // SKIP EXTERN
    public func inflateSetDictionary(_ strm: z_streamp!, _ dictionary: UnsafePointer<UInt8>!, _ dictLength: ZUInt32) -> Int32 { return zlib.inflateSetDictionary(strm, dictionary, dictLength) }
    // SKIP EXTERN
    public func inflateSync(_ strm: z_streamp!) -> Int32 { return zlib.inflateSync(strm) }
    // SKIP EXTERN
    public func inflateCopy(_ dest: z_streamp!, _ source: z_streamp!) -> Int32 { return zlib.inflateCopy(dest, source) }
    // SKIP EXTERN
    public func inflateReset(_ strm: z_streamp!) -> Int32 { return zlib.inflateReset(strm) }
    // SKIP EXTERN
    public func inflateReset2(_ strm: z_streamp!, _ windowBits: Int32) -> Int32 { return zlib.inflateReset2(strm, windowBits) }
    // SKIP EXTERN
    public func inflatePrime(_ strm: z_streamp!, _ bits: Int32, _ value: Int32) -> Int32 { return zlib.inflatePrime(strm, bits, value) }
    // SKIP EXTERN
    public func inflateMark(_ strm: z_streamp!) -> Int { return zlib.inflateMark(strm) }
    // SKIP EXTERN
//    public func inflateGetHeader(_ strm: z_streamp!, _ head: gz_headerp!) -> Int32 { return zlib.inflateGetHeader(strm, head) }
    // SKIP EXTERN
//    public func inflateBack(_ strm: z_streamp!, _ in: in_func!, _ in_desc: UnsafeMutableRawPointer!, _ out: out_func!, _ out_desc: UnsafeMutableRawPointer!) -> Int32 { return zlib.inflateBack(strm, `in`, in_desc, out, out_desc) }
    // SKIP EXTERN
    public func inflateBackEnd(_ strm: z_streamp!) -> Int32 { return zlib.inflateBackEnd(strm) }

    // MARK: gzip

    // SKIP EXTERN
    public func gzdopen(_ fd: Int32, _ mode: UnsafePointer<CChar>!) -> gzFile! { return zlib.gzdopen(fd, mode) }

    // SKIP EXTERN
    public func gzbuffer(_ file: gzFile!, _ size: ZUInt32) -> Int32 { return zlib.gzbuffer(file, size) }
    // SKIP EXTERN
    public func gzsetparams(_ file: gzFile!, _ level: Int32, _ strategy: Int32) -> Int32 { return zlib.gzsetparams(file, level, strategy) }
    // SKIP EXTERN
    public func gzread(_ file: gzFile!, _ buf: UnsafeMutableRawPointer!, _ len: ZUInt32) -> Int32 { return zlib.gzread(file, buf, len) }
    // SKIP EXTERN
    public func gzfread(_ buf: UnsafeMutableRawPointer!, _ size: Int, _ nitems: Int, _ file: gzFile!) -> Int { return zlib.gzfread(buf, size, nitems, file) }
    // SKIP EXTERN
    public func gzwrite(_ file: gzFile!, _ buf: UnsafeRawPointer!, _ len: ZUInt32) -> Int32 { return zlib.gzwrite(file, buf, len) }
    // SKIP EXTERN
    public func gzfwrite(_ buf: UnsafeRawPointer!, _ size: Int, _ nitems: Int, _ file: gzFile!) -> Int { return zlib.gzfwrite(buf, size, nitems, file) }
    // SKIP EXTERN
    public func gzputs(_ file: gzFile!, _ s: UnsafePointer<CChar>!) -> Int32 { return zlib.gzputs(file, s) }
    // SKIP EXTERN
    public func gzgets(_ file: gzFile!, _ buf: UnsafeMutablePointer<CChar>!, _ len: Int32) -> UnsafeMutablePointer<CChar>! { return zlib.gzgets(file, buf, len) }
    // SKIP EXTERN
    public func gzputc(_ file: gzFile!, _ c: Int32) -> Int32 { return zlib.gzputc(file, c) }
    // SKIP EXTERN
    public func gzgetc(_ file: gzFile!) -> Int32 { return zlib.gzgetc(file) }
    // SKIP EXTERN
    public func gzungetc(_ c: Int32, _ file: gzFile!) -> Int32 { return zlib.gzungetc(c, file) }
    // SKIP EXTERN
    public func gzflush(_ file: gzFile!, _ flush: Int32) -> Int32 { return zlib.gzflush(file, flush) }
    // SKIP EXTERN
    public func gzrewind(_ file: gzFile!) -> Int32 { return zlib.gzrewind(file) }
    // SKIP EXTERN
    public func gzeof(_ file: gzFile!) -> Int32 { return zlib.gzeof(file) }
    // SKIP EXTERN
    public func gzdirect(_ file: gzFile!) -> Int32 { return zlib.gzdirect(file) }
    // SKIP EXTERN
    public func gzclose(_ file: gzFile!) -> Int32 { return zlib.gzclose(file) }
    // SKIP EXTERN
    public func gzclose_r(_ file: gzFile!) -> Int32 { return zlib.gzclose_r(file) }
    // SKIP EXTERN
    public func gzclose_w(_ file: gzFile!) -> Int32 { return zlib.gzclose_w(file) }
    // SKIP EXTERN
    public func gzerror(_ file: gzFile!, _ errnum: UnsafeMutablePointer<Int32>!) -> UnsafePointer<CChar>! { return zlib.gzerror(file, errnum) }
    // SKIP EXTERN
    public func gzclearerr(_ file: gzFile!) { return zlib.gzclearerr(file)}

    // SKIP EXTERN
    public func gzgetc_(_ file: gzFile!) -> Int32 { return zlib.gzgetc_(file) }
    // SKIP EXTERN
    public func gzopen(_ a1: UnsafePointer<CChar>!, _ a2: UnsafePointer<CChar>!) -> gzFile! { return zlib.gzopen(a1, a2) }
    // SKIP EXTERN
    public func gzseek(_ file: gzFile!, _ a2: Int, _ a3: Int32) -> Int { return zlib.gzseek(file, a2, a3) }
    // SKIP EXTERN
    public func gztell(_ file: gzFile!) -> Int { return zlib.gztell(file) }
    // SKIP EXTERN
    public func gzoffset(_ file: gzFile!) -> Int { return zlib.gzoffset(file) }

    // SKIP EXTERN
    public func get_crc_table() -> UnsafePointer<z_crc_t>! { return zlib.get_crc_table() }

    // SKIP EXTERN
    //public func gzvprintf(_ file: gzFile!, _ format: UnsafePointer<CChar>!, _ va: CVaListPointer) -> Int32 { return zlib.gzvprintf(file, format, va) }
}

