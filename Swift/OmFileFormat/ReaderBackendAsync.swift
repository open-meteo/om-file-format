import Foundation

/// OmFileReader can read data from this backend
public protocol OmFileReaderBackendAsync: Sendable {
    /// The return data can be a directly a pointer or a `Data` class that retains data.
    associatedtype DataType: ContiguousBytes & Sendable
    
    // Length in bytes
    var count: Int { get }

    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int) async throws
    
    /// Read data. Data will be retined of type `DataType`. Reads must be thread safe.
    func getData(offset: Int, count: Int) async throws -> DataType
    
    /// Read data. Data is only temporarily read inside the callback
    func withData<T>(offset: Int, count: Int, fn: (UnsafeRawPointer) async throws -> T) async throws -> T
}
