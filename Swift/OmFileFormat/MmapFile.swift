import Foundation


/// `Mmap` all pages for a file
public final class MmapFile: Sendable {
    public let data: UnsafeBufferPointer<UInt8>
    public let file: FileHandle

    public enum Mode {
        case readOnly
        case readWrite

        /// mmap `prot` attribute
        fileprivate var prot: Int32 {
            switch self {
            case .readOnly:
                return PROT_READ
            case .readWrite:
                return PROT_READ | PROT_WRITE
            }
        }
    }

    public enum MAdvice {
        case willneed
        case dontneed

        fileprivate var mode: Int32 {
            switch self {
            case .willneed:
                return MADV_WILLNEED
            case .dontneed:
                return MADV_DONTNEED
            }
        }
    }

    /// Mmap the entire filehandle
    public init(fn: FileHandle, mode: Mode = .readOnly) throws {
        let len = try Int(fn.seekToEnd())
        guard let mem = mmap(nil, len, mode.prot, MAP_SHARED, fn.fileDescriptor, 0), mem != UnsafeMutableRawPointer(bitPattern: -1) else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotOpenFile(errno: errno, error: error)
        }
        //madvise(mem, len, MADV_SEQUENTIAL)
        let start = mem.assumingMemoryBound(to: UInt8.self)
        self.data = UnsafeBufferPointer(start: start, count: len)
        self.file = fn
    }

    /// Tell the OS to prefault the required memory pages. Subsequent calls to read data should be faster
    public func prefetchData(offset: Int, count: Int, advice: MAdvice) {
        /// Page start aligned to page size
        let pageStart = (offset / 4096) * 4096
        /// Length as a multiple of the page size
        let length = (count + 4096 - 1) / 4096 * 4096

        let ret = madvise(UnsafeMutableRawPointer(mutating: data.baseAddress!.advanced(by: pageStart)), length, advice.mode)
        guard ret == 0 else {
            let error = String(cString: strerror(errno))
            fatalError("madvice failed! ret=\(ret), errno=\(errno), \(error)")
        }
    }

    deinit {
        let len = data.count * MemoryLayout<UInt8>.size
        guard munmap(UnsafeMutableRawPointer(mutating: data.baseAddress!), len) == 0 else {
            fatalError("munmap failed")
        }
    }
}

extension MmapFile: OmFileReaderBackend {
    public var count: Int {
        return data.count
    }
    
    public func prefetchData(offset: Int, count: Int) async throws {
        self.prefetchData(offset: offset, count: count, advice: .willneed)
    }
    
    public func withData<T>(offset: Int, count: Int, fn: (UnsafeRawBufferPointer) throws -> T) async throws -> T {
        assert(offset + count <= data.count)
        let ptr = UnsafeRawBufferPointer(UnsafeBufferPointer(rebasing: data[offset ..< offset+count]))
        return try fn(ptr)
    }
    
    public func getData(offset: Int, count: Int) -> UnsafeRawBufferPointer {
        assert(offset + count <= data.count)
        let ptr = UnsafeRawBufferPointer(UnsafeBufferPointer(rebasing: data[offset ..< offset+count]))
        return ptr
    }
}

extension OmFileReader where Backend == MmapFile {
    public init(mmapFile: String) async throws {
        let fn = try FileHandle.openFileReading(file: mmapFile)
        let mmap = try MmapFile(fn: fn)
        try await self.init(fn: mmap)
    }
}
