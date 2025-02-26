//
//  OmFileDataTypeProtocol.swift
//  OpenMeteoApi
//
//  Created by Patrick Zippenfenig on 30.10.2024.
//

/// Allowed data types for reading and writing
public protocol OmFileArrayDataTypeProtocol {
    static var dataTypeArray: DataType { get }
}

extension Int8: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .int8_array
    }
}

extension UInt8: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .uint8_array
    }
}

extension Int16: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .int16_array
    }
}

extension UInt16: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .uint16_array
    }
}

extension Int32: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .int32_array
    }
}

extension UInt32: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .uint32_array
    }
}

extension Int: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .int64_array
    }
}

extension UInt: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .uint64_array
    }
}

extension Float: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .float_array
    }
}

extension Double: OmFileArrayDataTypeProtocol {
    public static var dataTypeArray: DataType {
        return .double_array
    }
}


public protocol OmFileScalarDataTypeProtocol {
    init(unsafeFrom: UnsafeRawBufferPointer)
    func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T
    static var dataTypeScalar: DataType { get }
}

extension Int8: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .int8
    }
}

extension UInt8: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .uint8
    }
}

extension Int16: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .int16
    }
}

extension UInt16: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .uint16
    }
}

extension Int32: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .int32
    }
}

extension UInt32: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .uint32
    }
}

extension Int: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .int64
    }
}

extension UInt: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .uint64
    }
}

extension Float: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .float
    }
}

extension Double: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return withUnsafeBytes(of: self, body)
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.bindMemory(to: Self.self)[0]
    }
    
    public static var dataTypeScalar: DataType {
        return .double
    }
}

extension UnsafeBufferPointer<CChar>: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        return body(UnsafeRawBufferPointer(self))
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = unsafeFrom.assumingMemoryBound(to: CChar.self)
    }
    
    public static var dataTypeScalar: DataType {
        return .string
    }
}

extension String: OmFileScalarDataTypeProtocol {
    public func withOmBytes<T>(body: (UnsafeRawBufferPointer) -> (T)) -> T {
        var copy: String = self
        return copy.withUTF8({
            return body(UnsafeRawBufferPointer($0))
        })
    }
    
    public init(unsafeFrom: UnsafeRawBufferPointer) {
        self = String.init(decoding: unsafeFrom, as: Unicode.UTF8.self)
    }
    
    public static var dataTypeScalar: DataType {
        return .string
    }
}
