import Foundation
import Testing
@testable import OmFileFormat

@Suite struct ConcurrentWriterTests {
    @Test(arguments: [1, 2, 4, 64])
    func matchesSequential(nConcurrent: Int) async throws {
        let dimensions: [UInt64] = [5, 19]
        let chunks: [UInt64] = [2, 7]
        let values = (0..<95).map { Float($0 % 31) / 20 }
        let pointer = UnsafeMutablePointer<Float>.allocate(capacity: values.count)
        pointer.initialize(from: values, count: values.count)
        defer { pointer.deinitialize(count: values.count); pointer.deallocate() }
        let input = UnsafeBufferPointer(start: pointer, count: values.count)
        let expected = try await writeFloatFile(dimensions: dimensions, chunks: chunks) {
            try $0.writeData(array: values)
        }
        let actual = try await writeFloatFile(dimensions: dimensions, chunks: chunks) {
            try await $0.writeDataConcurrent(pointer: input.baseAddress!, count: input.count, nConcurrent: nConcurrent)
        }
        #expect(actual == expected)
        let fromArray = try await writeFloatFile(dimensions: dimensions, chunks: chunks) {
            try await $0.writeDataConcurrent(array: values, nConcurrent: nConcurrent)
        }
        #expect(fromArray == expected)
    }

    @Test func successiveRegions() async throws {
        let dimensions: [UInt64] = [6, 19]
        let chunks: [UInt64] = [2, 7]
        let values = (0..<114).map { Float($0 % 53) / 20 }
        let pointer = UnsafeMutablePointer<Float>.allocate(capacity: values.count)
        pointer.initialize(from: values, count: values.count)
        defer { pointer.deinitialize(count: values.count); pointer.deallocate() }
        let input = UnsafeBufferPointer(start: pointer, count: values.count)
        let expected = try await writeFloatFile(dimensions: dimensions, chunks: chunks) {
            try $0.writeData(array: values)
        }
        let actual = try await writeFloatFile(dimensions: dimensions, chunks: chunks) { writer in
            try writer.writeData(array: values, arrayOffset: [0, 0], arrayCount: [2, 19])
            try await writer.writeDataConcurrent(pointer: input.baseAddress!, count: input.count, arrayOffset: [2, 0], arrayCount: [2, 19], nConcurrent: 2)
            try await writer.writeDataConcurrent(array: values, arrayDimensions: dimensions, arrayOffset: [4, 0], arrayCount: [2, 19], nConcurrent: 4)
        }
        #expect(actual == expected)
    }
}
