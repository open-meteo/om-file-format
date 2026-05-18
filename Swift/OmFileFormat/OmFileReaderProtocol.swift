import Foundation


/// OmFileReader can read data from this backend
public protocol OmFileReaderBackend: Sendable {
    /// The return data can be a directly a pointer or a `Data` class that retains data.
    associatedtype DataType: ContiguousBytes & Sendable
    
    // Length in bytes
    var count: Int { get }

    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int) async throws
    
    /// Read data. Data will be retained of type `DataType`. Reads must be thread safe.
    func getData(offset: Int, count: Int) async throws -> DataType
    
    /// Read data. Data is only temporarily read inside the callback without async
    func withData<T>(offset: Int, count: Int, fn: @Sendable (UnsafeRawBufferPointer) throws -> T) async throws -> T
}

extension OmFileReaderBackend {
    func getDataChecked(offset: Int, count: Int) async throws -> DataType {
        guard offset + count <= self.count else {
            throw OmFileFormatSwiftError.omDecoder(error: "Read out of bounds")
        }
        return try await self.getData(offset: offset, count: count)
    }
    
    func withDataChecked<T>(offset: Int, count: Int, fn: @Sendable (UnsafeRawBufferPointer) throws -> T) async throws -> T {
        guard offset + count <= self.count else {
            throw OmFileFormatSwiftError.omDecoder(error: "Read out of bounds")
        }
        return try await self.withData(offset: offset, count: count, fn: fn)
    }
}

/// Protocol for `OmFileReaderArray` to type erase the underlaying backend implementation
public protocol OmFileReaderArrayProtocol<OmType>: Sendable {
    associatedtype OmType: OmFileArrayDataTypeProtocol
    
    var compression: OmCompressionType { get }
    var scaleFactor: Float { get }
    var addOffset: Float { get }
    
    func withDimensions<R>(_ body: (_: UnsafeBufferPointer<UInt64>) -> R) -> R
    func withChunkDimensions<R>(_ body: (_: UnsafeBufferPointer<UInt64>) -> R) -> R
    func getDimensionsCount() -> UInt64
    func getDimensions() -> [UInt64]
    func getChunkDimensions() -> [UInt64]
    func getDimensionsInline<let nDimensions: Int>() -> InlineArray<nDimensions, UInt64>
    func getChunkDimensionsInline<let nDimensions: Int>() -> InlineArray<nDimensions, UInt64>
    
    func willNeed<let nDimensions: Int>(range: InlineArray<nDimensions, Range<UInt64>>) async throws
    func willNeed<let nDimensions: Int>(offset: InlineArray<nDimensions, UInt64>, count: InlineArray<nDimensions, UInt64>) async throws
    
    func read() async throws -> [OmType]
    func read<let nDimensions: Int>(offset: InlineArray<nDimensions, UInt64>, count: InlineArray<nDimensions, UInt64>) async throws -> [OmType]
    func read<let nDimensions: Int>(range: InlineArray<nDimensions, Range<UInt64>>) async throws -> [OmType]
    func read<let nDimensions: Int>(into: UnsafeMutablePointer<OmType>, range: InlineArray<nDimensions, Range<UInt64>>, intoCubeOffset: InlineArray<nDimensions, UInt64>?, intoCubeDimension: InlineArray<nDimensions, UInt64>?) async throws
    //func read(into: UnsafeMutablePointer<OmType>, offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, intoCubeOffset: UnsafePointer<UInt64>, intoCubeDimension: UnsafePointer<UInt64>, nDimensions: Int) async throws
    
    func readConcurrent<let nDimensions: Int>(offset: InlineArray<nDimensions, UInt64>, count: InlineArray<nDimensions, UInt64>) async throws -> [OmType]
    func readConcurrent<let nDimensions: Int>(range: InlineArray<nDimensions, Range<UInt64>>) async throws -> [OmType]
    func readConcurrent<let nDimensions: Int>(into: UnsafeMutablePointer<OmType>, range: InlineArray<nDimensions, Range<UInt64>>, intoCubeOffset: InlineArray<nDimensions, UInt64>?, intoCubeDimension: InlineArray<nDimensions, UInt64>?) async throws
    //func readConcurrent(into: UnsafeMutablePointer<OmType>, offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, intoCubeOffset: UnsafePointer<UInt64>, intoCubeDimension: UnsafePointer<UInt64>, nDimensions: Int) async throws
}
