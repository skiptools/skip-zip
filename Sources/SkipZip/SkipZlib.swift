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
        assert(zlib.Z_NO_FLUSH == 0, "\(Z_NO_FLUSH)")
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
    public typealias z_stream = zlib.z_stream

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
    func deflateEnd(_ strm: z_streamp!) -> Int32 {
        zlib.deflateEnd(strm!)
    }

    // SKIP EXTERN
    func inflateInit2_(_ strm: z_streamp!, _ windowBits: Int32, _ version: UnsafePointer<CChar>!, _ stream_size: Int32) -> Int32 {
        zlib.inflateInit2_(strm, windowBits, version, stream_size)
    }

    // SKIP EXTERN
    func inflateEnd(_ strm: z_streamp!) -> Int32 {
        zlib.inflateEnd(strm!)
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

