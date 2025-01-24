import Foundation
@_implementationOnly import OmFileFormatC

/// High level implementation to read an OpenMeteo file
/// Decodes meta data which may include JSON
/// Handles actual file reads. The current implementation just uses MMAP or plain memory.
/// Later implementations may use async read operations
public struct OmFileReaderAsync<Backend: OmFileReaderBackendAsync> {
    /// Points to the underlying memory. Needs to remain in scope to keep memory accessible
    public let fn: Backend
    
    /// Underlaying memory for the variable. Could just be a pointer or a reference counted allocated memory region
    let variable: Backend.DataType
        
    /// Open a file and decode om file meta data. In this case  fn is typically mmap or just plain memory
    public init(fn: Backend) async throws {
        self.fn = fn
        
        let headerSize = om_header_size()
        let headerData = try await fn.getData(offset: 0, count: headerSize)
        let headerType = headerData.withUnsafeBytes {
            om_header_type($0.baseAddress)
        }
        
        switch headerType {
        case OM_HEADER_LEGACY:
            self.variable = headerData
        case OM_HEADER_READ_TRAILER:
            let fileSize = try await fn.getCount()
            let trailerSize = om_trailer_size()
            let trailerData = try await fn.getData(offset: Int(fileSize) - trailerSize, count: trailerSize)
            var offset: UInt64 = 0
            var size: UInt64 = 0
            guard trailerData.withUnsafeBytes({om_trailer_read($0.baseAddress, &offset, &size)}) else {
                throw OmFileFormatSwiftError.notAnOpenMeteoFile
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
        return try await fn.getData(offset: 0, count: om_header_size()).withUnsafeBytes({
            return om_header_type($0.baseAddress) == OM_HEADER_LEGACY
        })
    }
    
    public var dataType: DataType {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            return DataType(rawValue: UInt8(om_variable_get_type(variable).rawValue))!
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
    
    public func getChild(_ index: UInt32) async throws -> OmFileReaderAsync<Backend>? {
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
        return OmFileReaderAsync(fn: fn, variable: dataChild)
    }
    
    public func readScalar<OmType: OmFileScalarDataTypeProtocol>() -> OmType? {
        guard OmType.dataTypeScalar == dataType else {
            return nil
        }
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            var value = OmType()
            guard withUnsafeMutablePointer(to: &value, { om_variable_get_scalar(variable, $0) }) == ERROR_OK else {
                return nil
            }
            return value
        })
    }
    
    /// If it is an array of specified type. Return a type safe reader for this type
    /// `io_size_merge` The maximum size (in bytes) for merging consecutive IO operations. It helps to optimise read performance by merging small reads.
    /// `io_size_max` The maximum size (in bytes) for a single IO operation before it is split. It defines the threshold for splitting large reads.
    public func asArray<OmType: OmFileArrayDataTypeProtocol>(of: OmType.Type, io_size_max: UInt64 = 65536, io_size_merge: UInt64 = 512) -> OmFileReaderAsyncArray<Backend, OmType>? {
        guard OmType.dataTypeArray == self.dataType else {
            return nil
        }
        return OmFileReaderAsyncArray(
            fn: fn,
            variable: variable,
            io_size_max: io_size_max,
            io_size_merge: io_size_merge
        )
    }
}

/// Represents a variable that is an array of a given type.
/// The previous function `asArray(of: T)` instantiates this struct and ensures it is the correct type (e.g. a float array)
public struct OmFileReaderAsyncArray<Backend: OmFileReaderBackendAsync, OmType: OmFileArrayDataTypeProtocol> {
    /// Points to the underlying memory. Needs to remain in scope to keep memory accessible
    public let fn: Backend
    
    let variable: Backend.DataType
    
    let io_size_max: UInt64
        
    let io_size_merge: UInt64
    
