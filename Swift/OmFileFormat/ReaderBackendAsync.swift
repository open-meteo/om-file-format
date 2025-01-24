import Foundation

/// OmFileReader can read data from this backend
public protocol OmFileReaderBackendAsync {
    /// The return data can be a directly a pointer or a `Data` class that retains data.
    associatedtype DataType: ContiguousBytes
    
    /// Length in bytes
    func getCount() async throws -> UInt64
    
    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int) async throws 
    
    /// Read data
    func getData(offset: Int, count: Int) async throws -> DataType
}

// NOTE: FileHandle cannot be used properly concurrently
extension FileHandle: OmFileReaderBackendAsync {
    public func getData(offset: Int, count: Int) async throws -> Data {
        // NOTE: Seek + read is not thread safe....
        try seek(toOffset: UInt64(offset))
        return try read(upToCount: count) ?? Data()
    }
    
    public func prefetchData(offset: Int, count: Int) async throws  {
        
    }
    
    public func getCount() async throws -> UInt64 {
        try seek(toOffset: 0)
        return try seekToEnd()
    }
}
