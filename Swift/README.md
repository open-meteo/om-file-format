# Using Om-Files in Swift

## Installation

The current package requires Swift 6.3 and declares macOS 26 as its minimum macOS version.

Add `OmFileFormat` as a dependency to your `Package.swift`. Note: Unsafe compiler flags are required for SIMD instructions and this does not work if semantic versioning is used. Therefore, the git revision needs to be specified manually.

```swift
  dependencies: [
    .package(url: "https://github.com/open-meteo/om-file-format.git", revision: "a19e578b2e791cf5c169334c6674c553d5aa2b42")
  ],
  targets: [
    .target(name: "MyApp", dependencies: [.product(name: "OmFileFormat", package: "om-file-format")])
  ]
```

## Writing an array

This example creates `temperature.om` with a Float array shaped `[2, 3, 4]`
(for example, `[y, x, time]`) and a string attribute. Values are flattened in
row-major order: the last dimension varies fastest. Run the examples inside a
throwing function; reading examples also require an async context.

```swift
import Foundation
import OmFileFormat

func writeExample(file: String) throws {
    let handle = try FileHandle.createNewFile(file: file)
    defer { try? handle.close() }
    let fileWriter = OmFileWriter(fn: handle, initialCapacity: 65536)

    let values = (0..<24).map { Float($0) / 2 }
    let array = try fileWriter.writeArray(
        data: values,
        dimensions: [2, 3, 4],
        chunkDimensions: [1, 2, 4],
        compression: .fpx_xor2d,
        scale_factor: 1,
        add_offset: 0
    )
    let units = try fileWriter.write(value: "°C", name: "units", children: [])
    let root = try fileWriter.write(
        array: array, name: "temperature", children: [units]
    )
    try fileWriter.writeTrailer(rootVariable: root)
}

try writeExample(file: "temperature.om")
```

`createNewFile` refuses to replace an existing file unless `overwrite: true` is
passed. `writeArray` compresses the data and finalises its LUT; `write` adds the
variable metadata. `writeTrailer` completes the file and flushes buffered output.
The example uses lossless FPX compression. For lossy floating-point compression,
use `.pfor_delta2d_int16` with a suitable scale factor for your data's precision
and range.

## Reading an array

Open the file from the previous example with a memory-mapped backend:

```swift
import Foundation
import OmFileFormat

let root = try await OmFileReader(mmapFile: "temperature.om")
let reader = try root.expectArray(of: Float.self)

print(root.getName())                // temperature
print(reader.getDimensions())       // [2, 3, 4]
print(reader.getChunkDimensions())   // [1, 2, 4]
let values = try await reader.read() // All 24 values
```

`expectArray(of:)` throws if the stored array type does not match. Use
`asArray(of:)` when you prefer an optional result. `OmFileReader(file:)` provides
an alternative local backend using file reads instead of memory mapping.

### Partial reads

Supply one half-open range per dimension. The returned array is flat and follows
the same row-major order as the input:

```swift
// All four time steps at y = 1, x = 2.
let timeSeries = try await reader.read(range: [1..<2, 2..<3, 0..<4])
// [10, 10.5, 11, 11.5]

// A 2 × 2 spatial region at time step 1.
let region = try await reader.read(range: [0..<2, 1..<3, 1..<2])
// [2.5, 4.5, 8.5, 10.5]

// The same selection expressed as an offset and count.
let sameRegion = try await reader.read(offset: [0, 1, 1], count: [2, 2, 1])
```

Ranges and offsets use `UInt64`. These APIs take `InlineArray` arguments, so the
number of dimensions is known at compile time. Reads may cross chunk boundaries;
the reader fetches and decompresses the required chunks.

### Attributes and child variables

Attributes are child variables. Read the string attribute created above, or
inspect every child:

```swift
if let attribute = try await root.getChild(name: "units") {
    let units: String? = attribute.readScalar()
    print(units ?? "")
}

for i in 0..<root.numberOfChildren {
    if let child = try await root.getChild(i) {
        print(child.getName(), child.dataType)
    }
}
```

