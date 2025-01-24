import Foundation

/// OmFileReader can read data from this backend
public protocol OmFileReaderBackend {
    /// Length in bytes
    var count: Int { get }
    
    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int)
    
    /// Read data
    func getData(offset: Int, count: Int) -> UnsafeRawPointer
}

/// Make `FileHandle` work as reader
extension MmapFile: OmFileReaderBackend {
    public func getData(offset: Int, count: Int) -> UnsafeRawPointer {
        assert(offset + count <= data.count)
        return UnsafeRawPointer(data.baseAddress!.advanced(by: offset))
    }
    
    public func prefetchData(offset: Int, count: Int) {
        self.prefetchData(offset: offset, count: count, advice: .willneed)
    }
    
    public var count: Int {
        return data.count
    }
}

/// Make `Data` work as reader
extension DataAsClass: OmFileReaderBackend {
    public func getData(offset: Int, count: Int) -> UnsafeRawPointer {
        // NOTE: Probably a bad idea to expose a pointer
        return data.withUnsafeBytes({
            $0.baseAddress!.advanced(by: offset)
        })
    }
    
    public var count: Int {
        return data.count
    }
    
    public func prefetchData(offset: Int, count: Int) {
        
    }
}
