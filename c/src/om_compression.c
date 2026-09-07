#include "om_compression.h"
#include "vp4.h"
#include "fp.h"
#include <string.h>

// Validate each block before entering TurboPFor's unchecked unpackers. In
// particular, widths select function pointers and exception positions index
// the output. Keep padding private: the unpackers use wide loads/stores even
// for short tails and constant blocks.
static bool take(size_t *pos, size_t size, size_t n) {
    if (*pos > size || n > size - *pos) return false;
    *pos += n;
    return true;
}

static bool block_size(const uint8_t *in, size_t size, unsigned n,
                       unsigned bits, size_t *length) {
    size_t p = 0;
    if (!take(&p, size, 1)) return false;
    unsigned header = in[0], b = header & 63;
    if ((header & 0xc0) == 0xc0 || !(header & 0xc0)) {
        if (bits == 64 && b == 63) b = 64;
        if (b > bits) return false;
        size_t bytes = (header & 0xc0) == 0xc0 ? (b + 7) / 8 : (n * b + 7) / 8;
        if (!take(&p, size, bytes)) return false;
    } else if (header & 0x80) {
        if (!take(&p, size, 1)) return false;
        unsigned bx = in[1];
        if (b >= bits || bx == 0 || bx > bits - b) return false;
        size_t bitmap = p;
        if (!take(&p, size, (n + 7) / 8)) return false;
        unsigned exceptions = 0;
        for (unsigned i = 0; i < n; ++i) exceptions += (in[bitmap + i / 8] >> (i % 8)) & 1;
        if ((n % 8) && (in[p - 1] >> (n % 8))) return false;
        if (!take(&p, size, (exceptions * bx + 7) / 8) ||
            !take(&p, size, (n * b + 7) / 8)) return false;
    } else {
        if (bits == 8 || b >= bits || !take(&p, size, 1)) return false;
        unsigned exceptions = in[1];
        if (exceptions == 0 || exceptions > n || !take(&p, size, (n * b + 7) / 8)) return false;
        // vbdec has a raw-array escape (255), otherwise uses TurboVByte.
        if (p == size) return false;
        if (in[p] == 255) {
            if (!take(&p, size, 1 + exceptions * (bits / 8))) return false;
        } else {
            for (unsigned i = 0; i < exceptions; ++i) {
                if (!take(&p, size, 1)) return false;
                unsigned h = in[p - 1];
                unsigned bytes = h < 177 ? 0 : h < 241 ? 1 : h < 249 ? 2 : 3 + h - 249;
                // The 16-bit decoder shares the 32-bit variable-byte reader.
                if (bytes > (bits == 64 ? 8u : 4u) || !take(&p, size, bytes)) return false;
            }
        }
        size_t positions = p;
        if (!take(&p, size, exceptions)) return false;
        for (unsigned i = 0; i < exceptions; ++i) if (in[positions + i] >= n) return false;
    }
    *length = p;
    return true;
}

static bool seed(const uint8_t *in, size_t size, unsigned bits, size_t *p, uint64_t *value) {
    if (!size) return false;
    unsigned h = in[0], bytes = 1;
    if (bits != 8) {
        for (unsigned mask = 128; mask && (h & mask); mask >>= 1) ++bytes;
        if (bits < 64 && bytes > 5) return false;
    }
    if (bytes > size) return false;
    uint64_t v = h;
    if (bytes == 2 || bytes == 4 || bytes == 8) {
        v = h & (255u >> bytes);
        for (unsigned i = 1; i < bytes; ++i) v = (v << 8) | in[i];
    } else if (bytes > 1) {
        v = 0;
        // Odd-length prefixes store the payload little endian; 7-byte
        // values store the high 16 bits before the low 32 bits.
        if (bytes == 7) {
            v = (uint64_t)(h & 1) << 48 | (uint64_t)in[1] << 32 | (uint64_t)in[2] << 40;
            for (unsigned i = 0; i < 4; ++i) v |= (uint64_t)in[3 + i] << (8 * i);
        } else if (bytes == 6) {
            v = (uint64_t)(((h & 3) << 8) | in[1]) << 32;
            for (unsigned i = 0; i < 4; ++i) v |= (uint64_t)in[2 + i] << (8 * i);
        } else {
            for (unsigned i = 1; i < bytes; ++i) v |= (uint64_t)in[i] << (8 * (i - 1));
            if (bytes < 9) v |= (uint64_t)(h & (255u >> bytes)) << (8 * (bytes - 1));
        }
    }
    if (bits < 64 && v >> bits) return false;
    *p = bytes;
    *value = v;
    return true;
}

