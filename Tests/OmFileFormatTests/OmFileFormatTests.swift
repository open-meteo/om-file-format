import Testing
import Foundation
@testable import OmFileFormat
@_implementationOnly import OmFileFormatC

@Suite struct OmFileFormatTests {
    @Test func headerAndTrailer() {
        #expect(om_header_size() == 40)
        #expect(om_trailer_size() == 24)
        #expect(om_header_write_size() == 3)
        
        #expect(om_header_type([UInt8(79), 77, 3]) == OM_HEADER_READ_TRAILER)
        #expect(om_header_type([UInt8(79), 77, 1]) == OM_HEADER_LEGACY)
        #expect(om_header_type([UInt8(79), 77, 2]) == OM_HEADER_LEGACY)
        #expect(om_header_type([UInt8(77), 77, 3]) == OM_HEADER_INVALID)
        
        var size: UInt64 = 0
        var offset: UInt64 = 0
        #expect(om_trailer_read([UInt8(79), 77, 3, 0, 0, 0, 0, 0, 88, 0, 0, 0, 0, 0, 0, 0, 124, 0, 0, 0, 0, 0, 0, 0], &offset, &size))
        #expect(size == 124)
        #expect(offset == 88)
        
        #expect(!om_trailer_read([UInt8(77), 77, 3, 0, 0, 0, 0, 0, 88, 0, 0, 0, 0, 0, 0, 0, 124, 0, 0, 0, 0, 0, 0, 0], &offset, &size))
        
        var header = [UInt8](repeating: 255, count: om_header_write_size())
        om_header_write(&header)
        #expect(om_header_type(header) == OM_HEADER_READ_TRAILER)
        #expect(header == [79, 77, 3])
        
        var trailer = [UInt8](repeating: 255, count: om_trailer_size())
        om_trailer_write(&trailer, 634764573452346, 45673452346)
        #expect(om_trailer_read(trailer, &offset, &size))
        #expect(size == 45673452346)
        #expect(offset == 634764573452346)
        #expect(trailer == [79, 77, 3, 0, 0, 0, 0, 0, 58, 168, 234, 164, 80, 65, 2, 0, 58, 147, 89, 162, 10, 0, 0, 0])
    }
    
    @Test func variable() {
        var name = "name"
        name.withUTF8({ name in
            let sizeScalar = om_variable_write_scalar_size(UInt16(name.count), 0, DATA_TYPE_INT8)
            #expect(sizeScalar == 13)
            
            var data = [UInt8](repeating: 255, count: sizeScalar)
            var value = UInt8(177)
            om_variable_write_scalar(&data, UInt16(name.count), 0, nil, nil, name.baseAddress, DATA_TYPE_INT8, &value)
            #expect(data == [1, 4, 4, 0, 0, 0, 0, 0, 177, 110, 97, 109, 101])
            
            let omvariable = om_variable_init(data)
            #expect(om_variable_get_type(omvariable) == DATA_TYPE_INT8)
            #expect(om_variable_get_children_count(omvariable) == 0)
            var valueOut = UInt8(255)
            #expect(om_variable_get_scalar(omvariable, &valueOut) == ERROR_OK)
            #expect(valueOut == 177)
        })
    }
    
    @Test func inMemory() throws {
        let data: [Float] = [0.0, 5.0, 2.0, 3.0, 2.0, 5.0, 6.0, 2.0, 8.0, 3.0, 10.0, 14.0, 12.0, 15.0, 14.0, 15.0, 66.0, 17.0, 12.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0]
        let compressed = try OmFileWriter(dim0: 1, dim1: data.count, chunk0: 1, chunk1: 10).writeInMemory(compressionType: .p4nzdec256, scalefactor: 1, all: data)
        #expect(compressed.count == 212)
        let uncompressed = try OmFileReader(fn: DataAsClass(data: compressed)).readAll()
        #expect(data == uncompressed)
    }
    