    public var compression: CompressionType {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            return CompressionType(rawValue: UInt8(om_variable_get_compression(variable).rawValue))!
        })
    }
    
    public var scaleFactor: Float {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            return om_variable_get_scale_factor(variable)
        })
    }
    
    public var addOffset: Float {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            return om_variable_get_add_offset(variable)
        })
    }
    
    /// Zero copy access to dimensions
    public func withDimensions<R>(_ body: (_: UnsafeBufferPointer<UInt64>) -> R) -> R {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            let dimensions = om_variable_get_dimensions(variable)
            return body(UnsafeBufferPointer<UInt64>(start: dimensions.values, count: Int(dimensions.count)))
        })
    }
    
    /// Zero copy access to chunk dimensions
    public func withChunkDimensions<R>(_ body: (_: UnsafeBufferPointer<UInt64>) -> R) -> R {
        return variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
            let dimensions = om_variable_get_chunks(variable)
            return body(UnsafeBufferPointer<UInt64>(start: dimensions.values, count: Int(dimensions.count)))
        })
    }
    
    public func getDimensions() -> [UInt64] {
        return withDimensions(Array.init)
    }
    
    public func getChunkDimensions() -> [UInt64] {
        return withChunkDimensions(Array.init)
    }
    
    /// Read variable as float array
    public func read(offset: [UInt64], count: [UInt64]) async throws -> [OmType] {
        let n = count.reduce(1, *)
        let intoCubeOffset = [UInt64](repeating: 0, count: count.count)
        var out = [OmType].init(unsafeUninitializedCapacity: Int(n)) {
            $1 += Int(n)
        }
        try await read(
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
    public func read(range: [Range<UInt64>]? = nil) async throws -> [OmType] {
        let range = range ?? self.getDimensions().map({ 0..<$0 })
        let outDims = range.map({UInt64($0.count)})
        let n = outDims.reduce(1, *)
        var out = [OmType].init(unsafeUninitializedCapacity: Int(n)) {
            $1 += Int(n)
        }
        try await read(
            into: &out,
            range: range
        )
        return out
    }
    
    /// Read a variable as an array of dynamic type.
    public func read(into: UnsafeMutablePointer<OmType>, range: [Range<UInt64>], intoCubeOffset: [UInt64]? = nil, intoCubeDimension: [UInt64]? = nil) async throws {
        let offset = range.map({$0.lowerBound})
        let count = range.map({UInt64($0.count)})
        let nDimensions = count.count
        let intoCubeOffset = intoCubeOffset ?? .init(repeating: 0, count: nDimensions)
        let intoCubeDimension = intoCubeDimension ?? count
        assert(intoCubeOffset.count == nDimensions)
        assert(intoCubeDimension.count == nDimensions)
        assert(offset.count == nDimensions)
        assert(count.count == nDimensions)
        try await self.read(into: into, offset: offset, count: count, intoCubeOffset: intoCubeOffset, intoCubeDimension: intoCubeDimension, nDimensions: nDimensions)
    }
    
    /// Read data by offset and count
    public func read(into: UnsafeMutablePointer<OmType>, offset: UnsafePointer<UInt64>, count: UnsafePointer<UInt64>, intoCubeOffset: UnsafePointer<UInt64>, intoCubeDimension: UnsafePointer<UInt64>, nDimensions: Int) async throws {
        var decoder = try variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
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
            return decoder
        })
        // TODO: Technically memory from `variable` is escaping through decoder. Consider copy all dimension information into decoder
        try await fn.decode(decoder: &decoder, into: into)
    }
    
    /// Prefetch data
    /*public func willNeed(range: [Range<UInt64>]? = nil) throws {
        let range = range ?? self.getDimensions().map({ 0..<$0 })
        let offset = range.map({$0.lowerBound})
        let count = range.map({UInt64($0.count)})
        try self.willNeed(offset: offset, count: count)
    }*/
    
    /// Prefetch data
    /*public func willNeed(offset: [UInt64], count: [UInt64]) throws {
        let nDimensions = count.count
        assert(offset.count == nDimensions)
        return try variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
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
        })
    }*/
    
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
        var decoder = try variable.withUnsafeBytes({
            let variable = om_variable_init($0.baseAddress)
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
            return decoder
        })
        // TODO: Technically memory from `variable` is escaping through decoder. Consider copy all dimension information into decoder
        try await fn.decodeConcurrent(decoder: &decoder, into: into)
    }
}

