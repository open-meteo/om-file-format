import struct OmFileFormatC.OmString64_t

extension OmFileFormatC.OmString64_t: Swift.CustomStringConvertible {
    public var description: String {
        // Create a String from the raw buffer with specified size
        return String(bytes: UnsafeRawBufferPointer(start: self.value, count: Int(self.size)), encoding: .utf8) ?? ""
    }
}

extension OmFileFormatC.OmString64_t: Swift.ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        // Get the UTF-8 representation of the string
        let utf8Data = Array(value.utf8)
        let size = UInt64(utf8Data.count)

        // Allocate memory that will persist
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: utf8Data.count)
        // Copy the string data into the buffer
        buffer.initialize(from: utf8Data, count: utf8Data.count)

        // Reinterpret the UInt8 pointer as CChar
        let charPtr = unsafeBitCast(buffer, to: UnsafePointer<CChar>.self)

        // Create OmString64_t with the size and pointer
        self.init(size: size, value: charPtr)
    }
}

extension OmFileFormatC.OmString64_t: Equatable {
    public static func == (lhs: OmFileFormatC.OmString64_t, rhs: OmFileFormatC.OmString64_t) -> Bool {
        guard lhs.size == rhs.size else { return false }

        let lhsString = String(bytes: UnsafeRawBufferPointer(start: lhs.value, count: Int(lhs.size)), encoding: .utf8)
        let rhsString = String(bytes: UnsafeRawBufferPointer(start: rhs.value, count: Int(rhs.size)), encoding: .utf8)

        return lhsString == rhsString
    }
}
