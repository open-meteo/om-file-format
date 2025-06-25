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
            // Read data from root.offset by root.size. Important: data must remain accessible throughout the use of this variable!!
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

    public func asStringArray(io_size_max: UInt64 = 65536, io_size_merge: UInt64 = 512) async throws -> OmFileReaderStringArray<Backend>? {
        guard self.dataType == .string_array else {
            return nil
        }

        return try await OmFileReaderStringArray(
            fn: fn,
            variable: variable,
            io_size_max: io_size_max,
            io_size_merge: io_size_merge
        )
    }
}

/// Specialized reader for string arrays that handles variable-length strings with native decoding
public struct OmFileReaderStringArray<Backend: OmFileReaderBackend> {
    /// Points to the underlying memory
    public let fn: Backend
    let variable: Backend.DataType
    let io_size_max: UInt64
    let io_size_merge: UInt64

    let lutTable: [UInt64]

    init(fn: Backend, variable: Backend.DataType, io_size_max: UInt64, io_size_merge: UInt64) async throws {
        self.fn = fn
        self.variable = variable
        self.io_size_max = io_size_max
        self.io_size_merge = io_size_merge

        // Extract LUT information from the variable metadata
        let (lutOffset, lutSize) = variable.withUnsafeBytes { bytes in
            let variable = om_variable_init(bytes.baseAddress)

            // Check if this is actually a string array
            guard om_variable_get_type(variable) == DATA_TYPE_STRING_ARRAY else {
                fatalError("Variable is not a string array")
            }

            // Cast to the string array structure to access LUT information
            let stringArrayPtr = bytes.baseAddress!.assumingMemoryBound(to: OmVariableStringArrayV3_t.self)
            let meta = stringArrayPtr.pointee

            return (meta.lut_offset, meta.lut_size)
        }

        // Read the LUT from the file
        let lutData = try await fn.getData(offset: Int(lutOffset), count: Int(lutSize))
        let lutCount = Int(lutSize) / MemoryLayout<UInt64>.size

        self.lutTable = lutData.withUnsafeBytes { bytes in
            let lutBuffer = bytes.bindMemory(to: UInt64.self)
            return Array(UnsafeBufferPointer(start: lutBuffer.baseAddress, count: lutCount))
        }

        print("lutTable \(lutTable)")
    }

    /// Get the dimensions of the string array
    public func getDimensions() -> [UInt64] {
        return variable.withUnsafeBytes { bytes in
            let variable = om_variable_init(bytes.baseAddress)
            let dimensions = om_variable_get_dimensions(variable)
            return Array(UnsafeBufferPointer<UInt64>(start: dimensions.values, count: Int(dimensions.count)))
        }
    }

    /// Read the entire string array
    public func read() async throws -> [String] {
        let dimensions = self.getDimensions()
        let ranges = dimensions.map { 0..<$0 }
        return try await read(range: ranges)
    }

    /// Read a subset of the string array
    public func read(range: [Range<UInt64>]) async throws -> [String] {
        let dimensions = self.getDimensions().map { Int($0) }
        print("Dimensions \(dimensions)")
        let ranges = range.map { Range(uncheckedBounds: (Int($0.lowerBound), Int($0.upperBound))) }
        let totalCount = ranges.map { $0.count }.reduce(1, *)

        guard dimensions.count == ranges.count else {
            throw OmFileFormatSwiftError.omDecoder(error: "Dimension count mismatch")
        }

        var strings = [String]()
        strings.reserveCapacity(Int(totalCount))

        // We need to translate the array indices to linear indices
        // according to row-major order
        // Create array to hold current indices
        var currentIndices = ranges.map { $0.lowerBound }

        // Row-major iteration (leftmost dimension changes slowest)
        outer: while true {
            // Calculate linear index for current position
            var linearIndex = 0
            var multiplier = 1

            // Calculate linear index in row-major order (rightmost dimension is fastest)
            for (idx, dim) in dimensions.enumerated().reversed() {
                linearIndex += currentIndices[idx] * multiplier
                multiplier *= dim
            }

            // The LUT at the linear index contains the offset of the string
            // The next LUT entry contains the offset of the next string
            // The length of the string is the difference between the two offsets
            let startOffset = self.lutTable[Int(linearIndex)]
            let endOffset = self.lutTable[Int(linearIndex + 1)]

            // Process current position
            print("Read string at \(startOffset) - \(endOffset)")
            strings.append(try await self.readString(start: Int(startOffset), end: Int(endOffset)))

            // Increment indices starting from rightmost dimension
            for dimIdx in (0..<dimensions.count).reversed() {
                currentIndices[dimIdx] += 1
                if currentIndices[dimIdx] < ranges[dimIdx].upperBound {
                    break // If we haven't reached the end of this dimension, continue
                }
                if dimIdx == 0 {
                    break outer // If we've processed all dimensions, we're done
                }
                // Reset this dimension and continue to increment the next one
                currentIndices[dimIdx] = ranges[dimIdx].lowerBound
            }
        }

        return strings
    }

    /// Read a single string from the specified start and end offset
    public func readString(start: Int, end: Int) async throws -> String {
        if start == end {
            return "" // Empty string
        }

        let stringData = try await self.fn.getData(offset: start, count: end - start)

        return stringData.withUnsafeBytes { buffer in
            String(decoding: buffer, as: UTF8.self)
        }
    }
}
