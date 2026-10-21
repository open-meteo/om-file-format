import Testing
import OmFileFormatC

@Suite struct FullLUTTests {
    private func metadata(n: UInt64, legacy: Bool, lutSize: UInt64) -> [UInt8] {
        if legacy {
            var bytes: [UInt8] = [79, 77, 2, 0]
            withUnsafeBytes(of: Float(1)) { bytes.append(contentsOf: $0) }
            for value: UInt64 in [1, n, 1, 1] {
                withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
            }
            return bytes
        }
        var bytes = [UInt8](repeating: 0, count: om_variable_write_numeric_array_size(0, 0, 2))
        om_variable_write_numeric_array(
            &bytes, 0, 0, nil, nil, nil, DATA_TYPE_FLOAT_ARRAY, COMPRESSION_PFOR_DELTA2D_INT16,
            1, 0, 2, [1, n], [1, 1], lutSize, 1000
        )
        return bytes
    }

    @Test func decodeFullLUT() {
        for n in [1, 63, 64, 65, 129] {
            for legacy in [false, true] {
                // Repeated offsets include empty chunks at LUT block boundaries.
                let expected = (0...n).map { UInt64($0 / 3) + (legacy ? 0 : 100) }
                var input: [UInt8]
                if legacy {
                    input = expected.dropFirst().flatMap { value in
                        withUnsafeBytes(of: value.littleEndian) { Array($0) }
                    }
                } else {
                    let capacity = om_encoder_lut_buffer_size(expected, UInt64(expected.count))
                    input = Array(repeating: 0, count: Int(capacity))
                    let size = om_encoder_compress_lut(expected, UInt64(expected.count), &input, capacity)
                    input = Array(input.prefix(Int(size)))
                }
                metadata(n: UInt64(n), legacy: legacy, lutSize: UInt64(input.count)).withUnsafeBytes {
                    let variable = om_variable_init($0.baseAddress)
                    var offset: UInt64 = 0
                    var size: UInt64 = 0
                    var dataOffset: UInt64 = 0
                    var entryCount: UInt64 = 0
                    #expect(om_variable_chunk_index_read(variable, &offset, &size, &dataOffset, &entryCount) == ERROR_OK)
                    #expect(entryCount == UInt64(n + 1))
                    #expect(offset == (legacy ? 40 : 1000))
                    #expect(size == UInt64(input.count))
                    #expect(dataOffset == (legacy ? UInt64(40 + 8 * n) : 0))
                    var output = Array(repeating: UInt64.max, count: Int(entryCount))
                    #expect(om_variable_decode_chunk_index(variable, input, size, &output, entryCount) == ERROR_OK)
                    #expect(output == expected)
                    #expect(om_variable_decode_chunk_index(variable, input, size - 1, &output, entryCount) == ERROR_OUT_OF_BOUND_READ)
                    #expect(om_variable_decode_chunk_index(variable, input, size, &output, UInt64(n)) == ERROR_OUT_OF_BOUND_READ)
                }
            }
        }
    }

    @Test func rejectInvalidOffsets() {
        metadata(n: 2, legacy: true, lutSize: 16).withUnsafeBytes {
            let variable = om_variable_init($0.baseAddress)
            var output = [UInt64](repeating: 0, count: 3)
            for offsets: [UInt64] in [[10, 9], [10, UInt64.max]] {
                let input = offsets.flatMap { value in
                    withUnsafeBytes(of: value.littleEndian) { Array($0) }
                }
                #expect(om_variable_decode_chunk_index(variable, input, 16, &output, 3) == ERROR_DEFLATED_SIZE_MISMATCH)
            }
        }
    }

    @Test func rejectInvalidMetadata() {
        for legacy in [false, true] {
            for n: UInt64 in [0, UInt64.max] {
                metadata(n: n, legacy: legacy, lutSize: 16).withUnsafeBytes {
                    var offset: UInt64 = 0
                    var size: UInt64 = 0
                    var dataOffset: UInt64 = 0
                    var entryCount: UInt64 = 0
                    #expect(om_variable_chunk_index_read(om_variable_init($0.baseAddress), &offset, &size, &dataOffset, &entryCount) == ERROR_INVALID_DIMENSIONS)
                }
            }
        }
        // Two LUT blocks must have equal nonzero lengths.
        for lutSize: UInt64 in [0, 3] {
            metadata(n: 64, legacy: false, lutSize: lutSize).withUnsafeBytes {
                var offset: UInt64 = 0
                var size: UInt64 = 0
                var dataOffset: UInt64 = 0
                var entryCount: UInt64 = 0
                #expect(om_variable_chunk_index_read(om_variable_init($0.baseAddress), &offset, &size, &dataOffset, &entryCount) == ERROR_DEFLATED_SIZE_MISMATCH)
            }
        }
    }
}
