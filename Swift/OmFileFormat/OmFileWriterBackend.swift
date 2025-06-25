import Foundation

/// OmFileWriter can write data to this backend
public protocol OmFileWriterBackend {
    func write<T>(contentsOf data: T) throws where T : DataProtocol
    func synchronize() throws
}

