#ifndef OM_COMPRESSION_H
#define OM_COMPRESSION_H
#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

// Bounded OM codec entry points. Return SIZE_MAX on malformed/truncated input.
// Input and output need no padding. Successfully decoded prefixes may be written.
size_t om_pfor_decode(const void *input, size_t input_size, size_t count,
                      void *output, unsigned bits, bool zigzag);
size_t om_fpx_decode(const void *input, size_t input_size, size_t count,
                     void *output, unsigned bits);
#endif
