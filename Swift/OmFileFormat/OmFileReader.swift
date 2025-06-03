import Foundation
import OmFileFormatC


/// High level implementation to read an OpenMeteo file
/// Decodes meta data which may include JSON
/// Handles actual file reads. The current implementation just uses MMAP or plain memory.
/// Later implementations may use async read operations
public struct OmFileReader<Backend: OmFileReaderBackend>: OmFileReaderProtocol {
    /// Points to the underlying memory. Needs to remain in scope to keep memory accessible
    public let fn: Backend

    /// Underlaying memory for the variable. Could just be a pointer or a reference counted allocated memory region
    let variable: Backend.DataType

    /// Open a file and decode om file meta data. In this case  fn is typically mmap or just plain memory
    public init(fn: Backend) async throws {
        self.fn = fn

        let headerSize = om_header_size()
        let headerType = try await fn.withData(offset: 0, count: headerSize) {
            om_header_type($0.baseAddress)
        }

        switch headerType {
        case OM_HEADER_LEGACY:
            self.variable = try await fn.getData(offset: 0, count: headerSize)
        case OM_HEADER_READ_TRAILER:
            let fileSize = fn.count
            let trailerSize = om_trailer_size()
            let (offset, size) = try await fn.withData(offset: fileSize - trailerSize, count: trailerSize) { trailerData in
                var offset: UInt64 = 0
                var size: UInt64 = 0
                guard om_trailer_read(trailerData.baseAddress, &offset, &size) else {
                    throw OmFileFormatSwiftError.notAnOpenMeteoFile
                }
                return (offset, size)
            }
            /// Read data from root.offset by root.size. Important: data must remain accessible throughout the use of this variable!!
            let dataVariable = try await fn.getData(offset: Int(offset), count: Int(size))
            self.variable = dataVariable
        case OM_HEADER_INVALID:
            fallthrough
        default:
            throw OmFileFormatSwiftError.notAnOpenMeteoFile
        }
    }

    init(fn: Backend, variable: Backend.DataType) {
        self.fn = fn
        self.variable = variable
    }

    public func isLegacyFormat() async throws -> Bool {
        return try await fn.withData(offset: 0, count: om_header_size()) {
            return om_header_type($0.baseAddress) == OM_HEADER_LEGACY
        }
    }

    public var dataType: OmDataType {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            return OmDataType(rawValue: UInt8(om_variable_get_type(variable).rawValue))!
        })
    }

    public func getName() -> String? {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            let name = om_variable_get_name(variable);
            guard name.size > 0 else {
                return nil
            }
            let buffer = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: name.value), count: Int(name.size), deallocator: .none)
            return String(data: buffer, encoding: .utf8)
        })
    }

    public var numberOfChildren: UInt32 {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            return om_variable_get_children_count(variable)
        })
    }

    public func getChild(_ index: UInt32) async throws -> OmFileReader<Backend>? {
        var size: UInt64 = 0
        var offset: UInt64 = 0
        guard variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            return om_variable_get_children(variable, index, 1, &offset, &size)
        }) else {
            return nil
        }
        /// Read data from child.offset by child.size
        let dataChild = try await fn.getData(offset: Int(offset), count: Int(size))
        return OmFileReader(fn: fn, variable: dataChild)
    }

    public func readScalar<OmType: OmFileScalarDataTypeProtocol>() -> OmType? {
        guard OmType.dataTypeScalar == dataType else {
            return nil
        }
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            var ptr = UnsafeMutableRawPointer(bitPattern: 0)
            var size: UInt64 = 0
            guard om_variable_get_scalar(variable, &ptr, &size) == ERROR_OK, let ptr else {
                return nil
            }
            return OmType(unsafeFrom: UnsafeRawBufferPointer(start: ptr, count: Int(size)))
        })
    }

    /// If it is an array of specified type. Return a type safe reader for this type
    /// `io_size_merge` The maximum size (in bytes) for merging consecutive IO operations. It helps to optimise read performance by merging small reads.
    /// `io_size_max` The maximum size (in bytes) for a single IO operation before it is split. It defines the threshold for splitting large reads.
    public func asArray<OmType: OmFileArrayDataTypeProtocol>(of: OmType.Type, io_size_max: UInt64 = 65536, io_size_merge: UInt64 = 512) -> OmFileReaderArray<Backend, OmType>? {
        guard OmType.dataTypeArray == self.dataType else {
            return nil
        }
        return OmFileReaderArray(
            fn: fn,
            variable: variable,
            io_size_max: io_size_max,
            io_size_merge: io_size_merge
        )
    }
    
    public func asArray<OmType>(of: OmType.Type, io_size_max: UInt64, io_size_merge: UInt64) -> (any OmFileReaderArrayProtocol<OmType>)? where OmType : OmFileArrayDataTypeProtocol {
        guard OmType.dataTypeArray == self.dataType else {
            return nil
        }
        return OmFileReaderArray(
            fn: fn,
            variable: variable,
            io_size_max: io_size_max,
            io_size_merge: io_size_merge
        )
    }
}
