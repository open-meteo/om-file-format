//
//  OmFileWriter2.swift
//  OpenMeteoApi
//
//  Created by Patrick Zippenfenig on 29.10.2024.
//

import Foundation
@_implementationOnly import OmFileFormatC


/// Writes om file header and trailer
public struct OmFileWriter<FileHandle: OmFileWriterBackend> {
    let buffer: OmBufferedWriter<FileHandle>

    public init(fn: FileHandle, initialCapacity: Int) {
        self.buffer = OmBufferedWriter(backend: fn, initialCapacity: initialCapacity)
    }

    public func writeHeaderIfRequired() throws {
        if buffer.totalBytesWritten > 0 {
            return
        }
        /// Write header
        let size = om_header_write_size()
        try buffer.reallocate(minimumCapacity: size)
        om_header_write(buffer.bufferAtWritePosition)
        buffer.incrementWritePosition(by: size)
    }

    public func write<OmType: OmFileScalarDataTypeProtocol>(value: OmType, name: String, children: [OmOffsetSize]) throws -> OmOffsetSize {
        try writeHeaderIfRequired()
        var name = name
        return try name.withUTF8{ name in
            guard name.count <= UInt16.max else { fatalError() }
            guard children.count <= UInt32.max else { fatalError() }
            let type = OmType.dataTypeScalar.toC()
            try buffer.alignTo8Bytes()

            let stringLength: UInt64
            if type == DATA_TYPE_STRING {
                // For strings, pass the string length
                stringLength = UInt64((value as! String).utf8.count) // TODO: safely init?
            } else {
                stringLength = 0
            }
            let size = om_variable_write_scalar_size(
                UInt16(name.count),
                UInt32(children.count),
                type,
                stringLength
            )

            let offset = UInt64(buffer.totalBytesWritten)
            try buffer.reallocate(minimumCapacity: Int(size))
            var value = value
            withUnsafePointer(to: &value, { value in
                let childrenOffsets = children.map {$0.offset}
                let childrenSizes = children.map {$0.size}
                om_variable_write_scalar(
                    buffer.bufferAtWritePosition,
                    UInt16(name.count),
                    UInt32(children.count),
                    childrenOffsets,
                    childrenSizes,
                    name.baseAddress,
                    type,
                    value,
                    stringLength
                )
            })
            buffer.incrementWritePosition(by: size)
            return OmOffsetSize(offset: offset, size: UInt64(size))
        }
    }

    public func prepareArray<OmType: OmFileArrayDataTypeProtocol>(type: OmType.Type, dimensions: [UInt64], chunkDimensions: [UInt64], compression: CompressionType, scale_factor: Float, add_offset: Float) throws -> OmFileWriterArray<OmType, FileHandle> {
        try writeHeaderIfRequired()
        return try .init(dimensions: dimensions, chunkDimensions: chunkDimensions, compression: compression, scale_factor: scale_factor, add_offset: add_offset, buffer: buffer)
    }

    public func prepareStringArray(dimensions: [UInt64]) throws -> OmFileWriterStringArray<FileHandle> {
        try writeHeaderIfRequired()
        return .init(dimensions: dimensions, buffer: buffer)
    }

    public func write(array: OmFileWriterArrayFinalised, name: String, children: [OmOffsetSize]) throws -> OmOffsetSize {
        try writeHeaderIfRequired()
        guard array.dimensions.count == array.chunks.count else {
            fatalError()
        }
        var name = name
        return try name.withUTF8{ name in
            guard name.count <= UInt16.max else { fatalError() }
            try buffer.alignTo8Bytes()
            let size = om_variable_write_numeric_array_size(UInt16(name.count), UInt32(children.count), UInt64(array.dimensions.count))
            let offset = UInt64(buffer.totalBytesWritten)
            try buffer.reallocate(minimumCapacity: Int(size))
            let childrenOffsets = children.map {$0.offset}
            let childrenSizes = children.map {$0.size}
            om_variable_write_numeric_array(buffer.bufferAtWritePosition, UInt16(name.count), UInt32(children.count), childrenOffsets, childrenSizes, name.baseAddress, array.datatype.toC(), array.compression.toC(), array.scale_factor, array.add_offset, UInt64(array.dimensions.count), array.dimensions, array.chunks, UInt64(array.lutSize), UInt64(array.lutOffset))
            buffer.incrementWritePosition(by: size)
            return OmOffsetSize(offset: offset, size: UInt64(size))
        }
    }

