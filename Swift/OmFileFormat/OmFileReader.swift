//
//  OmFileReader2.swift
//  OpenMeteoApi
//
//  Created by Patrick Zippenfenig on 19.10.2024.
//

import Foundation
@_implementationOnly import OmFileFormatC

/// High level implementation to read an OpenMeteo file
/// Decodes meta data which may include JSON
/// Handles actual file reads. The current implementation just uses MMAP or plain memory.
/// Later implementations may use async read operations
public struct OmFileReader<Backend: OmFileReaderBackend> {
    /// Points to the underlying memory. Needs to remain in scope to keep memory accessible
    public let fn: Backend

    let variable: UnsafePointer<OmVariable_t?>?

    /// Open a file and decode om file meta data. In this case  fn is typically mmap or just plain memory
    public init(fn: Backend) throws {
        self.fn = fn

        let headerSize = om_header_size()
        let headerData = fn.getData(offset: 0, count: headerSize)

        switch om_header_type(headerData) {
        case OM_HEADER_LEGACY:
            self.variable = om_variable_init(headerData)
        case OM_HEADER_READ_TRAILER:
            let fileSize = fn.count
            let trailerSize = om_trailer_size()
            let trailerData = fn.getData(offset: fileSize - trailerSize, count: trailerSize)
            var offset: UInt64 = 0
            var size: UInt64 = 0
            guard om_trailer_read(trailerData, &offset, &size) else {
                throw OmFileFormatSwiftError.notAnOpenMeteoFile
            }
            // Read data from root.offset by root.size. Important: data must remain accessible throughout the use of this variable!!
            let dataVariable = fn.getData(offset: Int(offset), count: Int(size))
            self.variable = om_variable_init(dataVariable)
        case OM_HEADER_INVALID:
            fallthrough
        default:
            throw OmFileFormatSwiftError.notAnOpenMeteoFile
        }
    }

    init(fn: Backend, variable: UnsafePointer<OmVariable_t?>?) {
        self.fn = fn
        self.variable = variable
    }

    public func isLegacyFormat() -> Bool {
        return om_header_type(fn.getData(offset: 0, count: om_header_size())) == OM_HEADER_LEGACY
    }

    public var dataType: DataType {
        return DataType(rawValue: UInt8(om_variable_get_type(variable).rawValue))!
    }

    public func getName() -> String? {
        let name = om_variable_get_name(variable);
        guard name.size > 0 else {
            return nil
        }
        let buffer = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: name.value), count: Int(name.size), deallocator: .none)
        return String(data: buffer, encoding: .utf8)
    }

    public var numberOfChildren: UInt32 {
        return om_variable_get_children_count(variable)
    }

    public func getChild(_ index: UInt32) -> OmFileReader<Backend>? {
        var size: UInt64 = 0
        var offset: UInt64 = 0
        guard om_variable_get_children(variable, index, 1, &offset, &size) else {
            return nil
        }
        /// Read data from child.offset by child.size
        let dataChild = fn.getData(offset: Int(offset), count: Int(size))
        let childVariable = om_variable_init(dataChild)
        return OmFileReader(fn: fn, variable: childVariable)
    }

    public func readScalar<OmType: OmFileScalarDataTypeProtocol>() -> OmType? {
        guard OmType.dataTypeScalar == self.dataType else {
            return nil
        }
        if OmType.dataTypeScalar == .string {
            let stringValue = om_variable_get_scalar_string(variable)
            guard stringValue.size > 0 else {
                return nil
            }
            return stringValue as? OmType
            //// Create a copy of the string buffer so that the data is
            //// always owned by the caller.
            //let buffer = Data(bytes: stringValue.value, count: Int(stringValue.size))
            //return String(data: buffer, encoding: .utf8) as? OmType
        }
        var value = OmType()
        guard withUnsafeMutablePointer(to: &value, { om_variable_get_scalar(variable, $0) }) == ERROR_OK else {
            return nil
        }
        return value
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
}

extension OmFileReader where Backend == MmapFile {
    public init(file: String) throws {
        let fn = try FileHandle.openFileReading(file: file)
        let mmap = try MmapFile(fn: fn)
        try self.init(fn: mmap)
    }
}



