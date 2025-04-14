# OM-File-Format Library

[![Test](https://github.com/open-meteo/om-file-format/actions/workflows/test.yml/badge.svg)](https://github.com/open-meteo/om-file-format/actions/workflows/test.yml) [![GitHub license](https://img.shields.io/github/license/open-meteo/om-file-format)](https://github.com/open-meteo/om-file-format/blob/main/LICENSE)

The Open-Meteo OM-File format is designed for efficient storage and distribution of multi-dimensional environmental data. By chunking, compressing, and indexing the data, OM-Files enable cloud-native random reads while minimizing file sizes. The format supports hierarchical data structures similar to NetCDF or HDF5.

This library implements the format in C, with a high-level Swift abstraction integrated directly into the Open-Meteo weather API. Future bindings for Python, TypeScript, and Rust are planned.

**Note**: This library is in a highly experimental stage. While Open-Meteo has used the format for years, this standalone library was initiated in October 2024 to provide Python bindings. We aim to provide a robust Python library to access the [Open-Meteo weather database](https://github.com/open-meteo/open-data) provided on S3 through an AWS open-data sponsorship.


### Features:
- **Chunked, compressed multi-dimensional arrays**
- **High-speed integer compression:** Fast compression speed at high compression ratios
- **Lossless and lossy compression:** Adjustable accuracy via scale factors to further reduce data size
- **Optimized for cloud-native random IO access:** Supports IO merging and splitting
- **Sequential file writing:** Enables streaming write to cloud storage; metadata is stored at the file’s end
- **Sans-IO C implementation:** Designed for async support and concurrency in higher-level libraries


### Core Principles:
- **Chunked Data Storage:** OM-Files partition large data arrays into individually compressed chunks, with a lookup table tracking chunk positions. This allows reading and decompressing only the required chunks—ideal for use cases like meteorological datasets, where users often query specific regions rather than global data.
- **Optimized for Meteorological Use Cases:** Example: In weather reanalysis (e.g., Copernicus ERA5-Land), global datasets at 0.1° spatial resolution can reach massive scales. A single timestep with 3600 x 1800 pixels (~25 MB using 32-bit floats) grows to 211.5 GB for one year of hourly data (8760 hours). Over decades, and across thousands of variables, datasets easily reach petabyte scales. Traditional GRIB files, while efficient for compression, require decompressing the entire file to access specific subsets. OM-Files, on the other hand, allow direct access to localized data (e.g., a single country or city) by leveraging small chunk sizes (e.g., 3 x 3 x 120).
- **High-Speed Data Access:** OM-Files minimize data transfer and decompression overhead, enabling extremely fast reads while maintaining strong compression ratios based on [FastPFOR](https://github.com/fast-pack/FastPFor) with SIMD instructions for compression rates in the GB/s range. This powers the Open-Meteo weather API to deliver forecasts in sub-millisecond speeds and enables large-scale data analysis without requiring users to download hundreds of gigabytes of GRIB files.
- **Improved Compression Efficiency:** Chunking exploits spatial and temporal data correlations to enhance compression. Weather data, for instance, shows gradual changes across locations and time. Optimal chunking dimensions (compressing 1,000–2,000 values per chunk with a last dimension >100) strike a balance between compression efficiency and performance. Too many chunks reduce both.

### C Library Interface
The C code is available in [/c](./c/). The C code is the foundation for all language bindings, but is completely agnostic of any IO or threading.

TODO document C functions

### Swift Library Interface
Swift code can be found in [./Swift](./Swift/) with tests in [./Tests](./Tests/). The Swift functions interact with the underlying C function and provide IO and structured concurrency.

TODO: Document functions + example


### Rust Library
This repository exposes low level Rust bindings to access the underlying C functions. A high level implementation is available in [open-meteo/rust-omfiles](https://github.com/open-meteo/rust-omfiles).


### Python Library
Python bindings can be found in the repository [open-meteo/python-omfiles](https://github.com/open-meteo/python-omfiles). Python bindings are based no the Rust bindings.


### ToDo:
- Document Swift functions
- Document C functions
- Support for string-arrays
- Build web-interface to make the entire Open-Meteo weather database accessible with automatic Python code generation


### Data Hierarchy Model:
- The file trailer contains the position of the root `Variable`
- Each `Variable` has a datatype and payload. E.g. Int16 has the number as 2-byte payload. An array stores the look-up-table position and array dimension information. The actual compressed array data, is stored at the beginning of the file.
- Each `Variable` has a name
- Each `Variable` has 0...N variables -> Variables resemble a key-value store where each value can have N children.

A `Variable` can be of different types:
- `None`: Does not contain any value. Useful to define a group
- `Scalar` or types Int8, Int16, Int32, Int64, Float, Double, String, etc
- `Array` of type Int8, Int16, etc with dimensions, chunks and compression type information
- `String Array` to be implemented

### Examples
The following examples show how data with attribute can be encoded into an OM-File format

**Example 1: Plain array inside an OM-File:**
```
Root: Name="temperature_2m" Type=Float32-Array Dimensions=[720,1400,24] Chunks=[1,50,24]
```

**Example 2: Array with attributes**
```
Root: Name="temperature_2m" Type=Float32-Array Dimensions=[720,1400,24] Chunks=[1,50,24]
|- Name="dimension_names" Type=String-Array Dimensions=[3]
|- Name="long_name" Type=String Value="Temperature 2 metres above ground"
|- Name="unit" Type=String Value="Celsius"
|- Name="height" Type=Int32 Value=2
```

**Example 3: Multiple Arrays with attributes**
```
Root: Type=None
|- Name="temperature_2m" Type=Float32-Array Dimensions=[720,1400,24] Chunks=[1,50,24]
  |- Name="dimension_names" Type=String-Array Dimensions=[3]
  |- Name="long_name" Type=String Value="Temperature 2 metres above ground"
  |- Name="unit" Type=String Value="Celsius"
  |- Name="height" Type=Int32 Value=2
|- Name="relative_humidity_2m" Type=Float32-Array Dimensions=[720,1400,24] Chunks=[1,50,24]
  |- Name="dimension_names" Type=String-Array Dimensions=[3]
  |- Name="long_name" Type=String Value="Relative Humidity 2 metres above ground"
  |- Name="unit" Type=String Value="Percentage"
  |- Name="height" Type=Int32 Value=2
```

### Model

```mermaid
classDiagram
    Variable <|-- Variable
    Variable --|> Int8
    Variable --|> Int16
    Variable --|>String
    Variable --|> Array
    Trailer --|> Variable
    Variable : +String_name
    Variable : +Variable[]_children
    Variable : +Enum_data_type
    Variable : +Enum_compression_type
    Variable: +number_of_childen()
    Variable: +get_child(int n)
    Variable: +get_name()
    class Trailer {
        +version
        +root_variable
    }
    class Int8{
      +Int8 value
      +read()
    }
    class Int16{
      +Int16 value
      +read()
    }
    class String{
      +String_value
      +read()
    }
    class Array{
        +Int64[]_dimensions
        +Int64[]_chunks
      +Int64_look_up_table_offset
      +Int64_look_up_table_size
      +read(offset:Int64[],count:Int64[])
    }
```

Legacy Binary Format:
- Int16: magic number "OM"
- Int8: version
- Int8: compression type with filter
- Float32: scalefactor
- Int64: dim0 dim (slow)
- Int64: dim0 dim1 (fast)
- Int64: chunk dim0
- Int64: chunk dim1
- **Array of 64-bit Integer: Offset lookup table**
- **Blob: Data for each chunk, offset but the lookup table**

New Binary Format:
- 3 byte: header (magic number "OM" + version)
- Blob: Compressed data and lookup table LUT
- Blob: Binary encoded meta data
- 24 byte: Trailer with address to root variable

Binary representation:
- File header with magic number and version
- File trailer with offsets and size of the root variable
- Variable has attributes: date type (8bit), compression type (8bit), size_of_name (16bit), count_of_attributes (32bit)
- Depending on data type followed by payload for a given data type
- Followed by the name as string, and for each attribute the offset and size
- Typically all compressed data is in the beginning of the file, followed by all meta data and attributes (streaming write without ever seeking back!)

Header message:
<table><thead>
  <tr>
    <th>Byte 1</th>
    <th>Byte 2</th>
    <th>Byte 3</th>
    <th>Byte 4</th>
    <th>Byte 5</th>
    <th>Byte 6</th>
    <th>Byte 7</th>
    <th>Byte 8</th>
  </tr></thead>
<tbody>
  <tr>
    <td colspan="2">Magic number "OM"</td>
    <td>Version</td>
  </tr>
</tbody></table>

Trailer message:
<table><thead>
  <tr>
    <th>Byte 1</th>
    <th>Byte 2</th>
    <th>Byte 3</th>
    <th>Byte 4</th>
    <th>Byte 5</th>
    <th>Byte 6</th>
    <th>Byte 7</th>
    <th>Byte 8</th>
  </tr></thead>
<tbody>
  <tr>
    <td colspan="2">Magic number "OM"</td>
    <td>Version</td>
    <td>Reserved</td>
    <td colspan="4">Reserved</td>
  </tr>
  <tr>
    <td colspan="8">Size of Root Variable</td>
  </tr>
  <tr>
    <td colspan="8">Offset of Root Variable</td>
  </tr>
</tbody></table>

Variable message:
<table><thead>
  <tr>
    <th>Byte 1</th>
    <th>Byte 2</th>
    <th>Byte 3</th>
    <th>Byte 4</th>
    <th>Byte 5</th>
    <th>Byte 6</th>
    <th>Byte 7</th>
    <th>Byte 8</th>
  </tr></thead>
<tbody>
  <tr>
    <td>Data Type</td>
    <td>Compression Type</td>
    <td colspan="2">Size of name</td>
    <td colspan="4">Number of Children</td>
  </tr>
  <tr>
    <td colspan="8">Size of Value / LUT (only arrays and strings)</td>
  </tr>
  <tr>
    <td colspan="8">Offset of Value / LUT (only arrays)</td>
  </tr>
  <tr>
    <td colspan="8">Number of Dimensions (only arrays)</td>
  </tr>
  <tr>
    <td colspan="4">Scale Factor (float, only arrays)</td>
    <td colspan="4">Add Offset (float, only arrays)</td>
  </tr>
  <tr>
    <td colspan="8">N * Size of Child</td>
  </tr>
  <tr>
    <td colspan="8">N * Offset of Child</td>
  </tr>
  <tr>
    <td colspan="8">N * Dimension Length (only arrays)</td>
  </tr>
  <tr>
    <td colspan="8">N * Chunk Dimension Length (only arrays)</td>
  </tr>
  <tr>
    <td colspan="8">Bytes of value (scalar, string, not arrays)</td>
  </tr>
  <tr>
    <td colspan="8">Byte of name</td>
  </tr>
</tbody></table>
