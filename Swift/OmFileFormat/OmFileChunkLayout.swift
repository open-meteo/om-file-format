/// Chunk shapes and starting element coordinates in row-major chunk order.
/// Matches the order of OmFileChunkIndex, including empty chunks.
/// Stores only array layout metadata; each element is computed on access.
public struct OmFileChunkLayout: RandomAccessCollection, Sendable {
    public let dimensions: [UInt64]
    public let chunkDimensions: [UInt64]

    public var startIndex: Int { 0 }
    public let endIndex: Int

    init(dimensions: [UInt64], chunkDimensions: [UInt64]) throws {
        guard !dimensions.isEmpty, dimensions.count == chunkDimensions.count,
              zip(dimensions, chunkDimensions).allSatisfy({ $0 > 0 && $1 > 0 && $1 <= $0 }) else {
            throw OmFileFormatSwiftError.omDecoder(error: "Invalid chunk dimensions")
        }
        var count: UInt64 = 1
        for (dimension, chunk) in zip(dimensions, chunkDimensions) {
            let length = (dimension - 1) / chunk + 1
            guard length <= UInt64(Int.max) / count else {
                throw OmFileFormatSwiftError.omDecoder(error: "Chunk count is out of bounds")
            }
            count *= length
        }
        self.dimensions = dimensions
        self.chunkDimensions = chunkDimensions
        self.endIndex = Int(count)
    }

    /// Actual shape clipped at array edges, and starting coordinates within the array.
    public subscript(position: Int) -> Chunk {
        precondition(position >= startIndex && position < endIndex)
        var shape = dimensions
        var offset = dimensions
        var remainder = UInt64(position)
        for d in dimensions.indices.reversed() {
            let chunksInDimension = (dimensions[d] - 1) / chunkDimensions[d] + 1
            offset[d] = (remainder % chunksInDimension) * chunkDimensions[d]
            shape[d] = Swift.min(chunkDimensions[d], dimensions[d] - offset[d])
            remainder /= chunksInDimension
        }
        return Chunk(shape: shape, offset: offset, arrayDimensions: dimensions)
    }

    /// A chunk's actual shape and starting element coordinates in the full array.
    public struct Chunk: Sendable {
        /// Actual chunk dimensions, clipped at the edges of the array.
        public let shape: [UInt64]
        /// Starting element coordinates within the full array.
        public let offset: [UInt64]
        /// Dimensions of the full array containing this chunk.
        public let arrayDimensions: [UInt64]

        /// Element coordinates covered by this chunk along one array dimension.
        public func range(in dimension: Int) -> Range<UInt64> {
            precondition(arrayDimensions.indices.contains(dimension))
            return offset[dimension]..<(offset[dimension] + shape[dimension])
        }
    }
}
