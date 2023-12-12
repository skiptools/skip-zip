// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Swift
import Foundation
#if SKIP
import SkipFFI
#else
import zlib
#endif

/// `ZlibLibrary` is an encapsulation of `libz` functions and structures.
public final class ZlibLibrary {
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
    public typealias z_streamp = zlib.z_streamp

    // SKIP EXTERN
    public func crc32(_ crc: uLong, _ buf: UnsafePointer<Bytef>!, _ len: uInt) -> uLong {
        zlib.crc32(crc, buf, len)
    }

    // SKIP EXTERN
    func deflate(_ strm: z_streamp, _ flush: Int32) -> Int32 {
        zlib.deflate(strm, flush)
    }

    // SKIP EXTERN
    func inflate(_ strm: z_streamp, _ flush: Int32) -> Int32 {
        zlib.inflate(strm, flush)
    }

    // SKIP EXTERN
    func deflateInit2_(_ strm: z_streamp!, _ level: Int32, _ method: Int32, _ windowBits: Int32, _ memLevel: Int32, _ strategy: Int32, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 {
        zlib.deflateInit2_(strm, level, method, windowBits, memLevel, strategy, version, stream_size)
    }

    // SKIP EXTERN
    @discardableResult func deflateEnd(_ strm: z_streamp!) -> Int32 {
        zlib.deflateEnd(strm!)
    }

    // SKIP EXTERN
    func inflateInit2_(_ strm: z_streamp!, _ windowBits: Int32, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 {
        zlib.inflateInit2_(strm, windowBits, version, stream_size)
    }

    // SKIP EXTERN
    @discardableResult func inflateEnd(_ strm: z_streamp!) -> Int32 {
        zlib.inflateEnd(strm!)
    }

    #endif

    #if !SKIP
    public typealias z_stream = zlib.z_stream
    #else
    // SKIP INSERT: @com.sun.jna.Structure.FieldOrder("next_in", "avail_in", "total_in", "next_out", "avail_out", "total_out", "msg", "state", "zalloc", "zfree", "opaque", "data_type", "adler", "reserved")
    public final class z_stream : com.sun.jna.Structure {
        // SKIP REPLACE: @JvmField var next_in: com.sun.jna.Pointer?
        public var next_in: com.sun.jna.Pointer?
        // SKIP INSERT: @JvmField
        public var avail_in: Int32
        // SKIP INSERT: @JvmField
        public var total_in: Int64

        // otherwise: "JvmField cannot be applied to a property with a custom accessor"
        // SKIP REPLACE: @JvmField var next_out: com.sun.jna.Pointer?
        public var next_out: com.sun.jna.Pointer?
        // SKIP INSERT: @JvmField
        public var avail_out: Int32
        // SKIP INSERT: @JvmField
        public var total_out: Int64

        // SKIP INSERT: @JvmField
        public var msg: String?
        // SKIP REPLACE: @JvmField var state: com.sun.jna.Pointer?
        public var state: com.sun.jna.Pointer?

        // SKIP REPLACE: @JvmField var zalloc: com.sun.jna.Pointer?
        public var zalloc: com.sun.jna.Pointer?
        // SKIP REPLACE: @JvmField var zfree: com.sun.jna.Pointer?
        public var zfree: com.sun.jna.Pointer?
        // SKIP REPLACE: @JvmField var opaque: com.sun.jna.Pointer?
        public var opaque: com.sun.jna.Pointer?

        // SKIP INSERT: @JvmField
        public var data_type: Int32
        // SKIP INSERT: @JvmField
        public var adler: Int32
        // SKIP INSERT: @JvmField
        public var reserved: Int64

        public init(next_in: com.sun.jna.Pointer? = nil, avail_in: Int32 = 0, total_in: Int64 = 0, next_out: com.sun.jna.Pointer? = nil, avail_out: Int32 = 0, total_out: Int64 = 0, msg: String? = nil, state: com.sun.jna.Pointer? = nil, zalloc: com.sun.jna.Pointer? = nil, zfree: com.sun.jna.Pointer? = nil, opaque: com.sun.jna.Pointer? = nil, data_type: Int32 = 0, adler: Int32 = 0, reserved: Int64 = 0) {
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

    //public func gzopen(_: UnsafePointer<CChar>!, _: UnsafePointer<CChar>!) -> gzFile!
    //public func gzseek(_: gzFile!, _: Int, _: Int32) -> Int
    //public func gztell(_: gzFile!) -> Int
    //public func gzoffset(_: gzFile!) -> Int
    //public func adler32_combine(_: uLong, _: uLong, _: Int) -> uLong
    //public func crc32_combine(_: uLong, _: uLong, _: Int) -> uLong
    //public func crc32_combine_gen(_: Int) -> uLong
    //public func zError(_: Int32) -> UnsafePointer<CChar>!
}

