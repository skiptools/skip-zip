/* mz_inflate_raw.c -- Raw DEFLATE decompression using zlib
   Part of MiniZip, providing a simple interface for decompressing
   raw deflate data (without zlib/gzip headers) as stored in zip archives. */

#include <string.h>

#if defined(HAVE_ZLIB)
#include "zlib.h"

int mz_inflate_raw(const void *source, unsigned long sourceLen,
                   void *dest, unsigned long *destLen) {
    z_stream stream;
    int ret;

    memset(&stream, 0, sizeof(stream));
    stream.next_in = (unsigned char *)source;
    stream.avail_in = (unsigned int)sourceLen;
    stream.next_out = (unsigned char *)dest;
    stream.avail_out = (unsigned int)*destLen;

    /* -MAX_WBITS (-15) tells zlib to expect raw deflate (no header/trailer) */
    ret = inflateInit2(&stream, -MAX_WBITS);
    if (ret != Z_OK)
        return ret;

    ret = inflate(&stream, Z_FINISH);
    *destLen = stream.total_out;
    inflateEnd(&stream);

    return (ret == Z_STREAM_END) ? Z_OK : (ret == Z_OK ? Z_BUF_ERROR : ret);
}

#else

int mz_inflate_raw(const void *source, unsigned long sourceLen,
                   void *dest, unsigned long *destLen) {
    (void)source; (void)sourceLen; (void)dest; (void)destLen;
    return -1; /* zlib not available */
}

#endif