/// Represents a variable that is an array of a given type.
/// The previous function `asArray(of: T)` instantiates this struct and ensures it is the correct type (e.g. a float array)
public struct OmFileReaderArray<Backend: OmFileReaderBackend, OmType: OmFileArrayDataTypeProtocol> {
    /// Points to the underlying memory. Needs to remain in scope to keep memory accessible
    public let fn: Backend

    let variable: UnsafePointer<OmVariable_t?>?

    let io_size_max: UInt64

    let io_size_merge: UInt64

    public var compression: CompressionType {
        return CompressionType(rawValue: UInt8(om_variable_get_compression(variable).rawValue))!
    }

    public var scaleFactor: Float {
        return om_variable_get_scale_factor(variable)
    }

    public var addOffset: Float {
        return om_variable_get_add_offset(variable)
    }

    public func getDimensions() -> UnsafeBufferPointer<UInt64> {
        let dimensions = om_variable_get_dimensions(variable);
        return UnsafeBufferPointer<UInt64>(start: dimensions.values, count: Int(dimensions.count))
    }

    public func getChunkDimensions() -> UnsafeBufferPointer<UInt64> {
        let dimensions = om_variable_get_chunks(variable);
        return UnsafeBufferPointer<UInt64>(start: dimensions.values, count: Int(dimensions.count))
    }

    /// Read variable as float array
    public func read(offset: [UInt64], count: [UInt64]) throws -> [OmType] {
        let n = count.reduce(1, *)
        let intoCubeOffset = [UInt64](repeating: 0, count: count.count)
        let out = try [OmType].init(unsafeUninitializedCapacity: Int(n)) {
            try read(
                into: $0.baseAddress!,
                offset: offset,
                count: count,
                intoCubeOffset: intoCubeOffset,
                intoCubeDimension: count,
                nDimensions: offset.count
            )
            $1 += Int(n)
        }
        return out
    }

    /// Read variable as float array
    public func read(range: [Range<UInt64>]? = nil) throws -> [OmType] {
        let range = range ?? self.getDimensions().map({ 0..<$0 })
        let outDims = range.map({UInt64($0.count)})
        let n = outDims.reduce(1, *)
        let out = try [OmType].init(unsafeUninitializedCapacity: Int(n)) {
            try read(
                into: $0.baseAddress!,
                range: range
            )
            $1 += Int(n)
        }
        return out
    }

    /// Read a variable as an array of dynamic type.
    public func read(into: UnsafeMutablePointer<OmType>, range: [Range<UInt64>], intoCubeOffset: [UInt64]? = nil, intoCubeDimension: [UInt64]? = nil) throws {
        let offset = range.map({$0.lowerBound})
        let count = range.map({UInt64($0.count)})
        let nDimensions = count.count
        let intoCubeOffset = intoCubeOffset ?? .init(repeating: 0, count: nDimensions)
        let intoCubeDimension = intoCubeDimension ?? count
        assert(intoCubeOffset.count == nDimensions)
        assert(intoCubeDimension.count == nDimensions)
        assert(offset.count == nDimensions)
        assert(count.count == nDimensions)
        try self.read(into: into, offset: offset, count: count, intoCubeOffset: intoCubeOffset, intoCubeDimension: intoCubeDimension, nDimensions: nDimensions)
    }

    /// Read data by offset and count
    public func read(into: UnsafeMutablePointer<OmType>, offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, intoCubeOffset: UnsafePointer<UInt64>, intoCubeDimension: UnsafePointer<UInt64>, nDimensions: Int) throws {
        var decoder = OmDecoder_t()
        let error = om_decoder_init(
            &decoder,
            variable,
            UInt64(nDimensions),
            offset,
            count,
            intoCubeOffset,
            intoCubeDimension,
            io_size_merge,
            io_size_max
        )
        guard error == ERROR_OK else {
            throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
        }
        try fn.decode(decoder: &decoder, into: into)
    }

