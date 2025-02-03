import Foundation

/// OmFileWriter can write data to this backend
public protocol OmFileWriterBackend {
    func write<T>(contentsOf data: T) throws where T : DataProtocol
    func synchronize() throws
}

/// Need to maintain a strong reference
public final class DataAsClass {
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

/// Make `FileHandle` work as writer
extension FileHandle: OmFileWriterBackend {
    public func write<T>(contentsOf data: T, atOffset: Int) throws where T : DataProtocol {
        try seek(toOffset: UInt64(atOffset))
        try write(contentsOf: data)
    }
}