    /// Make sure the last chunk has the correct number of chunks
    @Test func writeMoreDataThenExpected() throws {
        let file = "writeMoreDataThenExpected.om"
        try FileManager.default.removeItemIfExists(at: file)
        #expect(throws: (any Error).self) { try OmFileWriter(dim0: 5, dim1: 5, chunk0: 2, chunk1: 2).write(file: file, compressionType: .p4nzdec256, scalefactor: 1, overwrite: false, supplyChunk: { dim0pos in
            if dim0pos == 0 {
                return ArraySlice((0..<10).map({ Float($0) }))
            }
            if dim0pos == 2 {
                return ArraySlice((10..<20).map({ Float($0) }))
            }
            if dim0pos == 4 {
                // Here it is now 30 instead of 25
                return ArraySlice((20..<30).map({ Float($0) }))
            }
            fatalError("Not expected")
        }) }
        try FileManager.default.removeItem(atPath: "\(file)~")
    }
    
    @Test func writeLarge() throws {
        let file = "writeLarge.om"
        try FileManager.default.removeItemIfExists(at: file)
        let fn = try FileHandle.createNewFile(file: file)
        
        let fileWriter = OmFileWriter2(fn: fn, initialCapacity: 8)
        let writer = try fileWriter.prepareArray(type: Float.self, dimensions: [100,100,10], chunkDimensions: [2,2,2], compression: .p4nzdec256, scale_factor: 1, add_offset: 0)
        
        let data = (0..<100000).map({Float($0 % 10000)})
        try writer.writeData(array: data)
        let variableMeta = try writer.finalise()
        let variable = try fileWriter.write(array: variableMeta, name: "data", children: [])
        try fileWriter.writeTrailer(rootVariable: variable)
        
        let readFn = try MmapFile(fn: FileHandle.openFileReading(file: file))
        let read = try OmFileReader2(fn: readFn).asArray(of: Float.self)!
        
        let a1 = try read.read(range: [50..<51, 20..<21, 1..<2])
        #expect(a1 == [201.0])
                
        let a = try read.read(range: [0..<100, 0..<100, 0..<10])
        #expect(a == data)
        
        #expect(readFn.count == 154176)
        //let hex = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: readFn.getData(offset: 0, count: readFn.count)), count: readFn.count, deallocator: .none)
        //XCTAssertEqual(hex, "awfawf")
        
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func writeChunks() throws {
        let file = "writeChunks.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let fn = try FileHandle.createNewFile(file: file)
        let fileWriter = OmFileWriter2(fn: fn, initialCapacity: 8)
        
        let writer = try fileWriter.prepareArray(type: Float.self, dimensions: [5,5], chunkDimensions: [2,2], compression: .p4nzdec256, scale_factor: 1, add_offset: 0)
        
        // Directly feed individual chunks
        try writer.writeData(array: [0.0, 1.0, 5.0, 6.0], arrayDimensions: [2,2])
        try writer.writeData(array: [2.0, 3.0, 7.0, 8.0], arrayDimensions: [2,2])
        try writer.writeData(array: [4.0, 9.0], arrayDimensions: [2,1])
        try writer.writeData(array: [10.0, 11.0, 15.0, 16.0], arrayDimensions: [2,2])
        try writer.writeData(array: [12.0, 13.0, 17.0, 18.0], arrayDimensions: [2,2])
        try writer.writeData(array: [14.0, 19.0], arrayDimensions: [2,1])
        try writer.writeData(array: [20.0, 21.0], arrayDimensions: [1,2])
        try writer.writeData(array: [22.0, 23.0], arrayDimensions: [1,2])
        try writer.writeData(array: [24.0], arrayDimensions: [1,1])
        let variableMeta = try writer.finalise()
        let variable = try fileWriter.write(array: variableMeta, name: "data", children: [])
        try fileWriter.writeTrailer(rootVariable: variable)
        
        let readFn = try MmapFile(fn: FileHandle.openFileReading(file: file))
        let read = try OmFileReader2(fn: readFn).asArray(of: Float.self)!
        
        let a = try read.read(range: [0..<5, 0..<5])
        #expect(a == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0])
        
        #expect(readFn.count == 144)
        //let bytes = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: readFn.getData(offset: 0, count: readFn.count)), count: readFn.count, deallocator: .none).map{UInt8($0)}
        // difference on x86 and ARM cause by the underlying compression
        //XCTAssertTrue(bytes == [79, 77, 3, 0, 4, 130, 0, 2, 3, 34, 0, 4, 194, 2, 10, 4, 178, 0, 12, 4, 242, 0, 14, 197, 17, 20, 194, 2, 22, 194, 2, 24, 3, 3, 228, 200, 109, 1, 0, 0, 20, 0, 4, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 100, 97, 116, 97, 0, 0, 0, 0, 79, 77, 3, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 76, 0, 0, 0, 0, 0, 0, 0] || bytes == [79, 77, 3, 0, 4, 130, 64, 2, 3, 34, 16, 4, 194, 2, 10, 4, 178, 64, 12, 4, 242, 64, 14, 197, 17, 20, 194, 2, 22, 194, 2, 24, 3, 3, 228, 200, 109, 1, 0, 0, 20, 0, 4, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 100, 97, 116, 97, 0, 0, 0, 0, 79, 77, 3, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 76, 0, 0, 0, 0, 0, 0, 0])
        
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func offsetWrite() throws {
        let file = "offsetWrite.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let fn = try FileHandle.createNewFile(file: file)
        let fileWriter = OmFileWriter2(fn: fn, initialCapacity: 8)
        
        let writer = try fileWriter.prepareArray(type: Float.self, dimensions: [5,5], chunkDimensions: [2,2], compression: .p4nzdec256, scale_factor: 1, add_offset: 0)
        
        /// Deliberately add NaN on all positions that should not be written to the file. Only the inner 5x5 array is written
        let data = [.nan, .nan, .nan, .nan, .nan, .nan, .nan, .nan, Float(0.0), 1.0, 2.0, 3.0, 4.0, .nan, .nan, 5.0, 6.0, 7.0, 8.0, 9.0, .nan, .nan, 10.0, 11.0, 12.0, 13.0, 14.0, .nan, .nan, 15.0, 16.0, 17.0, 18.0, 19.0, .nan, .nan, 20.0, 21.0, 22.0, 23.0, 24.0, .nan, .nan, .nan, .nan, .nan, .nan, .nan, .nan]
        try writer.writeData(array: data, arrayDimensions: [7,7], arrayOffset: [1, 1], arrayCount: [5, 5])
        
        let variableMeta = try writer.finalise()
        let variable = try fileWriter.write(array: variableMeta, name: "data", children: [])
        try fileWriter.writeTrailer(rootVariable: variable)
        
        let readFn = try MmapFile(fn: FileHandle.openFileReading(file: file))
        let readFile = try OmFileReader2(fn: readFn)
        let read = readFile.asArray(of: Float.self)!
        #expect(readFile.dataType == .float_array)
        #expect(read.compression == .p4nzdec256)
        #expect(read.scaleFactor == 1)
        #expect(read.addOffset == 0)
        #expect(read.getDimensions().count == 2)
        #expect(read.getDimensions()[0] == 5)
        #expect(read.getDimensions()[1] == 5)
        #expect(read.getChunkDimensions()[0] == 2)
        #expect(read.getChunkDimensions()[1] == 2)
        
        let a = try read.read(range: [0..<5, 0..<5])
        #expect(a == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0])
        
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func write3D() throws {
        let file = "write3D.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let dims = [UInt64(3),3,3]
        let data = [Float(0.0), 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0]
        
        let fn = try FileHandle.createNewFile(file: file)
        let fileWriter = OmFileWriter2(fn: fn, initialCapacity: 8)
        
        let writer = try fileWriter.prepareArray(type: Float.self, dimensions: dims, chunkDimensions: [2,2,2], compression: .p4nzdec256, scale_factor: 1, add_offset: 0)
        try writer.writeData(array: data)
        let variableMeta = try writer.finalise()
        
        let int32Attribute = try fileWriter.write(value: Int32(12323154), name: "int32", children: [])
        let doubleAttribute = try fileWriter.write(value: Double(12323154), name: "double", children: [])
        let variable = try fileWriter.write(array: variableMeta, name: "data", children: [int32Attribute, doubleAttribute])
        
        try fileWriter.writeTrailer(rootVariable: variable)
        
        let readFn = try MmapFile(fn: FileHandle.openFileReading(file: file))
        let readFile = try OmFileReader2(fn: readFn)
        let read = readFile.asArray(of: Float.self)!
        
        #expect(readFile.numberOfChildren == 2)
        let child = readFile.getChild(0)!
        #expect(child.readScalar() == Int32(12323154))
        #expect(child.getName() == "int32")
        let child2 = readFile.getChild(1)!
        #expect(child2.readScalar() == Double(12323154))
        #expect(child2.getName() == "double")
        #expect(readFile.getChild(2) == nil)
        
        let a = try read.read(range: [0..<3, 0..<3, 0..<3])
        #expect(a == data)
        
        // single index
        for x in 0..<dims[0] {
            for y in 0..<dims[1] {
                for z in 0..<dims[2] {
                    #expect(try read.read(range: [x..<x+1, y..<y+1, z..<z+1]) == [Float(x*3*3 + y*3 + z)])
                }
            }
        }
        
        // Ensure written bytes are correct
        #expect(readFn.count == 240)
        let bytes = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: readFn.getData(offset: 0, count: readFn.count)), count: readFn.count, deallocator: .none).map{UInt8($0)}
        #expect(bytes[0..<3] == [79, 77, 3])
        #expect(bytes[3..<8] == [0, 3, 34, 140, 2]) // chunk // chunk
        #expect(bytes[8..<12] == [2, 3, 114, 1] || bytes[8..<12] == [2, 3, 114, 141]) // difference on x86 and ARM cause by the underlying compression // difference on x86 and ARM cause by the underlying compression
        #expect(bytes[12..<16] == [6, 3, 34, 0] || bytes[12..<16] == [6, 3, 34, 140]) // chunk // chunk
        #expect(bytes[16..<19] == [8, 194, 2]) // chunk // chunk
        #expect(bytes[19..<23] == [18, 5, 226, 3]) // chunk // chunk
        #expect(bytes[23..<26] == [20, 198, 33]) // chunk // chunk
        #expect(bytes[26..<29] == [24, 194, 2]) // chunk // chunk
        #expect(bytes[29..<30] == [26]) // chunk // chunk
        #expect(bytes[30..<35] == [3, 3, 37, 199, 45]) // lut // lut
        #expect(bytes[35..<40] == [0, 0, 0, 0, 0]) // zero padding // zero padding
        #expect(bytes[40..<40+17] == [5, 4, 5, 0, 0, 0, 0, 0, 82, 9, 188, 0, 105, 110, 116, 51, 50]) // scalar int32 // scalar int32
        #expect(bytes[65..<65+22] == [4, 6, 0, 0, 0, 0, 0, 0, 0, 0, 64, 42, 129, 103, 65, 100, 111, 117, 98, 108, 101, 0]) // scalar double // scalar double
        #expect(bytes[88..<88+124] == [20, 0, 4, 0, 2, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 100, 97, 116, 97]) // array meta // array meta
        #expect(bytes[216..<240] == [79, 77, 3, 0, 0, 0, 0, 0, 88, 0, 0, 0, 0, 0, 0, 0, 124, 0, 0, 0, 0, 0, 0, 0]) // trailer // trailer
        
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func writev3() throws {
        let file = "writev3.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let dims = [UInt64(5),5]
        let fn = try FileHandle.createNewFile(file: file)
        let fileWriter = OmFileWriter2(fn: fn, initialCapacity: 8)
        
        let writer = try fileWriter.prepareArray(type: Float.self, dimensions: dims, chunkDimensions: [2,2], compression: .p4nzdec256, scale_factor: 1, add_offset: 0)
        
        let data = [Float(0.0), 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0]
        try writer.writeData(array: data)
        let variableMeta = try writer.finalise()
        let variable = try fileWriter.write(array: variableMeta, name: "data", children: [])
        try fileWriter.writeTrailer(rootVariable: variable)
        
        let readFn = try MmapFile(fn: FileHandle.openFileReading(file: file))
        let read = try OmFileReader2(fn: readFn).asArray(of: Float.self)!
        

        let a = try read.read(range: [0..<5, 0..<5])
        #expect(a == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0])
        
        // single index
        for x in 0..<dims[0] {
            for y in 0..<dims[1] {
                #expect(try read.read(range: [x..<x+1, y..<y+1]) == [Float(x*5 + y)])
            }
        }
        
        // Read into an existing array with an offset
        for x in 0..<dims[0] {
            for y in 0..<dims[1] {
                var r = [Float](repeating: .nan, count: 9)
                try r.withUnsafeMutableBufferPointer({
                    try read.read(into: $0.baseAddress!, range: [x..<x+1, y..<y+1], intoCubeOffset: [1,1], intoCubeDimension: [3,3])
                })
                #expect(r == [.nan, .nan, .nan, .nan, Float(x*5 + y), .nan, .nan, .nan, .nan])
            }
        }
        
        // 2x in fast dim
        for x in 0..<dims[0] {
            for y in 0..<dims[1]-1 {
                #expect(try read.read(range: [x..<x+1, y..<y+2]) == [Float(x*5 + y), Float(x*5 + y + 1)])
            }
        }
        
        // 2x in slow dim
        for x in 0..<dims[0]-1 {
            for y in 0..<dims[1] {
                #expect(try read.read(range: [x..<x+2, y..<y+1]) == [Float(x*5 + y), Float((x+1)*5 + y)])
            }
        }
        
        // 2x2
        for x in 0..<dims[0]-1 {
            for y in 0..<dims[1]-1 {
                #expect(try read.read(range: [x..<x+2, y..<y+2]) == [Float(x*5 + y), Float(x*5 + y + 1), Float((x+1)*5 + y), Float((x+1)*5 + y + 1)])
            }
        }
        // 3x3
        for x in 0..<dims[0]-2 {
            for y in 0..<dims[1]-2 {
                #expect(try read.read(range: [x..<x+3, y..<y+3]) == [Float(x*5 + y), Float(x*5 + y + 1), Float(x*5 + y + 2), Float((x+1)*5 + y), Float((x+1)*5 + y + 1),  Float((x+1)*5 + y + 2), Float((x+2)*5 + y), Float((x+2)*5 + y + 1),  Float((x+2)*5 + y + 2)])
            }
        }
        
        // 1x5
        for x in 0..<dims[1] {
            #expect(try read.read(range: [x..<x+1, 0..<5]) == [Float(x*5), Float(x*5+1), Float(x*5+2), Float(x*5+3), Float(x*5+4)])
        }
        
        // 5x1
        for x in 0..<dims[0] {
            #expect(try read.read(range: [0..<5, x..<x+1]) == [Float(x), Float(x+5), Float(x+10), Float(x+15), Float(x+20)])
        }
        
        #expect(readFn.count == 144)
        let bytes = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: readFn.getData(offset: 0, count: readFn.count)), count: readFn.count, deallocator: .none).map{UInt8($0)}
        #expect(bytes == [79, 77, 3, 0, 4, 130, 0, 2, 3, 34, 0, 4, 194, 2, 10, 4, 178, 0, 12, 4, 242, 0, 14, 197, 17, 20, 194, 2, 22, 194, 2, 24, 3, 3, 228, 200, 109, 1, 0, 0, 20, 0, 4, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 100, 97, 116, 97, 0, 0, 0, 0, 79, 77, 3, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 76, 0, 0, 0, 0, 0, 0, 0])
        
        /*// test interpolation
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.5, dim0Y: 0, dim0YFraction: 0.5, dim0Nx: 2, dim1: 0..<5), [7.5, 8.5, 9.5, 10.5, 11.5], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.1, dim0Y: 0, dim0YFraction: 0.2, dim0Nx: 2, dim1: 0..<5), [2.5, 3.4999998, 4.5, 5.5, 6.5], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.9, dim0Y: 0, dim0YFraction: 0.2, dim0Nx: 2, dim1: 0..<5), [6.5, 7.5, 8.5, 9.5, 10.5], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.1, dim0Y: 0, dim0YFraction: 0.9, dim0Nx: 2, dim1: 0..<5), [9.5, 10.499999, 11.499999, 12.5, 13.499999], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.8, dim0Y: 0, dim0YFraction: 0.9, dim0Nx: 2, dim1: 0..<5), [12.999999, 14.0, 15.0, 16.0, 17.0], accuracy: 0.001)*/
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func writev3MaxIOLimit() throws {
        let file = "writev3MaxIOLimit.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let dims = [UInt64(5),5]
        let fn = try FileHandle.createNewFile(file: file)
        let fileWriter = OmFileWriter2(fn: fn, initialCapacity: 8)
        
        let writer = try fileWriter.prepareArray(type: Float.self, dimensions: dims, chunkDimensions: [2,2], compression: .p4nzdec256, scale_factor: 1, add_offset: 0)
        
        let data = [Float(0.0), 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0]
        try writer.writeData(array: data)
        let variableMeta = try writer.finalise()
        let variable = try fileWriter.write(array: variableMeta, name: "data", children: [])
        try fileWriter.writeTrailer(rootVariable: variable)
        
        let readFn = try MmapFile(fn: FileHandle.openFileReading(file: file))
        let read = try OmFileReader2(fn: readFn).asArray(of: Float.self, io_size_max: 0, io_size_merge: 0)!
        

        let a = try read.read(range: [0..<5, 0..<5])
        #expect(a == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0])
        
        // single index
        for x in 0..<dims[0] {
            for y in 0..<dims[1] {
                #expect(try read.read(range: [x..<x+1, y..<y+1]) == [Float(x*5 + y)])
            }
        }
        
        // Read into an existing array with an offset
        for x in 0..<dims[0] {
            for y in 0..<dims[1] {
                var r = [Float](repeating: .nan, count: 9)
                try r.withUnsafeMutableBufferPointer({
                    try read.read(into: $0.baseAddress!, range: [x..<x+1, y..<y+1], intoCubeOffset: [1,1], intoCubeDimension: [3,3])
                })
                #expect(r == [.nan, .nan, .nan, .nan, Float(x*5 + y), .nan, .nan, .nan, .nan])
            }
        }
        
        // 2x in fast dim
        for x in 0..<dims[0] {
            for y in 0..<dims[1]-1 {
                #expect(try read.read(range: [x..<x+1, y..<y+2]) == [Float(x*5 + y), Float(x*5 + y + 1)])
            }
        }
        
        // 2x in slow dim
        for x in 0..<dims[0]-1 {
            for y in 0..<dims[1] {
                #expect(try read.read(range: [x..<x+2, y..<y+1]) == [Float(x*5 + y), Float((x+1)*5 + y)])
            }
        }
        
        // 2x2
        for x in 0..<dims[0]-1 {
            for y in 0..<dims[1]-1 {
                #expect(try read.read(range: [x..<x+2, y..<y+2]) == [Float(x*5 + y), Float(x*5 + y + 1), Float((x+1)*5 + y), Float((x+1)*5 + y + 1)])
            }
        }
        // 3x3
        for x in 0..<dims[0]-2 {
            for y in 0..<dims[1]-2 {
                #expect(try read.read(range: [x..<x+3, y..<y+3]) == [Float(x*5 + y), Float(x*5 + y + 1), Float(x*5 + y + 2), Float((x+1)*5 + y), Float((x+1)*5 + y + 1),  Float((x+1)*5 + y + 2), Float((x+2)*5 + y), Float((x+2)*5 + y + 1),  Float((x+2)*5 + y + 2)])
            }
        }
        
        // 1x5
        for x in 0..<dims[1] {
            #expect(try read.read(range: [x..<x+1, 0..<5]) == [Float(x*5), Float(x*5+1), Float(x*5+2), Float(x*5+3), Float(x*5+4)])
        }
        
        // 5x1
        for x in 0..<dims[0] {
            #expect(try read.read(range: [0..<5, x..<x+1]) == [Float(x), Float(x+5), Float(x+10), Float(x+15), Float(x+20)])
        }
        
        /*// test interpolation
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.5, dim0Y: 0, dim0YFraction: 0.5, dim0Nx: 2, dim1: 0..<5), [7.5, 8.5, 9.5, 10.5, 11.5], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.1, dim0Y: 0, dim0YFraction: 0.2, dim0Nx: 2, dim1: 0..<5), [2.5, 3.4999998, 4.5, 5.5, 6.5], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.9, dim0Y: 0, dim0YFraction: 0.2, dim0Nx: 2, dim1: 0..<5), [6.5, 7.5, 8.5, 9.5, 10.5], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.1, dim0Y: 0, dim0YFraction: 0.9, dim0Nx: 2, dim1: 0..<5), [9.5, 10.499999, 11.499999, 12.5, 13.499999], accuracy: 0.001)
        XCTAssertEqualArray(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.8, dim0Y: 0, dim0YFraction: 0.9, dim0Nx: 2, dim1: 0..<5), [12.999999, 14.0, 15.0, 16.0, 17.0], accuracy: 0.001)*/
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func oldWriterNewReader() throws {
        let file = "oldWriterNewReader.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let fn = try OmFileWriter(dim0: 5, dim1: 5, chunk0: 2, chunk1: 2).write(file: file, compressionType: .p4nzdec256, scalefactor: 1, overwrite: false, supplyChunk: { dim0pos in
            
            if dim0pos == 0 {
                return ArraySlice((0..<10).map({ Float($0) }))
            }
            if dim0pos == 2 {
                return ArraySlice((10..<20).map({ Float($0) }))
            }
            if dim0pos == 4 {
                return ArraySlice((20..<25).map({ Float($0) }))
            }
            fatalError("Not expected")
        })
        
        let io_size_max: UInt64 = 1000000
        let io_size_merge: UInt64 = 100000
        
        let read = try OmFileReader2(fn: try MmapFile(fn: fn)).asArray(of: Float.self, io_size_max: io_size_max, io_size_merge: io_size_merge)!
        let dims = read.getDimensions()
        let a = try read.read(range: [0..<5, 0..<5])
        #expect(a == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0])
        
        // single index
        for x in 0..<dims[0] {
            for y in 0..<dims[1] {
                #expect(try read.read(range: [x..<x+1, y..<y+1]) == [Float(x*5 + y)])
            }
        }
        
        // Read into an existing array with an offset
        for x in 0..<dims[0] {
            for y in 0..<dims[1] {
                var r = [Float](repeating: .nan, count: 9)
                try r.withUnsafeMutableBufferPointer({
                    try read.read(into: $0.baseAddress!, range: [x..<x+1, y..<y+1], intoCubeOffset: [1,1], intoCubeDimension: [3,3])
                })
                #expect(r == [.nan, .nan, .nan, .nan, Float(x*5 + y), .nan, .nan, .nan, .nan])
            }
        }
        
        // 2x in fast dim
        for x in 0..<dims[0] {
            for y in 0..<dims[1]-1 {
                #expect(try read.read(range: [x..<x+1, y..<y+2]) == [Float(x*5 + y), Float(x*5 + y + 1)])
            }
        }
        
        // 2x in slow dim
        for x in 0..<dims[0]-1 {
            for y in 0..<dims[1] {
                #expect(try read.read(range: [x..<x+2, y..<y+1]) == [Float(x*5 + y), Float((x+1)*5 + y)])
            }
        }
        
        // 2x2
        for x in 0..<dims[0]-1 {
            for y in 0..<dims[1]-1 {
                #expect(try read.read(range: [x..<x+2, y..<y+2]) == [Float(x*5 + y), Float(x*5 + y + 1), Float((x+1)*5 + y), Float((x+1)*5 + y + 1)])
            }
        }
        // 3x3
        for x in 0..<dims[0]-2 {
            for y in 0..<dims[1]-2 {
                #expect(try read.read(range: [x..<x+3, y..<y+3]) == [Float(x*5 + y), Float(x*5 + y + 1), Float(x*5 + y + 2), Float((x+1)*5 + y), Float((x+1)*5 + y + 1),  Float((x+1)*5 + y + 2), Float((x+2)*5 + y), Float((x+2)*5 + y + 1),  Float((x+2)*5 + y + 2)])
            }
        }
        
        // 1x5
        for x in 0..<dims[1] {
            #expect(try read.read(range: [x..<x+1, 0..<5]) == [Float(x*5), Float(x*5+1), Float(x*5+2), Float(x*5+3), Float(x*5+4)])
        }
        
        // 5x1
        for x in 0..<dims[0] {
            #expect(try read.read(range: [0..<5, x..<x+1]) == [Float(x), Float(x+5), Float(x+10), Float(x+15), Float(x+20)])
        }
        try FileManager.default.removeItem(atPath: file)
    }
    
    
    @Test func write() throws {
        let file = "write.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        try OmFileWriter(dim0: 5, dim1: 5, chunk0: 2, chunk1: 2).write(file: file, compressionType: .p4nzdec256, scalefactor: 1, overwrite: false, supplyChunk: { dim0pos in
            
            if dim0pos == 0 {
                return ArraySlice((0..<10).map({ Float($0) }))
            }
            if dim0pos == 2 {
                return ArraySlice((10..<20).map({ Float($0) }))
            }
            if dim0pos == 4 {
                return ArraySlice((20..<25).map({ Float($0) }))
            }
            fatalError("Not expected")
        })
        
        let read = try OmFileReader(file: file)
        let a = try read.read(dim0Slow: 0..<5, dim1: 0..<5)
        #expect(a == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0])
        
        // single index
        for x in 0..<read.dim0 {
            for y in 0..<read.dim1 {
                #expect(try read.read(dim0Slow: x..<x+1, dim1: y..<y+1) == [Float(x*5 + y)])
            }
        }
        
        // 2x in fast dim
        for x in 0..<read.dim0 {
            for y in 0..<read.dim1-1 {
                #expect(try read.read(dim0Slow: x..<x+1, dim1: y..<y+2) == [Float(x*5 + y), Float(x*5 + y + 1)])
            }
        }
        
        // 2x in slow dim
        for x in 0..<read.dim0-1 {
            for y in 0..<read.dim1 {
                #expect(try read.read(dim0Slow: x..<x+2, dim1: y..<y+1) == [Float(x*5 + y), Float((x+1)*5 + y)])
            }
        }
        
        // 2x2
        for x in 0..<read.dim0-1 {
            for y in 0..<read.dim1-1 {
                #expect(try read.read(dim0Slow: x..<x+2, dim1: y..<y+2) == [Float(x*5 + y), Float(x*5 + y + 1), Float((x+1)*5 + y), Float((x+1)*5 + y + 1)])
            }
        }
        // 3x3
        for x in 0..<read.dim0-2 {
            for y in 0..<read.dim1-2 {
                #expect(try read.read(dim0Slow: x..<x+3, dim1: y..<y+3) == [Float(x*5 + y), Float(x*5 + y + 1), Float(x*5 + y + 2), Float((x+1)*5 + y), Float((x+1)*5 + y + 1),  Float((x+1)*5 + y + 2), Float((x+2)*5 + y), Float((x+2)*5 + y + 1),  Float((x+2)*5 + y + 2)])
            }
        }
        
        // 1x5
        for x in 0..<read.dim1 {
            #expect(try read.read(dim0Slow: x..<x+1, dim1: 0..<5) == [Float(x*5), Float(x*5+1), Float(x*5+2), Float(x*5+3), Float(x*5+4)])
        }
        
        // 5x1
        for x in 0..<read.dim0 {
            #expect(try read.read(dim0Slow: 0..<5, dim1: x..<x+1) == [Float(x), Float(x+5), Float(x+10), Float(x+15), Float(x+20)])
        }
        
        // test interpolation
        #expect(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.5, dim0Y: 0, dim0YFraction: 0.5, dim0Nx: 2, dim1: 0..<5) == [7.5, 8.5, 9.5, 10.5, 11.5])
        #expect(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.1, dim0Y: 0, dim0YFraction: 0.2, dim0Nx: 2, dim1: 0..<5) == [2.5, 3.4999998, 4.5, 5.5, 6.5])
        #expect(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.9, dim0Y: 0, dim0YFraction: 0.2, dim0Nx: 2, dim1: 0..<5) == [6.5, 7.5, 8.5, 9.5, 10.5])
        #expect(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.1, dim0Y: 0, dim0YFraction: 0.9, dim0Nx: 2, dim1: 0..<5) == [9.5, 10.499999, 11.499999, 12.5, 13.499999])
        #expect(try read.readInterpolated(dim0X: 0, dim0XFraction: 0.8, dim0Y: 0, dim0YFraction: 0.9, dim0Nx: 2, dim1: 0..<5) == [12.999999, 14.0, 15.0, 16.0, 17.0])
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func naN() throws {
        let file = "naN.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let data = (0..<(5*5)).map({ val in Float.nan })
        try OmFileWriter(dim0: 5, dim1: 5, chunk0: 5, chunk1: 5).write(file: file, compressionType: .p4nzdec256, scalefactor: 1, all: data)
        
        let read = try OmFileReader(file: file)
        let data2 = try read.read(dim0Slow: nil, dim1: nil)
        print(data2)
        #expect(try read.read(dim0Slow: 1..<2, dim1: 1..<2)[0].isNaN)
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func writeFpx() throws {
        let file = "writeFpx.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        try OmFileWriter(dim0: 5, dim1: 5, chunk0: 2, chunk1: 2).write(file: file, compressionType: .fpxdec32, scalefactor: 1, overwrite: false, supplyChunk: { dim0pos in
            
            if dim0pos == 0 {
                return ArraySlice((0..<10).map({ Float($0) }))
            }
            if dim0pos == 2 {
                return ArraySlice((10..<20).map({ Float($0) }))
            }
            if dim0pos == 4 {
                return ArraySlice((20..<25).map({ Float($0) }))
            }
            fatalError("Not expected")
        })
        
        let read = try OmFileReader(file: file)
        let a = try read.read(dim0Slow: 0..<5, dim1: 0..<5)
        #expect(a == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0])
        
        // single index
        for x in 0..<read.dim0 {
            for y in 0..<read.dim1 {
                #expect(try read.read(dim0Slow: x..<x+1, dim1: y..<y+1) == [Float(x*5 + y)])
            }
        }
        
        // 2x in fast dim
        for x in 0..<read.dim0 {
            for y in 0..<read.dim1-1 {
                #expect(try read.read(dim0Slow: x..<x+1, dim1: y..<y+2) == [Float(x*5 + y), Float(x*5 + y + 1)])
            }
        }
        
        // 2x in slow dim
        for x in 0..<read.dim0-1 {
            for y in 0..<read.dim1 {
                #expect(try read.read(dim0Slow: x..<x+2, dim1: y..<y+1) == [Float(x*5 + y), Float((x+1)*5 + y)])
            }
        }
        
        // 2x2
        for x in 0..<read.dim0-1 {
            for y in 0..<read.dim1-1 {
                #expect(try read.read(dim0Slow: x..<x+2, dim1: y..<y+2) == [Float(x*5 + y), Float(x*5 + y + 1), Float((x+1)*5 + y), Float((x+1)*5 + y + 1)])
            }
        }
        // 3x3
        for x in 0..<read.dim0-2 {
            for y in 0..<read.dim1-2 {
                #expect(try read.read(dim0Slow: x..<x+3, dim1: y..<y+3) == [Float(x*5 + y), Float(x*5 + y + 1), Float(x*5 + y + 2), Float((x+1)*5 + y), Float((x+1)*5 + y + 1),  Float((x+1)*5 + y + 2), Float((x+2)*5 + y), Float((x+2)*5 + y + 1),  Float((x+2)*5 + y + 2)])
            }
        }
        
        // 1x5
        for x in 0..<read.dim1 {
            #expect(try read.read(dim0Slow: x..<x+1, dim1: 0..<5) == [Float(x*5), Float(x*5+1), Float(x*5+2), Float(x*5+3), Float(x*5+4)])
        }
        
        // 5x1
        for x in 0..<read.dim0 {
            #expect(try read.read(dim0Slow: 0..<5, dim1: x..<x+1) == [Float(x), Float(x+5), Float(x+10), Float(x+15), Float(x+20)])
        }
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func naNfpx() throws {
        let file = "naNfpx.om"
        try FileManager.default.removeItemIfExists(at: file)
        
        let data = (0..<(5*5)).map({ val in Float.nan })
        try OmFileWriter(dim0: 5, dim1: 5, chunk0: 5, chunk1: 5).write(file: file, compressionType: .fpxdec32, scalefactor: 1, all: data)
        
        let read = try OmFileReader(file: file)
        let data2 = try read.read(dim0Slow: nil, dim1: nil)
        print(data2)
        #expect(try read.read(dim0Slow: 1..<2, dim1: 1..<2)[0].isNaN)
        try FileManager.default.removeItem(atPath: file)
    }
    
    @Test func copyLog10Roundtrip() {
        let ints: [Int16] = [100, 200, 300, 400, 500]
        var floats = [Float](repeating: 0, count: ints.count)
        var intsRoundtrip = [Int16](repeating: 0, count: ints.count)

        ints.withUnsafeBufferPointer { srcPtr in
            floats.withUnsafeMutableBufferPointer { dstPtr in
                om_common_copy_int16_to_float_log10(UInt64(ints.count), 1000.0, 0.0, srcPtr.baseAddress, dstPtr.baseAddress)
            }
        }

        floats.withUnsafeBufferPointer { srcPtr in
            intsRoundtrip.withUnsafeMutableBufferPointer { dstPtr in
                om_common_copy_float_to_int16_log10(UInt64(floats.count), 1000.0, 0.0, srcPtr.baseAddress, dstPtr.baseAddress)
            }
        }

        #expect(ints == intsRoundtrip)
    }
}
