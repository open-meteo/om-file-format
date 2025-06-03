import Foundation


/// Need to maintain a strong reference
public final class DataAsClass: @unchecked Sendable {
    public var data: Data

    public init(data: Data) {
        self.data = data
    }
}

/// Make `Data` work as writer
extension DataAsClass: OmFileWriterBackend {
    public func synchronize() throws {

    }

    public func write<T>(contentsOf data: T) throws where T : DataProtocol {
        self.data.append(contentsOf: data)
    }
}

extension DataAsClass: OmFileReaderBackend {
    public typealias DataType = Data.SubSequence
    
    public var count: Int {
        return data.count
    }
    
    public func prefetchData(offset: Int, count: Int) async throws {
        // nothing to do here
    }
    
    public func withData<T>(offset: Int, count: Int, fn: @Sendable (UnsafeRawBufferPointer) throws -> T) async throws -> T {
        try data[offset..<offset+count].withUnsafeBytes({
            try fn($0)
        })
    }
    
    public func getData(offset: Int, count: Int) async throws -> Data.SubSequence {
        return data[offset..<offset+count]
    }
}

