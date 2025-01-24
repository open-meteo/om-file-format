import Foundation

/// OmFileReader can read data from this backend
public protocol OmFileReaderBackend {
    /// The return data can be a directly a pointer or a `Data` class that retains data.
    associatedtype DataType: ContiguousBytes
    
    /// Length in bytes
    var count: Int { get }
    
    /// Prefect data for future access. E.g. madvice on memory mapped files
    func prefetchData(offset: Int, count: Int)
    
    /// Read data
    func getData(offset: Int, count: Int) -> DataType
}

/// Make `FileHandle` work as reader
extension MmapFile: OmFileReaderBackend {
    public func getData(offset: Int, count: Int) -> Slice<UnsafeBufferPointer<UInt8>> {
        assert(offset + count <= data.count)
        return data[offset ..< offset + count]
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
    public func getData(offset: Int, count: Int) -> Data {
        assert(offset + count <= data.count)
        return data[offset ..< offset+count]
    }
    
    public var count: Int {
        return data.count
    }
    
    public func prefetchData(offset: Int, count: Int) {
        
    }
}
