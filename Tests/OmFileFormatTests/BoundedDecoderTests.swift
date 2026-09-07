import Testing
import Foundation
import OmFileFormatC

@Suite struct BoundedDecoderTests {
    private func encode(_ values: [UInt64], bits: Int, mode: Int) -> [UInt8] {
        var input = [UInt8]()
        for value in values {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { input.append(contentsOf: $0.prefix(bits / 8)) }
        }
        var compressed = [UInt8](repeating: 0, count: values.count * 16 + 4096)
        let length = input.withUnsafeMutableBytes { raw in
            compressed.withUnsafeMutableBufferPointer { out in
                let n = values.count
                switch (bits, mode) {
                case (8, 0): return p4ndenc8(raw.baseAddress!.assumingMemoryBound(to: UInt8.self), n, out.baseAddress)
                case (8, _): return p4nzenc8(raw.baseAddress!.assumingMemoryBound(to: UInt8.self), n, out.baseAddress)
                case (16, 0): return p4ndenc128v16(raw.baseAddress!.assumingMemoryBound(to: UInt16.self), n, out.baseAddress)
                case (16, _): return p4nzenc128v16(raw.baseAddress!.assumingMemoryBound(to: UInt16.self), n, out.baseAddress)
                case (32, 0): return p4ndenc128v32(raw.baseAddress!.assumingMemoryBound(to: UInt32.self), n, out.baseAddress)
                case (32, 1): return p4nzenc128v32(raw.baseAddress!.assumingMemoryBound(to: UInt32.self), n, out.baseAddress)
                case (32, _): return fpxenc32(raw.baseAddress!.assumingMemoryBound(to: UInt32.self), n, out.baseAddress, 0)
                case (64, 0): return p4ndenc64(raw.baseAddress!.assumingMemoryBound(to: UInt64.self), n, out.baseAddress)
                case (64, 1): return p4nzenc64(raw.baseAddress!.assumingMemoryBound(to: UInt64.self), n, out.baseAddress)
                default: return fpxenc64(raw.baseAddress!.assumingMemoryBound(to: UInt64.self), n, out.baseAddress, 0)
                }
            }
        }
        return Array(compressed.prefix(length))
    }

    private func decode(_ input: [UInt8], count: Int, bits: Int, mode: Int) -> (Int, [UInt8]) {
        // Allocate exactly the advertised input/output sizes, so ASan catches
        // any reliance on caller padding. A trailing output canary catches stores.
        let src = UnsafeMutableRawPointer.allocate(byteCount: max(input.count, 1), alignment: 8)
        defer { src.deallocate() }
        input.withUnsafeBytes { if !$0.isEmpty { src.copyMemory(from: $0.baseAddress!, byteCount: $0.count) } }
        let bytes = count * bits / 8
        var output = [UInt8](repeating: 0xa5, count: bytes + 16)
        let result = output.withUnsafeMutableBytes { out in
            mode == 2
                ? om_fpx_decode(src, input.count, count, out.baseAddress, UInt32(bits))
                : om_pfor_decode(src, input.count, count, out.baseAddress, UInt32(bits), mode == 1)
        }
        #expect(output.suffix(16).allSatisfy { $0 == 0xa5 })
        return (result, Array(output.prefix(bytes)))
    }

    @Test func roundTripsAndTruncation() {
        for bits in [8, 16, 32, 64] {
            let mask = UInt64.max >> (64 - bits)
            for mode in 0..<(bits >= 32 ? 3 : 2) {
                for count in [1, 2, 7, 127, 128, 129, 130, 257] {
                    for pattern in 0..<4 {
                        var state: UInt64 = 0xfedcba9876543210
                        let values = (0..<count).map { i -> UInt64 in
                            state = state &* 6364136223846793005 &+ 1
                            switch pattern {
                            case 0: return mask
                            case 1: return UInt64(i) & mask
                            case 2: return (i % 61 == 0 ? mask : UInt64(i % 3)) & mask
                            default: return state & mask
                            }
                        }
                        let input = encode(values, bits: bits, mode: mode)
                        let (length, output) = decode(input, count: count, bits: bits, mode: mode)
                        #expect(length == input.count)
                        let expected = values.flatMap { value -> [UInt8] in
                            var v = value.littleEndian
                            return withUnsafeBytes(of: &v) { Array($0.prefix(bits / 8)) }
                        }
                        #expect(output == expected)
                        for end in 0..<input.count {
                            #expect(decode(Array(input.prefix(end)), count: count, bits: bits, mode: mode).0 == -1)
                        }
                    }
                }
            }
        }
    }

    @Test func seedWidths() {
        for bits in [8, 16, 32, 64] {
            for shift in 0..<bits {
                let value = UInt64(1) << shift
                for v in [value - 1, value, value | (value - 1)] {
                    let input = encode([v], bits: bits, mode: 0)
                    let (length, output) = decode(input, count: 1, bits: bits, mode: 0)
                    #expect(length == input.count)
                    var expected = v.littleEndian
                    #expect(output == withUnsafeBytes(of: &expected) { Array($0.prefix(bits / 8)) })
                }
            }
        }
    }

