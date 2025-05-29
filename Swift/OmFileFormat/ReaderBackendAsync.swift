import Foundation

/// OmFileReader can read data from this backend
public protocol OmFileReaderBackendAsync: Sendable {
    /// The return data can be a directly a pointer or a `Data` class that retains data.
    //associatedtype DataType: ContiguousBytes & Sendable

    /// Length in bytes
    func getCount() async throws -> UInt64

    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int) async throws
    
    /// Read data. Must be thread safe!
    func withData<T>(offset: Int, count: Int, fn: (UnsafeRawPointer) async throws -> T) async throws -> T
}

extension FileHandle: OmFileReaderBackendAsync {
    public func withData<T>(offset: Int, count: Int, fn: (UnsafeRawPointer) async throws -> T) async throws -> T {
        let data = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
        defer { data.deallocate() }
        /// Pread is thread safe
        let err = pread(self.fileDescriptor, data, count, off_t(offset))
        guard err == count else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotReadFile(errno: errno, error: error)
        }
        return try await fn(UnsafeRawPointer(data))
    }

    public func prefetchData(offset: Int, count: Int) async throws  {

    }

    public func getCount() async throws -> UInt64 {
        try seek(toOffset: 0)
        return try seekToEnd()
    }
}
