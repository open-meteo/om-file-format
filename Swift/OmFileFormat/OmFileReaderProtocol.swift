/// Protocol for `OmFileReader` but without the underlaying backend implementation
/// This protocol can be used to abstract multiple reader using different backends
public protocol OmFileReaderProtocol: Sendable {
    var dataType: DataType { get }
    var numberOfChildren: UInt32 { get }
    
    func getName() -> String?
    func getChild(_ index: UInt32) async throws -> Self?
    
    func readScalar<OmType: OmFileScalarDataTypeProtocol>() -> OmType?
    func asArray<OmType: OmFileArrayDataTypeProtocol>(of: OmType.Type, io_size_max: UInt64, io_size_merge: UInt64) -> (any OmFileReaderArrayProtocol<OmType>)?
}

/// Protocol for `OmFileReaderArray` to type erase the underlaying backend implementation
public protocol OmFileReaderArrayProtocol<OmType>: Sendable {
    associatedtype OmType: OmFileArrayDataTypeProtocol
    
    var compression: CompressionType { get }
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
