/// OmFileReader can read data from this backend
public protocol OmFileReaderBackend {
    /// The pointer type can be a directly a pointer or a `Data` class that retains data.
    /// Note: Needs additional testing to ensure data is retained while calling C functions
    associatedtype DataType: OmFileReaderPointer
    
    /// Length in bytes
    var count: Int { get }
    func prefetchData(offset: Int, count: Int)
    
    func getData(offset: Int, count: Int) -> DataType
}

public protocol OmFileReaderPointer {
    var pointer: UnsafeRawPointer { get }
}

extension UnsafeRawPointer: OmFileReaderPointer {
    public var pointer: UnsafeRawPointer {
        return self
    }
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
