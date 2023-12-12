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

    // SKIP EXTERN
    public func zlibVersion() -> String {
        String(cString: zlib.zlibVersion()!)
    }

    // SKIP EXTERN
    public func zError(code: Int32) -> String {
        String(cString: zlib.zError(code)!)
    }


//    public func gzopen(_: UnsafePointer<CChar>!, _: UnsafePointer<CChar>!) -> gzFile!
//
//    public func gzseek(_: gzFile!, _: Int, _: Int32) -> Int
//
//    public func gztell(_: gzFile!) -> Int
//
//    @available(macOS 10.7, *)
//    public func gzoffset(_: gzFile!) -> Int
//    public func adler32_combine(_: uLong, _: uLong, _: Int) -> uLong
//    public func crc32_combine(_: uLong, _: uLong, _: Int) -> uLong
//    public func crc32_combine_gen(_: Int) -> uLong
//    public func zError(_: Int32) -> UnsafePointer<CChar>!
//

}

