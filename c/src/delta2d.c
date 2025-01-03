#include "delta2d.h"

void delta2d_decode8(const size_t length0, const size_t length1, int8_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = 1; d0 < length0; d0++) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] += chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_encode8(const size_t length0, const size_t length1, int8_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = length0-1; d0 >= 1; d0--) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] -= chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_decode16(const size_t length0, const size_t length1, int16_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = 1; d0 < length0; d0++) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] += chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_encode16(const size_t length0, const size_t length1, int16_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = length0-1; d0 >= 1; d0--) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] -= chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_decode32(const size_t length0, const size_t length1, int32_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = 1; d0 < length0; d0++) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] += chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_encode32(const size_t length0, const size_t length1, int32_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = length0-1; d0 >= 1; d0--) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] -= chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_decode64(const size_t length0, const size_t length1, int64_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = 1; d0 < length0; d0++) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] += chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_encode64(const size_t length0, const size_t length1, int64_t* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    for (size_t d0 = length0-1; d0 >= 1; d0--) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBuffer[d0*length1 + d1] -= chunkBuffer[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_decode_xor(const size_t length0, const size_t length1, float* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    int* chunkBufferInt = (int*)chunkBuffer;
    for (size_t d0 = 1; d0 < length0; d0++) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBufferInt[d0*length1 + d1] ^= chunkBufferInt[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_encode_xor(const size_t length0, const size_t length1, float* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    int* chunkBufferInt = (int*)chunkBuffer;
    for (size_t d0 = length0-1; d0 >= 1; d0--) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBufferInt[d0*length1 + d1] ^= chunkBufferInt[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_decode_xor_double(const size_t length0, const size_t length1, double* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    int* chunkBufferInt = (int*)chunkBuffer;
    for (size_t d0 = 1; d0 < length0; d0++) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBufferInt[d0*length1 + d1] ^= chunkBufferInt[(d0-1)*length1 + d1];
        }
    }
}

void delta2d_encode_xor_double(const size_t length0, const size_t length1, double* chunkBuffer) {
    if (length0 <= 1) {
        return;
    }
    int* chunkBufferInt = (int*)chunkBuffer;
    for (size_t d0 = length0-1; d0 >= 1; d0--) {
        for (size_t d1 = 0; d1 < length1; d1++) {
            chunkBufferInt[d0*length1 + d1] ^= chunkBufferInt[(d0-1)*length1 + d1];
        }
    }
}
