import Foundation

/// OmFileReader can read data from this backend
public protocol OmFileReaderBackendAsync: Sendable {
    /// The return data can be a directly a pointer or a `Data` class that retains data.
    associatedtype DataType: ContiguousBytes & Sendable
    
    // Length in bytes
    var count: UInt64 { get }

    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int) async throws
    
    /// Read data. Data might be retained. Reads must be thread safe.
    func getData(offset: Int, count: Int) async throws -> DataType
    
    /// Read data. Data is only temporarily read inside the callback
    func withData<T>(offset: Int, count: Int, fn: (UnsafeRawPointer) async throws -> T) async throws -> T
}

/**
 A FileHandle with its length in bytes. This is required because there is no thread safe way to get the length
 */
public struct FileHandleWithCount: OmFileReaderBackendAsync {
    public let fileHandle: FileHandle
    public let count: UInt64
    
    public init(_ fileHandle: FileHandle) throws {
        self.fileHandle = fileHandle
        try fileHandle.seek(toOffset: 0)
        self.count = try fileHandle.seekToEnd()
    }
    
    public func prefetchData(offset: Int, count: Int) async throws {
        
    }
    
    public func getData(offset: Int, count: Int) async throws -> Data {
        var data = Data(capacity: count)
        let err = data.withUnsafeMutableBytes({ data in
            /// Pread is thread safe
            pread(fileHandle.fileDescriptor, data.baseAddress, count, off_t(offset))
        })
        guard err == count else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotReadFile(errno: errno, error: error)
        }
        return data
    }
    
    public func withData<T>(offset: Int, count: Int, fn: (UnsafeRawPointer) async throws -> T) async throws -> T {
        let data = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
        defer { data.deallocate() }
        /// Pread is thread safe
        let err = pread(fileHandle.fileDescriptor, data, count, off_t(offset))
        guard err == count else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotReadFile(errno: errno, error: error)
        }
        return try await fn(UnsafeRawPointer(data))
    }
}

