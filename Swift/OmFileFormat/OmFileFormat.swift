@_implementationOnly import OmFileFormatC
import Foundation


public enum OmFileFormatSwiftError: Error {
    case cannotOpenFile(filename: String, errno: Int32, error: String)
    case cannotCreateFile(filename: String, errno: Int32, error: String)
    case cannotTruncateFile(filename: String, errno: Int32, error: String)
    case cannotOpenFile(errno: Int32, error: String)
    case cannotReadFile(errno: Int32, error: String)
    case chunkHasWrongNumberOfElements
    case dimensionOutOfBounds(range: Range<Int>, allowed: Int)
    case chunkDimensionIsSmallerThenOverallDim
    case dimensionMustBeLargerThan0
    case notAOmFile
    case fileExistsAlready(filename: String)
    case posixFallocateFailed(error: Int32)
    case ftruncateFailed(error: Int32)
    case omDecoder(error: String)
    case omEncoder(error: String)
    case notAnOpenMeteoFile
    case requireDimensionsToMatch(required: Int, actual: Int)
}


public enum DataType: UInt8, Codable {
    case none = 0
    case int8 = 1
    case uint8 = 2
    case int16 = 3
    case uint16 = 4
    case int32 = 5
    case uint32 = 6
    case int64 = 7
    case uint64 = 8
    case float = 9
    case double = 10
    case string = 11
    case int8_array = 12
    case uint8_array = 13
    case int16_array = 14
    case uint16_array = 15
    case int32_array = 16
    case uint32_array = 17
    case int64_array = 18
    case uint64_array = 19
    case float_array = 20
    case double_array = 21
    case string_array = 22

    func toC() -> OmDataType_t {
        return OmDataType_t(rawValue: UInt32(self.rawValue))
    }
}

public enum CompressionType: UInt8, Codable {
    /// Lossy compression using 2D delta coding and scalefactor. Only support float which are scaled to 16 bit signed integers
    case pfor_delta2d_int16 = 0

    /// Lossless compression using 2D xor coding for float and double values
    case fpx_xor2d = 1

    /// PFor integer compression. Floating point values are scaled to 32 bit signed integers. Doubles are scaled to 64 bit signed integers.
    case pfor_delta2d = 2

    /// Similar to `pfor_delta2d_int16` but applies `log10(1+x)` before
    case pfor_delta2d_int16_logarithmic = 3

    /// No compression, currently only supported for string data
    case none = 255

    func toC() -> OmCompression_t {
        switch self {
        case .pfor_delta2d_int16:
            return COMPRESSION_PFOR_DELTA2D_INT16
        case .fpx_xor2d:
            return COMPRESSION_FPX_XOR2D
        case .pfor_delta2d:
            return COMPRESSION_PFOR_DELTA2D
        case .pfor_delta2d_int16_logarithmic:
            return COMPRESSION_PFOR_DELTA2D_INT16_LOGARITHMIC
        case .none:
            return COMPRESSION_NONE
        }
    }
}
