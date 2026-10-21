import Foundation
import Testing
@testable import OmFileFormat
import OmFileFormatC

/// Write one Float array through a temporary file and return the file bytes.
/// A file backend is used because `DataAsClass` as a writer crashes in release builds.
func writeFloatFile(dimensions: [UInt64], chunks: [UInt64], _ body: (OmFileWriterArray<Float, FileHandle>) async throws -> Void) async throws -> Data {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("chunk-copy-\(UUID()).om").path
    defer { try? FileManager.default.removeItem(atPath: file) }
    let fn = try FileHandle.createNewFile(file: file, overwrite: true)
    let fileWriter = OmFileWriter(fn: fn, initialCapacity: 8)
    let writer = try fileWriter.prepareArray(type: Float.self, dimensions: dimensions, chunkDimensions: chunks, compression: .pfor_delta2d_int16, scale_factor: 20, add_offset: 0)
    try await body(writer)
    let variable = try fileWriter.write(array: try writer.finalise(), name: "data", children: [])
    try fileWriter.writeTrailer(rootVariable: variable)
    try fn.close()
    return try Data(contentsOf: URL(fileURLWithPath: file))
}

/// Offset and element count of chunk `chunkIndex` in a row-major array. Chunks at the upper edges are smaller.
func chunkRegion(dimensions: [UInt64], chunks: [UInt64], chunkIndex: Int) -> (offset: [UInt64], count: [UInt64]) {
    var offset = dimensions
    var count = dimensions
    var rest = UInt64(chunkIndex)
    for i in dimensions.indices.reversed() {
        let grid = (dimensions[i] + chunks[i] - 1) / chunks[i]
        offset[i] = rest % grid * chunks[i]
        count[i] = min(chunks[i], dimensions[i] - offset[i])
        rest /= grid
    }
    return (offset, count)
}

/// Copy the chunks `keep` selects without decoding them and write the others as NaN.
/// Neighbouring kept chunks are fetched with one read, as a caller reading over a network would.
func copyChunks<Backend: OmFileReaderBackend>(from reader: OmFileReaderArray<Backend, Float>, into writer: OmFileWriterArray<Float, FileHandle>, keep: (Int) -> Bool) async throws {
    let ranges = try await reader.chunkIndex()
    let layout = try reader.chunkLayout()
    func kept(_ chunk: Int) -> Bool { keep(chunk) && ranges[chunk].count > 0 }
    var first = 0
    while first < ranges.count {
        guard kept(first) else {
            try writer.writeNaN(arrayDimensions: layout[first].shape)
            first += 1
            continue
        }
        var end = first + 1
        while end < ranges.count && kept(end) {
            end += 1
        }
        let start = ranges[first].lowerBound
        let bytes = try await reader.fn.getData(offset: Int(start), count: Int(ranges[end - 1].upperBound - start))
        try bytes.withUnsafeBytes { bytes in
            for chunk in first..<end {
                let lower = Int(ranges[chunk].lowerBound - start)
                try writer.writeCompressedChunk(UnsafeRawBufferPointer(rebasing: bytes[lower..<lower + Int(ranges[chunk].count)]))
            }
        }
        first = end
    }
}

