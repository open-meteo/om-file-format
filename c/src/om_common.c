//
//  om_common.c
//  OpenMeteoApi
//
//  Created by Patrick Zippenfenig on 30.10.2024.
//

#include "om_common.h"
#include <math.h>
#include "vp4.h"
#include "fp.h"
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic warning "-Wbad-function-cast"

const char* om_error_string(OmError_t error) {
    switch (error) {
        case ERROR_OK:
            return "No error occured";
        case ERROR_INVALID_COMPRESSION_TYPE:
            return "Invalid compression type";
        case ERROR_INVALID_DATA_TYPE:
            return "Invalid data type";
        case ERROR_OUT_OF_BOUND_READ:
            return "Corrupted data with potential out-of-bound read";
        case ERROR_NOT_AN_OM_FILE:
            return "Not an OM file";
        case ERROR_DEFLATED_SIZE_MISMATCH:
            return "Corrupted data: Deflated size does not match";
            break;
    }
    return "";
}

OmError_t om_get_element_size(OmDataType_t data_type, OmCompression_t compression, OmElementSize_t* size) {
    // Set element sizes based on data type
    switch (data_type) {
        case DATA_TYPE_INT8_ARRAY:
        case DATA_TYPE_UINT8_ARRAY:
            size->bytes_per_element = 1;
            size->bytes_per_element_compressed = 1;
            break;

        case DATA_TYPE_INT16_ARRAY:
        case DATA_TYPE_UINT16_ARRAY:
            size->bytes_per_element = 2;
            size->bytes_per_element_compressed = 2;
            break;

        case DATA_TYPE_INT32_ARRAY:
        case DATA_TYPE_UINT32_ARRAY:
        case DATA_TYPE_FLOAT_ARRAY:
            size->bytes_per_element = 4;
            size->bytes_per_element_compressed = 4;
            break;

        case DATA_TYPE_INT64_ARRAY:
        case DATA_TYPE_UINT64_ARRAY:
        case DATA_TYPE_DOUBLE_ARRAY:
            size->bytes_per_element = 8;
            size->bytes_per_element_compressed = 8;
            break;

        default:
            return ERROR_INVALID_DATA_TYPE;
    }

    // Adjust compressed size based on compression type
    switch (compression) {
        case COMPRESSION_PFOR_DELTA2D_INT16:
        case COMPRESSION_PFOR_DELTA2D_INT16_LOGARITHMIC:
            if (data_type != DATA_TYPE_FLOAT_ARRAY) {
                return ERROR_INVALID_DATA_TYPE;
            }
            size->bytes_per_element = 4;
            size->bytes_per_element_compressed = 2;
            break;

        case COMPRESSION_FPX_XOR2D:
        case COMPRESSION_PFOR_DELTA2D:
            break;

        default:
            return ERROR_INVALID_COMPRESSION_TYPE;
    }

    return ERROR_OK;
}

void om_common_copy_float_to_int16(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        float val = ((float *)src)[i];
        if (isnan(val)) {
            ((int16_t *)dst)[i] = INT16_MAX;
        } else {
            float scaled = val * scale_factor + add_offset;
            float clamped = fmaxf(INT16_MIN, fminf(INT16_MAX, roundf(scaled)));
            ((int16_t *)dst)[i] = (int16_t)clamped;
        }
    }
}

void om_common_copy_float_to_int32(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        float val = ((float *)src)[i];
        if (isnan(val)) {
            ((int32_t *)dst)[i] = INT32_MAX;
        } else {
            float scaled = val * scale_factor + add_offset;
            float clamped = fmaxf((float)INT32_MIN, fminf((float)INT32_MAX, roundf(scaled)));
            ((int32_t *)dst)[i] = (int32_t)clamped;
        }
    }
}

void om_common_copy_double_to_int64(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        double val = ((double *)src)[i];
        if (isnan(val)) {
            ((int64_t *)dst)[i] = INT64_MAX;
        } else {
            double scaled = val * (double)scale_factor + (double)add_offset;
            double clamped = fmax((double)INT64_MIN, fmin((double)INT64_MAX, round(scaled)));
            ((int64_t *)dst)[i] = (int64_t)clamped;
        }
    }
}

void om_common_copy_float_to_int16_log10(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        float val = ((float *)src)[i];
        if (isnan(val)) {
            ((int16_t *)dst)[i] = INT16_MAX;
        } else {
            float scaled = log10f(1 + val) * scale_factor;
            float clamped = fmaxf(INT16_MIN, fminf(INT16_MAX, roundf(scaled)));
            ((int16_t *)dst)[i] = (int16_t)clamped;
        }
    }
}

void om_common_copy_int16_to_float(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        int16_t val = ((int16_t *)src)[i];
        ((float *)dst)[i] = (val == INT16_MAX) ? NAN : (float)val / scale_factor - add_offset;
    }
}

void om_common_copy_int32_to_float(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        int32_t val = ((int32_t *)src)[i];
        ((float *)dst)[i] = (val == INT32_MAX) ? NAN : (float)val / scale_factor - add_offset;
    }
}

void om_common_copy_int64_to_double(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        int64_t val = ((int64_t *)src)[i];
        ((double *)dst)[i] = (val == INT64_MAX) ? NAN : (double)val / (double)scale_factor - (double)add_offset;
    }
}

void om_common_copy_int16_to_float_log10(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        int16_t val = ((int16_t *)src)[i];
        ((float *)dst)[i] = (val == INT16_MAX) ? NAN : powf(10, (float)val / scale_factor) - 1;
    }
}

void om_common_copy8(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        ((int8_t *)dst)[i] = ((int8_t *)src)[i];
    }
}

void om_common_copy16(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        ((int16_t *)dst)[i] = ((int16_t *)src)[i];
    }
}

void om_common_copy32(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        ((int32_t *)dst)[i] = ((int32_t *)src)[i];
    }
}

void om_common_copy64(uint64_t length, float scale_factor, float add_offset, const void* src, void* dst) {
    for (uint64_t i = 0; i < length; ++i) {
        ((int64_t *)dst)[i] = ((int64_t *)src)[i];
    }
}

uint64_t om_common_compress_fpxenc32(const void* src, uint64_t length, void* dst) {
    return fpxenc32((uint32_t*)src, length, (unsigned char *)dst, 0);
}

uint64_t om_common_compress_fpxenc64(const void* src, uint64_t length, void* dst) {
    return fpxenc64((uint64_t*)src, length, (unsigned char *)dst, 0);
}

uint64_t om_common_decompress_fpxdec32(const void* src, uint64_t length, void* dst) {
    return fpxdec32((unsigned char *)src, length, (uint32_t *)dst, 0);
}

uint64_t om_common_decompress_fpxdec64(const void* src, uint64_t length, void* dst) {
    return fpxdec64((unsigned char *)src, length, (uint64_t *)dst, 0);
}