extension OmFileReaderBackendAsync {
    /// Read and decode
    func decode(decoder: UnsafePointer<OmDecoder_t>, into: UnsafeMutableRawPointer) async throws {
        var indexRead = OmDecoder_indexRead_t()
        om_decoder_init_index_read(decoder, &indexRead)
        
        /// The size to decode a single chunk
        let bufferSize = om_decoder_read_buffer_size(decoder)
        
        /// Loop over index blocks and read index data
        while om_decoder_next_index_read(decoder, &indexRead) {
            //print("Read index \(indexRead)")
            let indexData = try await self.getData(offset: Int(indexRead.offset), count: Int(indexRead.count))
            
            var dataRead = OmDecoder_dataRead_t()
            om_decoder_init_data_read(&dataRead, &indexRead)
            
            var error: OmError_t = ERROR_OK
                /// Loop over data blocks and read compressed data chunks
            while indexData.withUnsafeBytes({ om_decoder_next_data_read(decoder, &dataRead, $0.baseAddress, indexRead.count, &error) }) {
                //print("Read data \(dataRead) for chunk index \(dataRead.chunkIndex)")
                let dataData = try await self.getData(offset: Int(dataRead.offset), count: Int(dataRead.count))
                try dataData.withUnsafeBytes({ dataData in
                    try withUnsafeTemporaryAllocation(byteCount: Int(bufferSize), alignment: 1) { buffer in
                        guard om_decoder_decode_chunks(decoder, dataRead.chunkIndex, dataData.baseAddress, dataRead.count, into, buffer.baseAddress, &error) else {
                            throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                        }
                    }
                })
            }
            guard error == ERROR_OK else {
                throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
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
                let indexData = try await self.getData(offset: Int(indexRead.offset), count: Int(indexRead.count))
                
                var dataRead = OmDecoder_dataRead_t()
                om_decoder_init_data_read(&dataRead, &indexRead)
                
                var error: OmError_t = ERROR_OK
                indexData.withUnsafeBytes({ indexData in
                    /// Loop over data blocks and read compressed data chunks
                    while om_decoder_next_data_read(decoder, &dataRead, indexData.baseAddress, indexRead.count, &error) {
                        //print("ENQUEUE chunk index \(dataRead.chunkIndex)")
                        let dataReadOffset = dataRead.offset
                        let dataReadCount = dataRead.count
                        let chunkIndex = dataRead.chunkIndex
                        group.addTask {
                            //print("Read data chunk index \(chunkIndex), count=\(dataReadCount)")
                            let dataData = try await self.getData(offset: Int(dataReadOffset), count: Int(dataReadCount))
                            try withUnsafeTemporaryAllocation(byteCount: Int(bufferSize), alignment: 8) { buffer in
                                try dataData.withUnsafeBytes({ dataData in
                                    var error: OmError_t = ERROR_OK
                                    guard om_decoder_decode_chunks(decoder, chunkIndex, dataData.baseAddress, dataReadCount, into, buffer.baseAddress, &error) else {
                                        throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                                    }
                                })
                            }
                        }
                    }
                })
                guard error == ERROR_OK else {
                    throw OmFileFormatSwiftError.omDecoder(error: String(cString: om_error_string(error)))
                }
            }
            try await group.waitForAll()
        }
    }

    /// Do an madvice to load data chunks from disk into page cache in the background
    /*func decodePrefetch(decoder: UnsafePointer<OmDecoder_t>) {
        var indexRead = OmDecoder_indexRead_t()
        om_decoder_init_index_read(decoder, &indexRead)
        
        /// Loop over index blocks and read index data
        while om_decoder_next_index_read(decoder, &indexRead) {
            let indexData = self.getData(offset: Int(indexRead.offset), count: Int(indexRead.count))
            
            var dataRead = OmDecoder_dataRead_t()
            om_decoder_init_data_read(&dataRead, &indexRead)
            
            var error: OmError_t = ERROR_OK
            indexData.withUnsafeBytes({ indexData in
                /// Loop over data blocks and read compressed data chunks
                while om_decoder_next_data_read(decoder, &dataRead, indexData.baseAddress, indexRead.count, &error) {
                    self.prefetchData(offset: Int(dataRead.offset), count: Int(dataRead.count))
                }
            })
        }
    }*/
}

