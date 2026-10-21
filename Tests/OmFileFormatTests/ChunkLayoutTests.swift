import Testing
@testable import OmFileFormat

@Suite struct ChunkLayoutTests {
    @Test func shapesAndOffsets() throws {
        let cases: [(dimensions: [UInt64], chunks: [UInt64])] = [
            ([5], [2]), ([4, 6], [2, 3]), ([3, 5], [2, 3]),
            ([3, 5, 7], [2, 3, 4]), ([2, 3, 4], [2, 3, 4])
        ]
        for (dimensions, chunks) in cases {
            // Construct expected coordinates independently in row-major order.
            var starts: [[UInt64]] = [[]]
            for d in dimensions.indices {
                starts = starts.flatMap { prefix in
                    stride(from: UInt64(0), to: dimensions[d], by: Int(chunks[d])).map { prefix + [$0] }
                }
            }
            var lut: [UInt64] = [10]
            for i in starts.indices { lut.append(lut.last! + (i % 3 == 0 ? 0 : 7)) }
            let ranges = OmFileChunkIndex(lut: lut, dataOffset: 100)
            let layout = try OmFileChunkLayout(dimensions: dimensions, chunkDimensions: chunks)
            #expect(layout.count == ranges.count)
            #expect(ranges.count == starts.count)
            var total: UInt64 = 0
            for (i, pair) in zip(ranges, layout).enumerated() {
                let (byteRange, chunk) = pair
                let shape = dimensions.indices.map { min(chunks[$0], dimensions[$0] - starts[i][$0]) }
                #expect(chunk.offset == starts[i])
                #expect(chunk.shape == shape)
                #expect(chunk.arrayDimensions == dimensions)
                for d in dimensions.indices {
                    #expect(chunk.range(in: d) == starts[i][d]..<(starts[i][d] + shape[d]))
                }
                #expect(byteRange == (100 + lut[i])..<(100 + lut[i + 1]))
                #expect(byteRange.isEmpty == (i % 3 == 0))
                total += chunk.shape.reduce(1, *)
            }
            #expect(total == dimensions.reduce(1, *))
            #expect(layout.reversed().map(\.offset) == Array(starts.reversed()))
            if starts.count > 1 {
                let slice = layout[1..<layout.endIndex]
                #expect(slice.startIndex == 1)
                #expect(slice.first?.offset == starts[1])
            }
        }
    }

    @Test func invalidLayoutDimensions() {
        let cases: [(dimensions: [UInt64], chunks: [UInt64])] = [
            ([], []), ([2], []), ([0], [1]), ([2], [0]), ([2], [3]),
            ([UInt64(Int.max), 2], [1, 1])
        ]
        for (dimensions, chunks) in cases {
            #expect(throws: OmFileFormatSwiftError.self) {
                try OmFileChunkLayout(dimensions: dimensions, chunkDimensions: chunks)
            }
        }
    }

    @Test func flatSpatialRange() throws {
        let chunk = try OmFileChunkLayout(dimensions: [15, 4], chunkDimensions: [7, 2])[4]
        #expect(chunk.range(in: 0) == 14..<15)
        #expect(chunk.range(in: 0).contains { Int($0) == 14 })
    }

    @Test func chunkMetadataOutlivesCollection() throws {
        let chunk = try OmFileChunkLayout(dimensions: [5], chunkDimensions: [3])[1]
        #expect(chunk.offset == [3])
        #expect(chunk.shape == [2])
    }
}
