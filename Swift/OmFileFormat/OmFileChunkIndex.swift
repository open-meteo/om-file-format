/// Compressed chunk ranges backed by a decoded lookup table.
/// Equal adjacent entries represent an empty (all-NaN) chunk.
public struct OmFileChunkIndex: RandomAccessCollection, Sendable {
    /// One entry per chunk plus the final end offset.
    public let lut: [UInt64]
    /// Added to LUT entries to obtain file offsets. Nonzero for legacy files.
    public let dataOffset: UInt64

    init(lut: [UInt64], dataOffset: UInt64) {
        self.lut = lut
        self.dataOffset = dataOffset
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { lut.count - 1 }

    public subscript(position: Int) -> Range<UInt64> {
        precondition(position >= startIndex && position < endIndex)
        return (dataOffset + lut[position])..<(dataOffset + lut[position + 1])
    }
}
