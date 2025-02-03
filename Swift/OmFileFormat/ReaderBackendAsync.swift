import Foundation

/// OmFileReader can read data from this backend
public protocol OmFileReaderBackendAsync {
    /// The return data can be a directly a pointer or a `Data` class that retains data.
    associatedtype DataType: ContiguousBytes

    /// Length in bytes
    func getCount() async throws -> UInt64

    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int) async throws

    /// Read data. Must be thread safe!
    func getData(offset: Int, count: Int) async throws -> DataType
}

extension FileHandle: OmFileReaderBackendAsync {
    public func getData(offset: Int, count: Int) async throws -> Data {
        var data = Data(capacity: count)
        let err = data.withUnsafeMutableBytes({ data in
            /// Pread is thread safe
            pread(self.fileDescriptor, data.baseAddress, count, off_t(offset))
        })
        guard err == count else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotReadFile(errno: errno, error: error)
        }
        return data
    }

    public func prefetchData(offset: Int, count: Int) async throws  {

    }

    public func getCount() async throws -> UInt64 {
        try seek(toOffset: 0)
        return try seekToEnd()
    }
}