    public func writeTrailer(rootVariable: OmOffsetSize) throws {
        try writeHeaderIfRequired()
        try buffer.alignTo8Bytes()

        // write length of JSON
        let size = om_trailer_size()
        try buffer.reallocate(minimumCapacity: size)
        om_trailer_write(buffer.bufferAtWritePosition, rootVariable.offset, rootVariable.size)
        buffer.incrementWritePosition(by: size)

        // Flush
        try buffer.writeToFile()
    }
}

/// Compress a single variable inside an om file. A om file may contain multiple variables
public final class OmFileWriterArray<OmType: OmFileArrayDataTypeProtocol, FileHandle: OmFileWriterBackend> {
    /// Store all byte offsets where our compressed chunks start. Later, we want to decompress chunk 1234 and know it starts at byte offset 5346545
    private var lookUpTable: [UInt64]

    private var encoder: OmEncoder_t

    /// Position of last chunk that has been written
    var chunkIndex: Int = 0

    /// The scalefactor that is applied to all write data
    let scale_factor: Float

    /// The offset that is applied to all write data
    let add_offset: Float

    /// Type of compression and coding. E.g. delta, zigzag coding is then implemented in different compression routines
    let compression: CompressionType

    /// The dimensions of the file
    let dimensions: [UInt64]

    /// How the dimensions are chunked
    let chunks: [UInt64]

    let compressedChunkBufferSize: UInt64

    let chunkBuffer: UnsafeMutableRawBufferPointer

    /// Temporarily write data here. Keeps also track of `totalBytesWritten`
    let buffer: OmBufferedWriter<FileHandle>


    public init(dimensions: [UInt64], chunkDimensions: [UInt64], compression: CompressionType, scale_factor: Float, add_offset: Float, buffer: OmBufferedWriter<FileHandle>) throws {

        assert(dimensions.count == chunkDimensions.count)

        self.chunks = chunkDimensions
        self.dimensions = dimensions
        self.compression = compression
        self.scale_factor = scale_factor
        self.add_offset = add_offset

        if OmType.dataTypeArray == .string_array {
            // string arrays need to have chunk dimensions of 1
            if !chunkDimensions.allSatisfy({ $0 == 1 }) {
                throw OmFileFormatSwiftError.omEncoder(error: "String arrays need to have chunk dimensions of 1")
            }
        }

        // Note: The encoder keeps the pointer to `&self.dimensions`. It is important that this array is not deallocated!
        self.encoder = OmEncoder_t()
        let error = om_encoder_init(&encoder, scale_factor, add_offset, compression.toC(), OmType.dataTypeArray.toC(), &self.dimensions, &self.chunks, UInt64(dimensions.count))

        guard error == ERROR_OK else {
            throw OmFileFormatSwiftError.omEncoder(error: String(cString: om_error_string(error)))
        }

        /// Number of total chunks in the compressed files
        let nChunks = om_encoder_count_chunks(&encoder)

        /// This is the minimum output buffer size for each compressed size. In practice the buffer should be much larger.
        self.compressedChunkBufferSize = om_encoder_compressed_chunk_buffer_size(&encoder)

        let chunkBufferSize = om_encoder_chunk_buffer_size(&encoder)

        /// Each thread needs its own chunk buffer to compress data. This implementation is single threaded
        self.chunkBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(chunkBufferSize), alignment: 1)
        chunkBuffer.initializeMemory(as: UInt8.self, repeating: 0)

        /// Allocate space for a lookup table. Needs to be number_of_chunks+1 to store start address and for each chunk then end address
        self.lookUpTable = .init(repeating: 0, count: Int(nChunks) + 1)