    @Test func malformedBlocks() {
        let bad: [[UInt8]] = [
            [0, 17],                         // invalid 16-bit dispatch index
            [0, 0xc0 | 17, 0, 0, 0],         // invalid constant width
            [0, 0x80, 17, 0],                // invalid exception width
            [0, 0x80 | 16, 1, 0],            // invalid base/exception combination
            [0, 0x40, 1, 1, 2],              // position 2 outside a 2-value tail
            [0, 0x40, 3, 1, 1, 1, 0, 1, 2], // too many exceptions
            [0, 0x40, 1, 254],               // oversized variable byte prefix
            [0, 0x40, 1, 255, 1],            // truncated raw exceptions
            [0, 0x80, 1, 0x80, 0]            // bitmap sets a bit outside the tail
        ]
        for input in bad {
            #expect(decode(input, count: 3, bits: 16, mode: 1).0 == -1)
        }
        #expect(decode([33, 0], count: 1, bits: 32, mode: 2).0 == -1)
        // Exercise every dispatch header with enough bytes for valid encodings.
        for bits in [8, 16, 32, 64] {
            for header in 0...255 {
                for count in [3, 129] {
                    var input = [UInt8](repeating: 0, count: 2304)
                    input[1] = UInt8(header)
                    _ = decode(input, count: count, bits: bits, mode: 1)
                }
            }
        }
    }

    @Test func mutatedStreams() {
        var state: UInt64 = 0x123456789abcdef
        for bits in [8, 16, 32, 64] {
            for mode in 0..<(bits >= 32 ? 3 : 2) {
                let original = encode((0..<130).map { UInt64($0 % 7) }, bits: bits, mode: mode)
                for _ in 0..<1000 {
                    state = state &* 6364136223846793005 &+ 1
                    var input = original
                    input[Int(state % UInt64(input.count))] = UInt8(truncatingIfNeeded: state >> 32)
                    _ = decode(input, count: 130, bits: bits, mode: mode)
                }
            }
        }
    }

    @Test func corruptLookupTableReturnsError() {
        // First LUT block is valid; the next block has an invalid exception
        // width. This also exercises errors when crossing a LUT block boundary.
        let first = encode(Array(0..<UInt64(LUT_CHUNK_COUNT)), bits: 64, mode: 0)
        let width = max(first.count, 4)
        var input = first + [UInt8](repeating: 0, count: width - first.count)
        input += [0, 0x80, 65, 0] + [UInt8](repeating: 0, count: width - 4)
        var decoder = OmDecoder_t()
        decoder.number_of_chunks = UInt64(LUT_CHUNK_COUNT) + 1
        decoder.lut_chunk_length = UInt64(width)
        var read = OmDecoder_dataRead_t()
        read.nextChunk = OmRange_t(lowerBound: UInt64(LUT_CHUNK_COUNT) - 1, upperBound: UInt64(LUT_CHUNK_COUNT))
        var error = ERROR_OK
        #expect(!om_decoder_next_data_read(&decoder, &read, input, UInt64(input.count), &error))
        #expect(error == ERROR_DEFLATED_SIZE_MISMATCH)

        // Also reject a truncated first lookup block.
        decoder.lut_chunk_length = 1
        decoder.number_of_chunks = 1
        read = OmDecoder_dataRead_t()
        read.nextChunk = OmRange_t(lowerBound: 0, upperBound: 1)
        error = ERROR_OK
        #expect(!om_decoder_next_data_read(&decoder, &read, [UInt8(0)], 1, &error))
        #expect(error == ERROR_DEFLATED_SIZE_MISMATCH)
    }

    @Test func corruptChunkReturnsErrorBeforeCopying() {
        var dimension: UInt64 = 3
        var offset: UInt64 = 0
        withUnsafePointer(to: &dimension) { dims in
            withUnsafePointer(to: &offset) { offsets in
                var decoder = OmDecoder_t()
                decoder.dimensions_count = 1
                decoder.dimensions = dims
                decoder.chunks = dims
                decoder.read_count = dims
                decoder.read_offset = offsets
                decoder.data_type = UInt8(DATA_TYPE_FLOAT_ARRAY.rawValue)
                decoder.compression = UInt8(COMPRESSION_PFOR_DELTA2D_INT16.rawValue)
                decoder.bytes_per_element = 4
                decoder.bytes_per_element_compressed = 2
                var output = [Float](repeating: 42, count: 3)
                var scratch = [UInt16](repeating: 0, count: 3)
                var error = ERROR_OK
                let input: [UInt8] = [0, 17]
                #expect(!om_decoder_decode_chunks(&decoder, OmRange_t(lowerBound: 0, upperBound: 1), input, UInt64(input.count), &output, &scratch, &error))
                #expect(error == ERROR_DEFLATED_SIZE_MISMATCH)
                #expect(output == [42, 42, 42])
            }
        }
    }
}
