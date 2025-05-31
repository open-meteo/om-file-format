import Foundation

/**
 A FileHandle with its length in bytes. This is required because there is no thread safe way to get the length
 */
public struct FileHandleWithCount: Sendable {
    public let fileHandle: FileHandle
    public let count: Int
    
    public init(_ fileHandle: FileHandle) throws {
        self.fileHandle = fileHandle
        try fileHandle.seek(toOffset: 0)
        self.count = Int(try fileHandle.seekToEnd())
    }
}

extension FileHandleWithCount: OmFileReaderBackendAsync {
    public func prefetchData(offset: Int, count: Int) async throws {
        // No prefetch possible
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
    
    public func withData<T>(offset: Int, count: Int, fn: (UnsafeRawBufferPointer) throws -> T) async throws -> T {
        return try await getData(offset: offset, count: count).withUnsafeBytes(fn)
    }
}

extension OmFileReaderAsync where Backend == FileHandleWithCount {
    public init(file: String) async throws {
        let fn = try FileHandle.openFileReading(file: file)
        let mmap = try FileHandleWithCount(fn)
        try await self.init(fn: mmap)
    }
}