// Largest block: 128 64-bit base values plus 128 variable-byte exceptions
// and their positions. Extra bytes cover the unpackers' wide tail loads.
#define BLOCK_CAPACITY 2432
#define PADDING 64
union block_output { uint8_t u8[192]; uint16_t u16[192]; uint32_t u32[192]; uint64_t u64[192]; };

size_t om_pfor_decode(const void *input, size_t size, size_t count, void *output, unsigned bits, bool zigzag) {
    if (bits != 8 && bits != 16 && bits != 32 && bits != 64) return SIZE_MAX;
    if (!count) return 0;
    const uint8_t *in = input;
    size_t pos;
    uint64_t start;
    if (!seed(in, size, bits, &pos, &start)) return SIZE_MAX;
    // memcpy from the matching integer type also supports unaligned output.
    #define STORE_SEED(B) case B: { uint##B##_t v = (uint##B##_t)start; memcpy(output, &v, sizeof(v)); break; }
    switch (bits) { STORE_SEED(8) STORE_SEED(16) STORE_SEED(32) STORE_SEED(64) }
    #undef STORE_SEED
    uint8_t *out = (uint8_t *)output + bits / 8;
    for (--count; count;) {
        unsigned n = count < 128 ? (unsigned)count : 128;
        size_t length;
        if (!block_size(in + pos, size - pos, n, bits, &length) || length > BLOCK_CAPACITY - PADDING) return SIZE_MAX;
        uint8_t padded[BLOCK_CAPACITY];
        unsigned char *block = (unsigned char *)in + pos;
        if (size - pos - length < PADDING) {
            memcpy(padded, block, length);
            memset(padded + length, 0, PADDING);
            block = padded;
        }
        union block_output decoded;
        unsigned char *end;
        #define DECODE(B, FULL) case B: \
            if (n == 128) end = zigzag ? p4zdec##FULL(block, n, decoded.u##B, (uint##B##_t)start) : p4ddec##FULL(block, n, decoded.u##B, (uint##B##_t)start); \
            else end = zigzag ? p4zdec##B(block, n, decoded.u##B, (uint##B##_t)start) : p4ddec##B(block, n, decoded.u##B, (uint##B##_t)start); \
            start = decoded.u##B[n - 1]; break;
        switch (bits) { DECODE(8, 8) DECODE(16, 128v16) DECODE(32, 128v32) DECODE(64, 64) default: return SIZE_MAX; }
        #undef DECODE
        if ((size_t)(end - block) != length) return SIZE_MAX;
        memcpy(out, &decoded, n * (bits / 8));
        out += n * (bits / 8);
        pos += length;
        count -= n;
    }
    return pos;
}

size_t om_fpx_decode(const void *input, size_t size, size_t count, void *output, unsigned bits) {
    if (bits != 32 && bits != 64) return SIZE_MAX;
    const uint8_t *in = input;
    uint8_t *out = output;
    size_t pos = 0;
    uint64_t start = 0;
    while (count) {
        if (pos == size) return SIZE_MAX;
        unsigned shift = in[pos++], n = count < 128 ? (unsigned)count : 128;
        size_t length;
        if (shift > bits || !block_size(in + pos, size - pos, n, bits, &length) || length >= BLOCK_CAPACITY - PADDING) return SIZE_MAX;
        // Include the FPX shift header when calling the optimized codec.
        uint8_t padded[BLOCK_CAPACITY];
        unsigned char *block = (unsigned char *)in + pos - 1;
        if (size - pos - length < PADDING) {
            memcpy(padded, block, length + 1);
            memset(padded + length + 1, 0, PADDING);
            block = padded;
        }
        union block_output decoded;
        if (shift == bits) {
            // Every XOR difference is zero. Avoid a scalar shift by the
            // type width, which is undefined in the original FPX tail path.
            for (unsigned i = 0; i < n; ++i) {
                if (bits == 32) decoded.u32[i] = (uint32_t)start;
                else decoded.u64[i] = start;
            }
        } else {
            size_t consumed;
            if (bits == 32) {
                consumed = fpxdec32(block, n, decoded.u32, (uint32_t)start);
                start = decoded.u32[n - 1];
            } else {
                consumed = fpxdec64(block, n, decoded.u64, start);
                start = decoded.u64[n - 1];
            }
            if (consumed != length + 1) return SIZE_MAX;
        }
        memcpy(out, &decoded, n * (bits / 8));
        out += n * (bits / 8);
        pos += length;
        count -= n;
    }
    return pos;
}
