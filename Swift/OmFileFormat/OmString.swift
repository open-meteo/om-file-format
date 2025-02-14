@_implementationOnly import struct OmFileFormatC.OmString64_t
import Foundation

/// A string type that guarantees UTF-8 storage for compatibility with C APIs
public struct OmString {
    // The raw UTF-8 bytes stored in an array
    private let storage: ContiguousArray<UInt8>

    // Needed for conformance with OmFileScalarDataTypeProtocol
    public init() {
        self.storage = []
    }

    public init(_ string: String) {
        self.storage = ContiguousArray(string.utf8)
    }

    /// Creates a string from an OmString64_t by copying the bytes
    init(_ omString: OmString64_t) {
        let buffer = UnsafeRawBufferPointer(
            start: omString.value,
            count: Int(omString.size)
        )
        self.storage = ContiguousArray(buffer)
    }
}

// MARK: - String Literal Convertible
extension OmString: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - Custom String Convertible
extension OmString: CustomStringConvertible {
    public var description: String {
        String(decoding: self.storage, as: UTF8.self)
    }
}

// MARK: - Equatable
extension OmString: Equatable {
    public static func == (lhs: OmString, rhs: OmString) -> Bool {
        return lhs.storage == rhs.storage
    }
}

// MARK: - C Interop
extension OmString {
    /// Provides temporary access to an OmString64_t representation without copying data
    func withOmString64<T>(_ body: ((inout OmString64_t)) throws -> T) rethrows -> T {
        try storage.withUnsafeBytes { buffer in
            var omString = OmString64_t(
                size: UInt64(storage.count),
                value: buffer.baseAddress!.assumingMemoryBound(to: CChar.self)
            )
            return try body(&omString)
        }
    }

    var byteCount: UInt64 {
        UInt64(self.storage.count)
    }
}
