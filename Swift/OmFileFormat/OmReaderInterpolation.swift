extension OmFileReaderArrayProtocol where OmType == Float {
    /// Read interpolated between 4 points. Assuming dim0 and dim1 are a spatial field
    public func readInterpolated(dim0: Int, dim0Fraction: Float, dim1: Int, dim1Fraction: Float) async throws -> Float {
        let dims = getDimensions()
        guard dims.count == 2 else {
            throw OmFileFormatSwiftError.requireDimensionsToMatch(required: 2, actual: dims.count)
        }
        // bound x and y
        var dim0 = UInt64(dim0)
        var dim0Fraction = dim0Fraction
        if dim0+2 > dims[0] {
            dim0 = dims[0]-2
            dim0Fraction = 1
        }
        var dim1 = UInt64(dim1)
        var dim1Fraction = dim1Fraction
        if dim1+2 > dims[1] {
            dim1 = dims[1]-2
            dim1Fraction = 1
        }

        // reads 4 points at once
        let points = try await read(range: [dim0 ..< dim0 + 2, dim1 ..< dim1 + 2])

        // interpolate linearly between
        return points[0] * (1-dim0Fraction) * (1-dim1Fraction) +
               points[1] * (dim0Fraction) * (1-dim1Fraction) +
               points[2] * (1-dim0Fraction) * (dim1Fraction) +
               points[3] * (dim0Fraction) * (dim1Fraction)
    }

    /// Read interpolated between 4 points. Assuming dim0 is used for locations and dim1 is a time series
    public func readInterpolated(dim0X: Int, dim0XFraction: Float, dim0Y: Int, dim0YFraction: Float, dim0Nx: Int, dim1 dim1Read: Range<UInt64>) async throws -> [Float] {
        let dims = getDimensions()
        guard dims.count == 2 || dims.count == 3 else {
            throw OmFileFormatSwiftError.requireDimensionsToMatch(required: 3, actual: dims.count)
        }

        if dims.count == 2 {
            // bound x and y
            var dim0X = UInt64(dim0X)
            let dim0Nx = UInt64(dim0Nx)
            var dim0XFraction = dim0XFraction
            if dim0X+2 > dim0Nx {
                dim0X = dim0Nx-2
                dim0XFraction = 1
            }
            var dim0Y = UInt64(dim0Y)
            var dim0YFraction = dim0YFraction
            let dim0Ny = dims[0] / dim0Nx
            if dim0Y+2 > dim0Ny {
                dim0Y = dim0Ny-2
                dim0YFraction = 1
            }

            // reads 4 points. As 2 points are next to each other, we can read a small row of 2 elements at once
            let top = try await read(range: [dim0Y * dim0Nx + dim0X ..< dim0Y * dim0Nx + dim0X + 2, dim1Read])
            let bottom = try await read(range: [(dim0Y + 1) * dim0Nx + dim0X ..< (dim0Y + 1) * dim0Nx + dim0X + 2, dim1Read])

            // interpolate linearly between
            let nt = dim1Read.count
            return zip(zip(top[0..<nt], top[nt..<2*nt]), zip(bottom[0..<nt], bottom[nt..<2*nt])).map {
                let ((a,b),(c,d)) = $0
                return  a * (1-dim0XFraction) * (1-dim0YFraction) +
                        b * (dim0XFraction) * (1-dim0YFraction) +
                        c * (1-dim0XFraction) * (dim0YFraction) +
                        d * (dim0XFraction) * (dim0YFraction)
            }
        }

        // bound x and y
        var dim0X = UInt64(dim0X)
        let dim0Nx = UInt64(dim0Nx)
        var dim0XFraction = dim0XFraction
        if dim0X+2 > dim0Nx {
            dim0X = dim0Nx-2
            dim0XFraction = 1
        }
        var dim0Y = UInt64(dim0Y)
        var dim0YFraction = dim0YFraction
        let dim0Ny = dims[0]
        if dim0Y+2 > dim0Ny {
            dim0Y = dim0Ny-2
            dim0YFraction = 1
        }

        // New 3D files use [y,x,time] and are able to read 2x2xT slices directly
        let data = try await read(range: [dim0Y ..< dim0Y+2, dim0X ..< dim0X+2, dim1Read])
        let nt = dim1Read.count
        return zip(zip(data[0..<nt], data[nt..<2*nt]), zip(data[nt*2..<nt*3], data[nt*3..<nt*4])).map {
            let ((a,b),(c,d)) = $0
            return  a * (1-dim0XFraction) * (1-dim0YFraction) +
                    b * (dim0XFraction) * (1-dim0YFraction) +
                    c * (1-dim0XFraction) * (dim0YFraction) +
                    d * (dim0XFraction) * (dim0YFraction)
        }
    }


    /// Read interpolated between 4 points. If one point is NaN, ignore it.
    /*public func readInterpolatedIgnoreNaN(dim0X: Int, dim0XFraction: Float, dim0Y: Int, dim0YFraction: Float, dim0Nx: Int, dim1 dim1Read: Range<Int>) throws -> [Float] {

        // reads 4 points. As 2 points are next to each other, we can read a small row of 2 elements at once
        let top = try read(dim0Slow: dim0Y * dim0Nx + dim0X ..< dim0Y * dim0Nx + dim0X + 2, dim1: dim1Read)
        let bottom = try read(dim0Slow: (dim0Y + 1) * dim0Nx + dim0X ..< (dim0Y + 1) * dim0Nx + dim0X + 2, dim1: dim1Read)

        // interpolate linearly between
        let nt = dim1Read.count
        return zip(zip(top[0..<nt], top[nt..<2*nt]), zip(bottom[0..<nt], bottom[nt..<2*nt])).map {
            let ((a,b),(c,d)) = $0
            var value: Float = 0
            var weight: Float = 0
            if !a.isNaN {
                value += a * (1-dim0XFraction) * (1-dim0YFraction)
                weight += (1-dim0XFraction) * (1-dim0YFraction)
            }
            if !b.isNaN {
                value += b * (1-dim0XFraction) * (dim0YFraction)
                weight += (1-dim0XFraction) * (dim0YFraction)
            }
            if !c.isNaN {
                value += c * (dim0XFraction) * (1-dim0YFraction)
                weight += (dim0XFraction) * (1-dim0YFraction)
            }
            if !d.isNaN {
                value += d * (dim0XFraction) * (dim0YFraction)
                weight += (dim0XFraction) * (dim0YFraction)
            }
            return weight > 0.001 ? value / weight : .nan
        }
    }*/
}
