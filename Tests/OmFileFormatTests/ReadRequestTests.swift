import Testing
import OmFileFormatC

@Suite struct ReadRequestTests {
    private struct Request: Equatable {
        let chunks: Range<UInt64>
        let offset: UInt64
        let count: UInt64

        init(_ chunks: Range<UInt64>, _ offset: UInt64, _ count: UInt64) {
            self.chunks = chunks
            self.offset = offset
            self.count = count
        }
    }

    /// Synthetic chunk lengths let the tests specify exact byte boundaries without
    /// depending on codec output. Optionally exercise the index reader as well.
    private func requests(
        lengths: [UInt64], dimensions: [UInt64]? = nil,
        offset: [UInt64]? = nil, count: [UInt64]? = nil,
        merge: UInt64 = 4096, maximum: UInt64 = 4096,
        readIndex: Bool = false
    ) -> (data: [Request], indexCount: Int) {
        let dimensions = dimensions ?? [UInt64(lengths.count)]
        let chunks = Array(repeating: UInt64(1), count: dimensions.count)
        let offset = offset ?? Array(repeating: UInt64(0), count: dimensions.count)
        let count = count ?? dimensions
        var lut: [UInt64] = [100]
        for length in lengths { lut.append(lut.last! + length) }
        let capacity = om_encoder_lut_buffer_size(lut, UInt64(lut.count))
        var compressed = [UInt8](repeating: 0, count: Int(capacity))
        let size = om_encoder_compress_lut(lut, UInt64(lut.count), &compressed, capacity)
        var result: [Request] = []
        var indexCount = 0
        dimensions.withUnsafeBufferPointer { dimensions in
            chunks.withUnsafeBufferPointer { chunks in
                offset.withUnsafeBufferPointer { offset in
                    count.withUnsafeBufferPointer { count in
                        var decoder = OmDecoder_t()
                        decoder.dimensions_count = UInt64(dimensions.count)
                        decoder.dimensions = dimensions.baseAddress
                        decoder.chunks = chunks.baseAddress
                        decoder.read_offset = offset.baseAddress
                        decoder.read_count = count.baseAddress
                        decoder.number_of_chunks = UInt64(lengths.count)
                        decoder.lut_chunk_length = size / ((UInt64(lut.count) + 63) / 64)
                        decoder.lut_start = 1000
                        decoder.io_size_max = maximum
                        decoder.io_size_merge = merge
                        var index = OmDecoder_indexRead_t()
                        om_decoder_init_index_read(&decoder, &index)
                        var error = ERROR_OK

                        func collect(_ index: OmDecoder_indexRead_t, bytes: [UInt8]) {
                            var index = index
                            var read = OmDecoder_dataRead_t()
                            om_decoder_init_data_read(&read, &index)
                            var iterations = 0
                            while om_decoder_next_data_read(&decoder, &read, bytes, UInt64(bytes.count), &error) {
                                iterations += 1
                                #expect(iterations <= lengths.count)
                                if iterations > lengths.count { break }
                                let range = read.chunkIndex.lowerBound..<read.chunkIndex.upperBound
                                #expect(!range.isEmpty)
                                #expect(range.upperBound <= UInt64(lengths.count))
                                #expect(read.offset == lut[Int(range.lowerBound)])
                                #expect(read.count == lut[Int(range.upperBound)] - read.offset)
                                #expect(read.count <= maximum || range.count == 1)
                                result.append(Request(range, read.offset, read.count))
                            }
                            #expect(error == ERROR_OK)
                        }

                        if readIndex {
                            while om_decoder_next_index_read(&decoder, &index) {
                                indexCount += 1
                                #expect(indexCount <= lengths.count)
                                if indexCount > lengths.count { break }
                                let start = Int(index.offset - decoder.lut_start)
                                let end = start + Int(index.count)
                                #expect(start >= 0 && end <= Int(size))
                                guard start >= 0 && end <= Int(size) else { break }
                                collect(index, bytes: Array(compressed[start..<end]))
                            }
                        } else {
                            index.chunkIndex = index.nextChunk
                            index.indexRange = OmRange_t(lowerBound: 0, upperBound: UInt64(lengths.count))
                            collect(index, bytes: Array(compressed.prefix(Int(size))))
                        }
                    }
                }
            }
        }
        return (result, indexCount)
    }

