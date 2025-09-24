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

/// Each variable (array and scalar) contains datatype, name and children
public protocol OmFileVariableProtocol: Sendable {
    var dataType: OmDataType { get }
    var numberOfChildren: UInt32 { get }
    var name: String { get }
    
    func getChild(index: UInt32) async throws -> Self?
    func getChild(name: String) async throws -> Self?
}

/// Protocol for `OmFileReader` but without the underlaying backend implementation
/// This protocol can be used to abstract multiple reader using different backends
public protocol OmFileReaderProtocol: OmFileVariableProtocol {
    func scalar<OmType: OmFileScalarDataTypeProtocol>(of: OmType.Type) throws -> any OmFileReaderArrayProtocol<OmType>
    func array<OmType: OmFileArrayDataTypeProtocol>(of: OmType.Type, io_size_max: UInt64, io_size_merge: UInt64) throws -> any OmFileReaderArrayProtocol<OmType>
}

/// Protocol for `OmFileReaderArray` to type erase the underlaying backend implementation
public protocol OmFileReaderArrayProtocol<OmType>: OmFileVariableProtocol {
    associatedtype OmType: OmFileArrayDataTypeProtocol
    
    var compression: OmCompressionType { get }
    var scaleFactor: Float { get }
    var addOffset: Float { get }
    
    func withDimensions<R>(_ body: (_: UnsafeBufferPointer<UInt64>) -> R) -> R
    func withChunkDimensions<R>(_ body: (_: UnsafeBufferPointer<UInt64>) -> R) -> R
    func getDimensions() -> [UInt64]
    func getChunkDimensions() -> [UInt64]
    
    func willNeed(range: [Range<UInt64>]?) async throws
    func willNeed(offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, nDimensions: Int) async throws
    
    func read(offset: [UInt64], count: [UInt64]) async throws -> [OmType]
    func read(range: [Range<UInt64>]?) async throws -> [OmType]
    func read(into: UnsafeMutablePointer<OmType>, range: [Range<UInt64>], intoCubeOffset: [UInt64]?, intoCubeDimension: [UInt64]?) async throws
    func read(into: UnsafeMutablePointer<OmType>, offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, intoCubeOffset: UnsafePointer<UInt64>, intoCubeDimension: UnsafePointer<UInt64>, nDimensions: Int) async throws
    
    func readConcurrent(offset: [UInt64], count: [UInt64]) async throws -> [OmType]
    func readConcurrent(range: [Range<UInt64>]?) async throws -> [OmType]
    func readConcurrent(into: UnsafeMutablePointer<OmType>, range: [Range<UInt64>], intoCubeOffset: [UInt64]?, intoCubeDimension: [UInt64]?) async throws
    func readConcurrent(into: UnsafeMutablePointer<OmType>, offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, intoCubeOffset: UnsafePointer<UInt64>, intoCubeDimension: UnsafePointer<UInt64>, nDimensions: Int) async throws
}


/// Protocol for `OmFileReaderScalar` to type erase the underlaying backend implementation
public protocol OmFileReaderScalarProtocol<OmType>: OmFileVariableProtocol {
    associatedtype OmType: OmFileScalarDataTypeProtocol
    
    func read() async throws -> OmType
}
