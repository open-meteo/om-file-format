#include "om_compression.h"
#include "conf.h"
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

static ALWAYS_INLINE bool block_size(const uint8_t *in, size_t size, unsigned n,
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
// Dispatch once per stream. B and MODE are compile-time constants in each
// generated loop, including the bounds validator and the scratch-buffer type.
#define DEFINE_PFOR_DECODER(B, MODE, FULL) \
static size_t pfor_decode_##MODE##B(const uint8_t *in, size_t size, size_t count, void *output) { \
    if (!count) return 0; \
    size_t pos; \
    uint64_t initial; \
    if (!seed(in, size, B, &pos, &initial)) return SIZE_MAX; \
    uint##B##_t start = (uint##B##_t)initial; \
    memcpy(output, &start, sizeof(start)); \
    uint8_t *out = (uint8_t *)output + sizeof(start); \
    for (--count; count;) { \
        unsigned n = count < 128 ? (unsigned)count : 128; \
        size_t length; \
        if (!block_size(in + pos, size - pos, n, B, &length) || length > BLOCK_CAPACITY - PADDING) return SIZE_MAX; \
        uint8_t padded[BLOCK_CAPACITY]; \
        unsigned char *block = (unsigned char *)in + pos; \
        if (size - pos - length < PADDING) { \
            memcpy(padded, block, length); \
            memset(padded + length, 0, PADDING); \
            block = padded; \
        } \
        uint##B##_t decoded[192]; \
        unsigned char *end = n == 128 \
            ? p4##MODE##dec##FULL(block, n, decoded, start) \
            : p4##MODE##dec##B(block, n, decoded, start); \
        if ((size_t)(end - block) != length) return SIZE_MAX; \
        start = decoded[n - 1]; \
        memcpy(out, decoded, n * sizeof(start)); \
        out += n * sizeof(start); \
        pos += length; \
        count -= n; \
    } \
    return pos; \
}

DEFINE_PFOR_DECODER(8, d, 8)
DEFINE_PFOR_DECODER(8, z, 8)
DEFINE_PFOR_DECODER(16, d, 128v16)
DEFINE_PFOR_DECODER(16, z, 128v16)
DEFINE_PFOR_DECODER(32, d, 128v32)
DEFINE_PFOR_DECODER(32, z, 128v32)
DEFINE_PFOR_DECODER(64, d, 64)
DEFINE_PFOR_DECODER(64, z, 64)
#undef DEFINE_PFOR_DECODER

size_t om_pfor_decode(const void *input, size_t size, size_t count, void *output, unsigned bits, bool zigzag) {
    #define DISPATCH(B) case B: return zigzag \
        ? pfor_decode_z##B(input, size, count, output) \
        : pfor_decode_d##B(input, size, count, output);
    switch (bits) {
        DISPATCH(8)
        DISPATCH(16)
        DISPATCH(32)
        DISPATCH(64)
        default: return SIZE_MAX;
    }
    #undef DISPATCH
}

// Include the FPX shift header when calling the optimized codec. A shift of
// B means every XOR difference is zero; handle it without the original
// scalar tail's undefined shift by the type width.
#define DEFINE_FPX_DECODER(B) \
static size_t fpx_decode_##B(const uint8_t *in, size_t size, size_t count, void *output) { \
    uint8_t *out = output; \
    size_t pos = 0; \
    uint##B##_t start = 0; \
    while (count) { \
        if (pos == size) return SIZE_MAX; \
        unsigned shift = in[pos++], n = count < 128 ? (unsigned)count : 128; \
        size_t length; \
        if (shift > B || !block_size(in + pos, size - pos, n, B, &length) || length >= BLOCK_CAPACITY - PADDING) return SIZE_MAX; \
        uint8_t padded[BLOCK_CAPACITY]; \
        unsigned char *block = (unsigned char *)in + pos - 1; \
        if (size - pos - length < PADDING) { \
            memcpy(padded, block, length + 1); \
            memset(padded + length + 1, 0, PADDING); \
            block = padded; \
        } \
        uint##B##_t decoded[192]; \
        if (shift == B) { \
            for (unsigned i = 0; i < n; ++i) decoded[i] = start; \
        } else { \
            size_t consumed = fpxdec##B(block, n, decoded, start); \
            if (consumed != length + 1) return SIZE_MAX; \
            start = decoded[n - 1]; \
        } \
        memcpy(out, decoded, n * sizeof(start)); \
        out += n * sizeof(start); \
        pos += length; \
        count -= n; \
    } \
    return pos; \
}

DEFINE_FPX_DECODER(32)
DEFINE_FPX_DECODER(64)
#undef DEFINE_FPX_DECODER

size_t om_fpx_decode(const void *input, size_t size, size_t count, void *output, unsigned bits) {
    switch (bits) {
        case 32: return fpx_decode_32(input, size, count, output);
        case 64: return fpx_decode_64(input, size, count, output);
        default: return SIZE_MAX;
    }
}