@Suite struct ChunkCopyTests {
    /// Dimensions [3, 45] in chunks of [1, 2] give 69 chunks, which crosses a 64 entry lookup table block.
    /// Row 0 is data, row 1 is NaN, row 2 alternates data and NaN chunks, with a one element chunk at the end.
    static func writeMixed() async throws -> (file: Data, isNaN: [Bool]) {
        let file = try await writeFloatFile(dimensions: [3, 45], chunks: [1, 2]) { writer in
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

    @Test func chunkIndexOfMixedFile() async throws {
        let (file, isNaN) = try await Self.writeMixed()
        // A small, the default and a large io size must give the same ranges
        let ioSizes: [(max: UInt64, merge: UInt64)] = [(1, 0), (64, 16), (65536, 512), (1 << 20, 1 << 16)]
        for io in ioSizes {
            let backend = LUTRecordingBackend(data: file)
            let reader = try await OmFileReader(fn: backend).asArray(of: Float.self, io_size_max: io.max, io_size_merge: io.merge)!
            let before = await backend.reads.count
            let layout = try reader.chunkLayout()
            #expect(await backend.reads.count == before)
            let ranges = try await reader.chunkIndex()
            let reads = await backend.reads
            #expect(reads.count == before + 1)
            #expect(ranges.lut.count == isNaN.count + 1)
            #expect(ranges.dataOffset == 0)
            #expect(Array(ranges.reversed()) == Array(ranges).reversed())
            #expect(ranges.count == isNaN.count)
            #expect(layout.count == ranges.count)
            for (index, pair) in zip(ranges, layout).enumerated() {
                let expected = chunkRegion(dimensions: [3, 45], chunks: [1, 2], chunkIndex: index)
                #expect(pair.0 == ranges[index])
                #expect(pair.1.shape == expected.count)
                #expect(pair.1.offset == expected.offset)
            }
            var end = UInt64(om_header_write_size())
            var wrong = 0
            for (range, empty) in zip(ranges, isNaN) {
                if (range.count == 0) != empty || range.lowerBound != end {
                    wrong += 1
                }
                end = range.upperBound
            }
            #expect(wrong == 0)
            // The compressed lookup table follows the last chunk
            #expect(end < UInt64(file.count))
            #expect(reads.last?.lowerBound == Int(end))
        }
    }

    @Test func copyChunksOfMixedFile() async throws {
        let (file, isNaN) = try await Self.writeMixed()
        let source = try await OmFileReader(fn: DataAsClass(data: file)).asArray(of: Float.self)!
        let values = try await source.read()
        // Drop every third chunk, which also breaks up runs of kept chunks
        let keep: (Int) -> Bool = { $0 % 3 != 0 }
        let copy = try await writeFloatFile(dimensions: [3, 45], chunks: [1, 2]) { writer in
            try await copyChunks(from: source, into: writer, keep: keep)
        }
        let result = try await OmFileReader(fn: DataAsClass(data: copy)).asArray(of: Float.self)!
        let copied = try await result.read()
        for chunk in 0..<isNaN.count {
            let region = chunkRegion(dimensions: [3, 45], chunks: [1, 2], chunkIndex: chunk)
            for column in region.offset[1]..<region.offset[1] + region.count[1] {
                let i = Int(region.offset[0] * 45 + column)
                if keep(chunk) {
                    #expect(copied[i].isNaN ? values[i].isNaN : copied[i] == values[i])
                } else {
                    #expect(copied[i].isNaN)
                }
            }
        }
        // Copying again keeps the bytes of a kept chunk as they are
        let ranges = try await source.chunkIndex()
        let copyRanges = try await result.chunkIndex()
        for chunk in 0..<ranges.count {
            #expect(copyRanges[chunk].count == (keep(chunk) ? ranges[chunk].count : 0))
        }
    }

    @Test func writeCompressedChunkRefusesWrongCalls() async throws {
        _ = try await writeFloatFile(dimensions: [1, 4], chunks: [1, 2]) { writer in
            #expect(throws: OmFileFormatSwiftError.self) { try writer.writeCompressedChunk(UnsafeRawBufferPointer(start: nil, count: 0)) }
            try writer.writeData(array: [1, 2, 3, 4], arrayDimensions: [1, 4])
            // Both chunks are written
            let byte: [UInt8] = [0]
            #expect(throws: OmFileFormatSwiftError.self) { try byte.withUnsafeBytes { try writer.writeCompressedChunk($0) } }
        }
    }

    /// A legacy file stores flat dimensions [ny * nx, t], an uncompressed lookup table of chunk end offsets after a 40 byte header, and the chunks after that.
    @Test func copyChunksOfLegacyFile() async throws {
        let dimensions: [UInt64] = [30, 11]
        let chunks: [UInt64] = [4, 3]
        let nChunks = 8 * 4
        let values: [Float] = (0..<330).map { Float($0 % 97) / 20 }
        // Chunks compressed by the current writer have the legacy encoding for this compression
        let modern = try await writeFloatFile(dimensions: dimensions, chunks: chunks) { writer in
            for chunk in 0..<nChunks {
                let region = chunkRegion(dimensions: dimensions, chunks: chunks, chunkIndex: chunk)
                // The elements of this chunk alone: the encoder cannot read a region that ends at the last column of a wider array
                var dense: [Float] = []
                for row in region.offset[0]..<region.offset[0] + region.count[0] {
                    let start = Int(row * 11 + region.offset[1])
                    let end = start + Int(region.count[1])
                    dense.append(contentsOf: values[start..<end])
                }
                try writer.writeData(array: dense, arrayDimensions: region.count)
            }
        }
        let modernReader = try await OmFileReader(fn: DataAsClass(data: modern)).asArray(of: Float.self)!
        let modernRanges = try await modernReader.chunkIndex()
        var legacy = Data([79, 77, 2, 0])
        withUnsafeBytes(of: Float(20)) { legacy += $0 }
        var header: [UInt64] = dimensions
        header.append(contentsOf: chunks)
        let firstOffset: UInt64 = modernRanges[0].lowerBound
        for range in modernRanges {
            header.append(range.upperBound - firstOffset)
        }
        for value in header {
            withUnsafeBytes(of: value.littleEndian) { legacy += $0 }
        }
        legacy += modern[Int(modernRanges[0].lowerBound)..<Int(modernRanges[nChunks - 1].upperBound)]

        let backend = LUTRecordingBackend(data: legacy)
        let source = try await OmFileReader(fn: backend)
        #expect(try await source.isLegacyFormat())
        let legacyReader = source.asArray(of: Float.self, io_size_max: 256, io_size_merge: 16)!
        let before = await backend.reads.count
        let legacyRanges = try await legacyReader.chunkIndex()
        let reads = await backend.reads
        #expect(reads.count == before + 1)
        #expect(reads.last == 40..<(40 + 8 * nChunks))
        #expect(legacyRanges.lut.count == nChunks + 1)
        #expect(legacyRanges.lut.first == 0)
        #expect(legacyRanges.dataOffset == UInt64(40 + 8 * nChunks))
        #expect(legacyRanges.count == nChunks)
        let legacyLayout = try legacyReader.chunkLayout()
        #expect(legacyLayout.count == legacyRanges.count)
        for (index, pair) in zip(legacyRanges, legacyLayout).enumerated() {
            let (byteRange, chunk) = pair
            let expected = chunkRegion(dimensions: dimensions, chunks: chunks, chunkIndex: index)
            #expect(chunk.offset == expected.offset)
            #expect(chunk.shape == expected.count)
            #expect(byteRange == legacyRanges[index])
        }
        // Offsets are absolute in the legacy file, which has a different header and lookup table
        let headerAndLut = UInt64(40 + 8 * nChunks)
        for (legacyRange, modernRange) in zip(legacyRanges, modernRanges) {
            #expect(legacyRange.lowerBound == modernRange.lowerBound - firstOffset + headerAndLut)
            #expect(legacyRange.count == modernRange.count)
        }

        // Into a version 3 array of the same dimensions, dropping chunks 2 to 4 and 20
        let keep: (Int) -> Bool = { !(2...4).contains($0) && $0 != 20 }
        let copy = try await writeFloatFile(dimensions: dimensions, chunks: chunks) { writer in
            try await copyChunks(from: legacyReader, into: writer, keep: keep)
        }
        var expected = values
        for chunk in 0..<nChunks where !keep(chunk) {
            let region = chunkRegion(dimensions: dimensions, chunks: chunks, chunkIndex: chunk)
            for row in region.offset[0]..<region.offset[0] + region.count[0] {
                for column in region.offset[1]..<region.offset[1] + region.count[1] {
                    expected[Int(row * 11 + column)] = .nan
                }
            }
        }
        let result = try await OmFileReader(fn: DataAsClass(data: copy)).asArray(of: Float.self)!
        #expect(try await result.read().elementsEqual(expected, by: { $0 == $1 || ($0.isNaN && $1.isNaN) }))
    }
}


/// Records backend reads so LUT enumeration must use exactly one request.
private actor LUTRecordingBackend: OmFileReaderBackend {
    let data: Data
    var reads: [Range<Int>] = []

    init(data: Data) { self.data = data }
    nonisolated var count: Int { data.count }

    func getData(offset: Int, count: Int) async throws -> Data {
        reads.append(offset..<(offset + count))
        return data.subdata(in: offset..<(offset + count))
    }

    nonisolated func withData<T>(offset: Int, count: Int, fn: @Sendable (UnsafeRawBufferPointer) throws -> T) async throws -> T {
        try await getData(offset: offset, count: count).withUnsafeBytes(fn)
    }

    func prefetchData(offset: Int, count: Int) async throws {}
}