    @Test func maximumRequestSize() {
        for maximum: UInt64 in [19, 20, 21] {
            let actual = requests(lengths: [10, 10, 10, 10], maximum: maximum).data
            let expected: [Request] = maximum < 20
                ? [Request(0..<1, 100, 10), Request(1..<2, 110, 10), Request(2..<3, 120, 10), Request(3..<4, 130, 10)]
                : [Request(0..<2, 100, 20), Request(2..<4, 120, 20)]
            #expect(actual == expected)
        }
        // An oversized chunk must still be returned intact, and iteration resumes.
        #expect(requests(lengths: [5, 30, 5, 5], maximum: 10).data == [
            Request(0..<1, 100, 5), Request(1..<2, 105, 30), Request(2..<4, 135, 10)
        ])
    }

    @Test func mergeThresholdIncludesGapAndNextChunk() {
        // Selected chunks 0, 3, 6. Each merge adds a 5-byte gap plus 10 bytes.
        let lengths: [UInt64] = [10, 2, 3, 10, 2, 3, 10, 2, 3]
        for merge: UInt64 in [14, 15, 16] {
            let actual = requests(lengths: lengths, dimensions: [3, 3], count: [3, 1], merge: merge).data
            #expect(actual == (merge < 15
                ? [Request(0..<1, 100, 10), Request(3..<4, 115, 10), Request(6..<7, 130, 10)]
                : [Request(0..<7, 100, 40)]))
        }
        #expect(requests(lengths: lengths, dimensions: [3, 3], count: [3, 1], merge: 15, maximum: 25).data == [
            Request(0..<4, 100, 25), Request(6..<7, 130, 10)
        ])
        #expect(requests(lengths: [2, 2, 2], merge: 0).data == [
            Request(0..<1, 100, 2), Request(1..<2, 102, 2), Request(2..<3, 104, 2)
        ])
    }

    @Test func emptyChunkTransitions() {
        #expect(requests(lengths: [0, 0, 5, 5, 0, 0, 7, 0]).data == [
            Request(0..<2, 100, 0), Request(2..<4, 100, 10),
            Request(4..<6, 110, 0), Request(6..<7, 110, 7), Request(7..<8, 117, 0)
        ])
        #expect(requests(lengths: [0, 0, 0], merge: 0, maximum: 1).data == [Request(0..<3, 100, 0)])
        // Empty selected chunks cannot absorb nonempty skipped chunks.
        #expect(requests(lengths: [0, 5, 0, 5], dimensions: [2, 2], count: [2, 1]).data == [
            Request(0..<1, 100, 0), Request(2..<3, 105, 0)
        ])
    }

    @Test func mergeReadsAcrossSkippedChunks() {
        // Preserve coverage for short gaps and gaps spanning multiple LUT blocks,
        // with an empty chunk at either end of the gap or at the next selection.
        for width: UInt64 in [3, 130] {
            for emptyChunk in [nil, UInt64(1), width - 1, width] {
                var lengths = Array(repeating: UInt64(1), count: Int(2 * width))
                if let emptyChunk { lengths[Int(emptyChunk)] = 0 }
                let actual = requests(lengths: lengths, dimensions: [2, width], count: [2, 1]).data
                if let emptyChunk {
                    let nextOffset = 100 + width - (emptyChunk < width ? 1 : 0)
                    #expect(actual == [
                        Request(0..<1, 100, 1),
                        Request(width..<(width + 1), nextOffset, emptyChunk == width ? 0 : 1)
                    ])
                } else {
                    #expect(actual == [Request(0..<(width + 1), 100, width + 1)])
                }
            }
        }
    }

    @Test func skippedEmptyChunksAtLUTBoundaries() {
        for empty in [63, 64, 127, 128] {
            var lengths = Array(repeating: UInt64(1), count: 390)
            lengths[empty] = 0
            // Split at the first gap, then resume merging across the second gap.
            #expect(requests(lengths: lengths, dimensions: [3, 130], count: [3, 1]).data == [
                Request(0..<1, 100, 1), Request(130..<261, 229, 131)
            ])
        }
        #expect(requests(lengths: Array(repeating: 1, count: 130), maximum: 64).data == [
            Request(0..<64, 100, 64), Request(64..<128, 164, 64), Request(128..<130, 228, 2)
        ])
    }

    @Test func indexAndDataRequestIteration() {
        for maximum: UInt64 in [32, 128, 65536] {
            let result = requests(
                lengths: Array(repeating: 4, count: 6000),
                dimensions: [3, 2000], offset: [0, 65], count: [3, 70],
                merge: 65536, maximum: maximum, readIndex: true
            )
            // Every selected chunk occurs exactly once, including when a new
            // index request starts partway through a LUT block.
            let selected: [UInt64] = Array(65..<135) + Array(2065..<2135) + Array(4065..<4135)
            for chunk in selected {
                #expect(result.data.filter { $0.chunks.contains(chunk) }.count == 1)
            }
            if maximum == 65536 {
                #expect(result.indexCount == 1)
                #expect(result.data == [Request(65..<4135, 360, 16280)])
            } else {
                #expect(result.indexCount > 1)
                #expect(result.data.count > 1)
            }
        }
    }
}