For a file containing multiple arrays, write each array variable first, collect
its returned `OmOffsetSize`, and create a group with
`fileWriter.writeNone(name: "", children: variables)`. Pass that group's offset
and size to `writeTrailer(rootVariable:)`. On reading, select an array with
`getChild(name:)`, then call `expectArray(of:)` on that child.

## Writing incrementally

Use `prepareArray` when the full array is not available at once. This example
writes one complete row at a time:

```swift
func writeRows(file: String) throws {
    let handle = try FileHandle.createNewFile(file: file)
    defer { try? handle.close() }
    let fileWriter = OmFileWriter(fn: handle, initialCapacity: 65536)
    let writer = try fileWriter.prepareArray(
        type: Float.self,
        dimensions: [3, 45],
        chunkDimensions: [1, 2],
        compression: .fpx_xor2d,
        scale_factor: 1,
        add_offset: 0
    )

    for row in 0..<3 {
        let values = (0..<45).map { Float(row * 45 + $0) }
        try writer.writeData(array: values, arrayDimensions: [1, 45])
    }

    let array = try writer.finalise()
    let root = try fileWriter.write(array: array, name: "data", children: [])
    try fileWriter.writeTrailer(rootVariable: root)
}
```

Each write must cover complete chunks in sequential chunk order, including
smaller chunks at array edges. Write all chunks before calling `finalise()`, and
finish one array before preparing another on the same file writer.

## Writing NaN chunks

On an `OmFileWriterArray<Float, Backend>` or `OmFileWriterArray<Double, Backend>`,
use `writeNaN(arrayDimensions:)` to append NaN chunks without allocating an input
array or writing compressed payloads:

```swift
// For an array with dimensions [3, 45] and chunk dimensions [1, 2],
// append the next complete row, including its smaller final chunk.
try writer.writeNaN(arrayDimensions: [1, 45])
```

The region starts at the next unwritten chunk and must cover whole chunks,
including smaller edge chunks, contiguously in chunk order. Calls can be mixed
with `writeData` and `writeCompressedChunk`, always advancing in chunk order.

To append just one NaN chunk, including an edge chunk:

```swift
try writer.writeCompressedChunk(UnsafeRawBufferPointer(start: nil, count: 0))
```

A nil base address or an empty buffer has this behavior; empty buffers with a
nonnil address also work. Empty chunks are supported only for Float/Double arrays.
Ordinary `writeData` calls still compress NaNs normally. Zero-byte chunks require
an updated reader and do not preserve NaN sign or payload bits.

## Inspecting and copying chunks

`chunkIndex()` returns an `OmFileChunkIndex` containing the absolute file byte
range of every chunk. It reads the entire LUT in one backend request, ignoring
the reader's IO limits, and stores `numberOfChunks + 1` decoded offsets. Empty
ranges represent NaN chunks. Both legacy and current LUT layouts are supported.

`chunkLayout()` returns an `OmFileChunkLayout` using already loaded metadata,
without backend reads. Each element has `shape`, `offset`, and `arrayDimensions`
properties, plus `range(in:)` for the coordinates covered along one dimension.
Shapes account for smaller edge chunks. Both collections use row-major chunk
order, with the last dimension varying fastest:

```swift
let index = try await reader.chunkIndex()
let layout = try reader.chunkLayout()

for (bytes, chunk) in zip(index, layout) {
    print(bytes, chunk.shape, chunk.offset, chunk.range(in: 0))
}
```

To copy chunks without decoding them, prepare a destination array writer with
the same dimensions, chunk dimensions, compression, scale factor, and offset.
For a Float/Double source and destination:

```swift
let index = try await reader.chunkIndex()
for range in index {
    if range.isEmpty {
        try writer.writeCompressedChunk(UnsafeRawBufferPointer(start: nil, count: 0))
        continue
    }
    let data = try await reader.fn.getData(
        offset: Int(range.lowerBound), count: Int(range.count)
    )
    try data.withUnsafeBytes { bytes in
        try writer.writeCompressedChunk(bytes)
    }
}
```

This example reads each nonempty chunk separately; remote callers can combine
adjacent ranges into fewer requests. Nonempty compressed payloads are copied
without validation. To omit a chunk in a selective copy, write an empty buffer
in its place. After writing all chunks, finalise the array and write its variable
and file trailer as usual.