    /// Prefetch data
    public func willNeed(range: [Range<UInt64>]? = nil) throws {
        let range = range ?? self.getDimensions().map({ 0..<$0 })
        let offset = range.map({$0.lowerBound})
        let count = range.map({UInt64($0.count)})
        try self.willNeed(offset: offset, count: count)
    }

    /// Prefetch data
    public func willNeed(offset: [UInt64], count: [UInt64]) throws {
        let nDimensions = count.count
        assert(offset.count == nDimensions)

        try offset.withUnsafeBufferPointer({ readOffset in
            try count.withUnsafeBufferPointer({ readCount in
                var decoder = OmDecoder_t()
                let error = om_decoder_init(
                    &decoder,
                    variable,
                    UInt64(nDimensions),
                    readOffset.baseAddress,
                    readCount.baseAddress,
                    nil,
                    nil,
                    io_size_merge,
                    io_size_max
                )
                guard error == ERROR_OK else {
                    throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                }
                fn.decodePrefetch(decoder: &decoder)
            })
        })
    }

    /// Read variable as float array
    public func readConcurrent(offset: [UInt64], count: [UInt64]) async throws -> [OmType] {
        let n = count.reduce(1, *)
        var out = [OmType].init(unsafeUninitializedCapacity: Int(n)) {
            $1 += Int(n)
        }
        let intoCubeOffset = [UInt64](repeating: 0, count: count.count)
        try await readConcurrent(
            into: &out,
            offset: offset,
            count: count,
            intoCubeOffset: intoCubeOffset,
            intoCubeDimension: count,
            nDimensions: offset.count
        )
        return out
    }

    /// Read variable as float array
    public func readConcurrent(range: [Range<UInt64>]? = nil) async throws -> [OmType] {
        let range = range ?? self.getDimensions().map({ 0..<$0 })
        let outDims = range.map({UInt64($0.count)})
        let n = outDims.reduce(1, *)
        var out = [OmType].init(unsafeUninitializedCapacity: Int(n)) {
            $1 += Int(n)
        }
        try await readConcurrent(
            into: &out,
            range: range
        )
        return out
    }

    /// Read a variable as an array of dynamic type.
    public func readConcurrent(into: UnsafeMutablePointer<OmType>, range: [Range<UInt64>], intoCubeOffset: [UInt64]? = nil, intoCubeDimension: [UInt64]? = nil) async throws {
        let nDimensions = range.count
        let offset = range.map({$0.lowerBound})
        let count = range.map({UInt64($0.count)})
        let intoCubeOffset = intoCubeOffset ?? .init(repeating: 0, count: nDimensions)
        let intoCubeDimension = intoCubeDimension ?? count
        assert(intoCubeOffset.count == nDimensions)
        assert(intoCubeDimension.count == nDimensions)
        assert(offset.count == nDimensions)
        try await self.readConcurrent(into: into, offset: offset, count: count, intoCubeOffset: intoCubeOffset, intoCubeDimension: intoCubeDimension, nDimensions: range.count)
    }

    /// Read data by offset and count
    public func readConcurrent(into: UnsafeMutablePointer<OmType>, offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, intoCubeOffset: UnsafePointer<UInt64>, intoCubeDimension: UnsafePointer<UInt64>, nDimensions: Int) async throws {

        // TODO allow null pointer for intoCubeOffset and intoCubeDimension

        var decoder = OmDecoder_t()
        let error = om_decoder_init(
            &decoder,
            variable,
            UInt64(nDimensions),
            offset,
            count,
            intoCubeOffset,
            intoCubeDimension,
            io_size_merge,
            io_size_max
        )
        guard error == ERROR_OK else {
            throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
        }
        try await fn.decodeConcurrent(decoder: &decoder, into: into)
    }
}

