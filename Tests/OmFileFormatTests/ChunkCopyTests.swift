import Foundation
import Testing
@testable import OmFileFormat
import OmFileFormatC

/// Write one Float array through a temporary file and return the file bytes.
/// A file backend is used because `DataAsClass` as a writer crashes in release builds.
func writeFloatFile(dimensions: [UInt64], chunks: [UInt64], _ body: (OmFileWriterArray<Float, FileHandle>) throws -> Void) throws -> Data {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("chunk-copy-\(UUID()).om").path
    defer { try? FileManager.default.removeItem(atPath: file) }
    let fn = try FileHandle.createNewFile(file: file, overwrite: true)
    let fileWriter = OmFileWriter(fn: fn, initialCapacity: 8)
    let writer = try fileWriter.prepareArray(type: Float.self, dimensions: dimensions, chunkDimensions: chunks, compression: .pfor_delta2d_int16, scale_factor: 20, add_offset: 0)
    try body(writer)
    let variable = try fileWriter.write(array: try writer.finalise(), name: "data", children: [])
    try fileWriter.writeTrailer(rootVariable: variable)
    try fn.close()
    return try Data(contentsOf: URL(fileURLWithPath: file))
}

@Suite struct ChunkCopyTests {
    /// Dimensions [3, 45] in chunks of [1, 2] give 69 chunks, which crosses a 64 entry lookup table block.
    /// Row 0 is data, row 1 is NaN, row 2 alternates data and NaN chunks, with a one element chunk at the end.
    static func writeMixed() throws -> (file: Data, isNaN: [Bool]) {
        let file = try writeFloatFile(dimensions: [3, 45], chunks: [1, 2]) { writer in
            try writer.writeData(array: (0..<45).map { Float($0 % 7) }, arrayDimensions: [1, 45])
            try writer.writeNaN(arrayDimensions: [1, 45])
            for chunk in 0..<23 {
                let shape: [UInt64] = [1, chunk == 22 ? 1 : 2]
                if chunk % 2 == 0 {
                    try writer.writeData(array: [Float](repeating: Float(chunk), count: Int(shape[1])), arrayDimensions: shape)
                } else {
                    try writer.writeNaN(arrayDimensions: shape)
                }
            }
        }
        return (file, (0..<69).map { $0 / 23 == 1 || ($0 >= 46 && $0 % 2 == 1) })
    }

    @Test func chunkByteRangesOfMixedFile() async throws {
        let (file, isNaN) = try Self.writeMixed()
        // A small, the default and a large io size must give the same ranges
        let ioSizes: [(max: UInt64, merge: UInt64)] = [(64, 16), (65536, 512), (1 << 20, 1 << 16)]
        for io in ioSizes {
            let reader = try await OmFileReader(fn: DataAsClass(data: file)).asArray(of: Float.self, io_size_max: io.max, io_size_merge: io.merge)!
            let ranges = try await reader.chunkByteRanges()
            #expect(ranges.count == isNaN.count)
            var end = UInt64(om_header_write_size())
            var wrong = 0
            for (range, empty) in zip(ranges, isNaN) {
                if (range.count == 0) != empty || range.offset != end {
                    wrong += 1
                }
                end += range.count
            }
            #expect(wrong == 0)
            // The compressed lookup table follows the last chunk
            #expect(end < UInt64(file.count))
        }
    }
}
