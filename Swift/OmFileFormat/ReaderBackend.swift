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

extension DataAsClass: OmFileReaderBackend {
    public typealias DataType = Data.SubSequence
    
    public var count: Int {
        return data.count
    }
    
    public func prefetchData(offset: Int, count: Int) async throws {
        // nothing to do here
    }
    
    public func withData<T>(offset: Int, count: Int, fn: @Sendable (UnsafeRawBufferPointer) throws -> T) async throws -> T {
        try data[offset..<offset+count].withUnsafeBytes({
            try fn($0)
        })
    }
    
    public func getData(offset: Int, count: Int) async throws -> Data.SubSequence {
        return data[offset..<offset+count]
    }
}