extension OmFileReaderBackend {
    /// Read and decode
    func decode(decoder: UnsafePointer<OmDecoder_t>, into: UnsafeMutableRawPointer) throws {
        var indexRead = OmDecoder_indexRead_t()
        om_decoder_init_index_read(decoder, &indexRead)

        /// The size to decode a single chunk
        let bufferSize = om_decoder_read_buffer_size(decoder)
        try withUnsafeTemporaryAllocation(byteCount: Int(bufferSize), alignment: 1) { buffer in
            /// Loop over index blocks and read index data
            while om_decoder_next_index_read(decoder, &indexRead) {
                //print("Read index \(indexRead)")
                let indexData = self.getData(offset: Int(indexRead.offset), count: Int(indexRead.count))

                var dataRead = OmDecoder_dataRead_t()
                om_decoder_init_data_read(&dataRead, &indexRead)

                var error: OmError_t = ERROR_OK
                /// Loop over data blocks and read compressed data chunks
                while om_decoder_next_data_read(decoder, &dataRead, indexData, indexRead.count, &error) {
                    //print("Read data \(dataRead) for chunk index \(dataRead.chunkIndex)")
                    let dataData = self.getData(offset: Int(dataRead.offset), count: Int(dataRead.count))
                    guard om_decoder_decode_chunks(decoder, dataRead.chunkIndex, dataData, dataRead.count, into, buffer.baseAddress, &error) else {
                        throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                    }
                }
                guard error == ERROR_OK else {
                    throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                }
            }
        }
    }

    /// Read and decode
    /// Note: This function uses more memory
    /// Decodes chunks concurrently (limited by io sizes). Only `om_decoder_decode_chunks` is called concurrently
    func decodeConcurrent(decoder: UnsafePointer<OmDecoder_t>, into: UnsafeMutableRawPointer) async throws {
        var indexRead = OmDecoder_indexRead_t()
        om_decoder_init_index_read(decoder, &indexRead)

        try await withThrowingTaskGroup(of: Void.self) { group in
            /// The size to decode a single chunk
            let bufferSize = om_decoder_read_buffer_size(decoder)

            /// Loop over index blocks and read index data
            while om_decoder_next_index_read(decoder, &indexRead) {
                //print("Read index \(indexRead)")
                let indexData = self.getData(offset: Int(indexRead.offset), count: Int(indexRead.count))

                var dataRead = OmDecoder_dataRead_t()
                om_decoder_init_data_read(&dataRead, &indexRead)

                var error: OmError_t = ERROR_OK
                /// Loop over data blocks and read compressed data chunks
                while om_decoder_next_data_read(decoder, &dataRead, indexData, indexRead.count, &error) {
                    //print("ENQUEUE chunk index \(dataRead.chunkIndex)")
                    let dataReadOffset = dataRead.offset
                    let dataReadCount = dataRead.count
                    let chunkIndex = dataRead.chunkIndex
                    group.addTask {
                        try withUnsafeTemporaryAllocation(byteCount: Int(bufferSize), alignment: 1) { buffer in
                            //print("Read data chunk index \(chunkIndex), count=\(dataReadCount)")
                            let dataData = self.getData(offset: Int(dataReadOffset), count: Int(dataReadCount))
                            guard om_decoder_decode_chunks(decoder, chunkIndex, dataData, dataReadCount, into, buffer.baseAddress, &error) else {
                                throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                            }
                        }
                    }
                }
                guard error == ERROR_OK else {
                    throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                }
            }
            try await group.waitForAll()
        }
    }

    /// Do an madvice to load data chunks from disk into page cache in the background
    func decodePrefetch(decoder: UnsafePointer<OmDecoder_t>) {
        var indexRead = OmDecoder_indexRead_t()
        om_decoder_init_index_read(decoder, &indexRead)

        /// Loop over index blocks and read index data
        while om_decoder_next_index_read(decoder, &indexRead) {
            let indexData = self.getData(offset: Int(indexRead.offset), count: Int(indexRead.count))

            var dataRead = OmDecoder_dataRead_t()
            om_decoder_init_data_read(&dataRead, &indexRead)

            var error: OmError_t = ERROR_OK
            /// Loop over data blocks and read compressed data chunks
            while om_decoder_next_data_read(decoder, &dataRead, indexData, indexRead.count, &error) {
                self.prefetchData(offset: Int(dataRead.offset), count: Int(dataRead.count))
            }
        }
    }
}