        self.buffer = buffer
    }

    /// Compress data and write it to file. Can be all, a single or multiple chunks. If multiple chunks are given at once, they must align with chunks.
    /// `arrayDimensions` specify the total dimensions of the input array
    /// `arrayRead` specify which parts of this array should be read
    /// It is important that this function can write data out to a FileHandle to empty the buffer. Otherwise the buffer could grow to multiple gigabytes
    public func writeData(array: [OmType], arrayDimensions: [UInt64]? = nil, arrayOffset: [UInt64]? = nil, arrayCount: [UInt64]? = nil) throws {
        try array.withUnsafeBufferPointer { array in
            try writeData(pointer: array, arrayDimensions: arrayDimensions, arrayOffset: arrayOffset, arrayCount: arrayCount)
        }
    }

    /// Compress data and write it to file. Can be all, a single or multiple chunks. If multiple chunks are given at once, they must align with chunks.
    /// `arrayDimensions` specify the total dimensions of the input array
    /// `arrayRead` specify which parts of this array should be read
    /// It is important that this function can write data out to a FileHandle to empty the buffer. Otherwise the buffer could grow to multiple gigabytes
    public func writeData(pointer: UnsafeBufferPointer<OmType>, arrayDimensions: [UInt64]? = nil, arrayOffset: [UInt64]? = nil, arrayCount: [UInt64]? = nil) throws {
        let arrayDimensions = arrayDimensions ?? self.dimensions
        let arrayCount = arrayCount ?? arrayDimensions
        let arrayOffset = arrayOffset ?? [UInt64](repeating: 0, count: arrayDimensions.count)

        assert(pointer.count == arrayDimensions.reduce(1, *))
        assert(arrayDimensions.allSatisfy({$0 >= 0}))
        assert(arrayOffset.allSatisfy({$0 >= 0}))
        assert(zip(arrayDimensions, zip(arrayOffset, arrayCount)).allSatisfy { $1.0 + $1.1 <= $0 })

        /// For performance the output buffer should be able to hold a multiple of the chunk buffer size
        try buffer.reallocate(minimumCapacity: Int(compressedChunkBufferSize) * 4)

        /// How many chunks can be written to the output. This could be only a single one, or multiple
        let numberOfChunksInArray = om_encoder_count_chunks_in_array(&encoder, arrayCount)

        // Store data start address if this is the first time this read is called
        if self.chunkIndex == 0 {
            lookUpTable[chunkIndex] = UInt64(buffer.totalBytesWritten)
        }

        // This loop could be done in parallel. However, the order of chunks must remain the same in the LUT and final output buffer.
        // For multithreading, multiple buffers are required that need to be copied into the final buffer afterwards
        for chunkIndexOffsetInThisArray in 0..<numberOfChunksInArray {
            try buffer.reallocate(minimumCapacity: Int(compressedChunkBufferSize))

            let bytes_written = om_encoder_compress_chunk(
                &encoder,
                pointer.baseAddress,
                arrayDimensions,
                arrayOffset,
                arrayCount,
                UInt64(chunkIndex),
                chunkIndexOffsetInThisArray,
                buffer.bufferAtWritePosition,
                chunkBuffer.baseAddress
            )

            buffer.incrementWritePosition(by: Int(bytes_written))

            // Store chunk offset in LUT
            lookUpTable[chunkIndex+1] = UInt64(buffer.totalBytesWritten)
            chunkIndex += 1
        }
    }

    /// Compress the lookup table and write it to the output buffer
    public func finalise() throws -> OmFileWriterArrayFinalised {
        let lut_offset = buffer.totalBytesWritten

        /// The size of the total compressed LUT including some padding
        let buffer_size = om_encoder_lut_buffer_size(lookUpTable, UInt64(lookUpTable.count))
        try buffer.reallocate(minimumCapacity: Int(buffer_size))

        /// Compress the LUT and return the actual compressed LUT size
        let compressed_lut_size = om_encoder_compress_lut(lookUpTable, UInt64(lookUpTable.count), buffer.bufferAtWritePosition, buffer_size)
        buffer.incrementWritePosition(by: Int(compressed_lut_size))
        return OmFileWriterArrayFinalised(
            scale_factor: scale_factor,
            add_offset: add_offset,
            compression: compression,
            datatype: OmType.dataTypeArray,
            dimensions: dimensions,
            chunks: chunks,
            lutSize: compressed_lut_size,
            lutOffset: UInt64(lut_offset)
        )
    }

    deinit {
        chunkBuffer.deallocate()
    }
}

