import Foundation
import Testing
@testable import OmFileFormat
import OmFileFormatC

/// Reads of a 3D file where NaN chunks sit first, last, in a long run and between data chunks.
@Suite struct NaNChunkReadTests {
    static let dimensions: [UInt64] = [20, 30, 8]
    static let chunks: [UInt64] = [1, 7, 8]
    static let chunkCount = 20 * 5

    static func isNaN(chunk: Int) -> Bool {
        chunk == 0 || chunk == 99 || (40..<55).contains(chunk) || chunk % 3 == 1
    }

    /// The file and the values a reader must return
    static func write() async throws -> (file: Data, expected: [Float]) {
        let total: UInt64 = dimensions.reduce(1, *)
        let values: [Float] = (0..<Int(total)).map { Float($0 % 1000) / 20 }
        var expected = values
        let file = try await writeFloatFile(dimensions: dimensions, chunks: chunks) { writer in
            for chunk in 0..<chunkCount {
                let region = chunkRegion(dimensions: dimensions, chunks: chunks, chunkIndex: chunk)
                if isNaN(chunk: chunk) {
                    try writer.writeNaN(arrayDimensions: region.count)
                    for column in region.offset[1]..<region.offset[1] + region.count[1] {
                        for k in 0..<8 {
                            expected[Int((region.offset[0] * 30 + column) * 8) + k] = .nan
                        }
                    }
                } else {
                    try writer.writeData(array: values, arrayDimensions: dimensions, arrayOffset: region.offset, arrayCount: region.count)
                }
            }
        }
        return (file, expected)
    }

    static let ranges: [[Range<UInt64>]] = [
        [0..<20, 0..<30, 0..<8],
        [5..<11, 10..<20, 0..<8],
        [0..<1, 0..<7, 0..<8], // only chunk 0, NaN
        [19..<20, 28..<30, 0..<8], // only chunk 99, NaN
        [8..<11, 0..<30, 2..<6], // NaN run 40..<55
        [0..<20, 26..<30, 0..<8], // last chunk of every row, so reads jump
        [3..<17, 5..<23, 1..<8],
    ]

    static let ioSizes: [(max: UInt64, merge: UInt64)] = [(65536, 512), (512, 64), (1 << 20, 1 << 16)]

    @Test func readFileWithNaNChunks() async throws {
        let (file, expected) = try await Self.write()
        let same: (Float, Float) -> Bool = { $0 == $1 || ($0.isNaN && $1.isNaN) }
        for io in Self.ioSizes {
            // SuspendingBackend refuses zero byte reads, like an HTTP range request
            let reader = try await OmFileReader(fn: SuspendingBackend(data: file)).asArray(of: Float.self, io_size_max: io.max, io_size_merge: io.merge)!
            let ranges = try await reader.chunkByteRanges()
            #expect((0..<Self.chunkCount).allSatisfy { (ranges[$0].count == 0) == Self.isNaN(chunk: $0) })
            for range in Self.ranges {
                let r3: InlineArray<3, Range<UInt64>> = [range[0], range[1], range[2]]
                let want = slice(expected, dimensions: Self.dimensions, range: range)
                #expect(try await reader.read(range: r3).elementsEqual(want, by: same))
                #expect(try await reader.readConcurrent(range: r3).elementsEqual(want, by: same))

                // Into a larger cube: the border must stay untouched
                let cube: [UInt64] = range.map { UInt64($0.count) + 2 }
                let cubeCount: UInt64 = cube.reduce(1, *)
                var into = [Float](repeating: -1, count: Int(cubeCount))
                try await reader.read(into: &into, range: r3, intoCubeOffset: [1, 1, 1], intoCubeDimension: [cube[0], cube[1], cube[2]])
                let inside = slice(into, dimensions: cube, range: [1..<cube[0] - 1, 1..<cube[1] - 1, 1..<cube[2] - 1])
                #expect(inside.elementsEqual(want, by: same))
                let untouched: Int = into.filter { $0 == -1 }.count
                #expect(untouched == into.count - want.count)
            }
        }
    }

    /// Values of a row-major array inside `range`
    func slice(_ array: [Float], dimensions: [UInt64], range: [Range<UInt64>]) -> [Float] {
        var out = [Float]()
        for i in range[0] {
            for j in range[1] {
                let start = Int((i * dimensions[1] + j) * dimensions[2] + range[2].lowerBound)
                out += array[start..<start + range[2].count]
            }
        }
        return out
    }
}