/// Attributes of an compressed array that had been written and now contains LUT size and offset
public struct OmFileWriterArrayFinalised {
    /// The scale-factor that is applied to all write data
    let scale_factor: Float

    /// The offset that is applied to all write data
    let add_offset: Float

    /// Type of compression and coding. E.g. delta, zigzag coding is then implemented in different compression routines
    let compression: CompressionType

    let datatype: DataType

    /// The dimensions of the file
    let dimensions: [UInt64]

    /// How the dimensions are chunked
    let chunks: [UInt64]

    let lutSize: UInt64

    let lutOffset: UInt64
}

/// Specialized string array writer
public final class OmFileWriterStringArray<FileHandle: OmFileWriterBackend> {
    private var lookUpTable: [UInt64]
    private var currentPosition: UInt64
    private let buffer: OmBufferedWriter<FileHandle>
    private let dimensions: [UInt64]

    public init(dimensions: [UInt64], buffer: OmBufferedWriter<FileHandle>) {
        self.dimensions = dimensions
        let numberOfStrings = dimensions.reduce(1, *)
        // Allocate space for a lookup table.
        // Needs to be numberOfStrings+1 to store start of first string
        // as first element and for each string then the end address
        self.lookUpTable = .init(repeating: 0, count: Int(numberOfStrings + 1))
        self.currentPosition = 0
        self.buffer = buffer
    }

    /// Write all strings at once. The array must match the dimensions
    public func writeData(array: [String]) throws {
        // Verify array size matches dimensions
        let expectedSize = dimensions.reduce(1, *)
        guard array.count == expectedSize && self.currentPosition == 0 else {
            throw OmFileFormatSwiftError.omEncoder(error: "String arrays need to be encoded all at once and must match the dimensions")
        }

        // Store data start address if this is the first time this read is called
        let lutOffset = UInt64(buffer.totalBytesWritten)
        if self.currentPosition == 0 {
            lookUpTable[0] = lutOffset
        }

        // Pre-calculate total required capacity
        let totalCapacity = array.reduce(0) { $0 + $1.utf8.count }
        try buffer.reallocate(minimumCapacity: totalCapacity)

        // Write all strings consecutively
        for (i, string) in array.enumerated() {
            string.utf8.withContiguousStorageIfAvailable { utf8 in
                buffer.bufferAtWritePosition.advanced(by: Int(self.currentPosition))
                    .copyMemory(from: utf8.baseAddress!, byteCount: utf8.count)
                self.currentPosition += UInt64(utf8.count)
                lookUpTable[i+1] = lutOffset + self.currentPosition
            }
        }

        buffer.incrementWritePosition(by: Int(self.currentPosition))
    }

    public func finalise() throws -> OmFileWriterArrayFinalised {
        try buffer.alignTo8Bytes()
        let lutOffset = buffer.totalBytesWritten

        // Write uncompressed LUT
        let lutSize = Int(lookUpTable.count * MemoryLayout<UInt64>.size)
        try buffer.reallocate(minimumCapacity: lutSize)
        buffer.bufferAtWritePosition.copyMemory(from: self.lookUpTable, byteCount: lutSize)
        buffer.incrementWritePosition(by: lutSize)

        return OmFileWriterArrayFinalised(
            scale_factor: 0,
            add_offset: 0,
            compression: .none,
            datatype: .string_array,
            dimensions: dimensions,
            chunks: dimensions.map { _ in 1 },  // one string per chunk
            lutSize: UInt64(lutSize),
            lutOffset: UInt64(lutOffset)
        )
    }
}

/// Wrapper for the internal C structure to keep offset and size
public struct OmOffsetSize {
    let offset: UInt64
    let size: UInt64

    init(offset: UInt64, size: UInt64) {
        self.offset = offset
        self.size = size
    }
}
