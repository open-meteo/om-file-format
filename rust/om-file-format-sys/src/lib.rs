#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

#[cfg(test)]
mod tests {
    use fastpfor::{BlockCodec, FastPForBlock128, FastPForBlock256};
    use std::slice;

    #[test]
    fn test_round_trip_p4n() {
        const n: usize = 3;
        let mut nums = vec![33_u16, 44, 77];
        let mut compressed = vec![0_u8; 1000];
        // TODO: p4bound buffer sizes!
        let mut recovered = vec![0_u16; n + 200];
        unsafe {
            crate::p4nzenc128v16(nums.as_mut_ptr(), 3, compressed.as_mut_ptr());
            crate::p4nzdec128v16(compressed.as_mut_ptr(), n, recovered.as_mut_ptr());
        }
        assert_eq!(recovered[..n], nums[..n]);
    }

    #[test]
    fn test_round_trip_fp32() {
        const n: usize = 3;
        let mut nums = vec![33_u32, 44, 77];
        let mut compressed = vec![0_u8; 1000];
        let mut recovered = vec![0_u32; n];
        unsafe {
            let compressed_size = crate::fpxenc32(nums.as_mut_ptr(), 3, compressed.as_mut_ptr(), 0);
            let decompressed_size =
                crate::fpxdec32(compressed.as_mut_ptr(), n, recovered.as_mut_ptr(), 0);
            assert_eq!(compressed_size, decompressed_size);
        }
        assert_eq!(recovered, nums);
    }

    #[test]
    fn test_round_trip_fp32_with_very_short_length() {
        let data: Vec<f32> = vec![10.0, 22.0, 23.0, 24.0];
        let length = 1; //data.len();

        // create buffers for compression and decompression!
        let mut compressed = vec![0; 1000];
        let mut decompressed = vec![0.0; length];

        // compress data
        let compressed_size = unsafe {
            crate::fpxenc32(
                data.as_ptr() as *mut u32,
                length,
                compressed.as_mut_ptr(),
                0,
            )
        };
        if compressed_size >= compressed.len() {
            panic!("Compress Buffer too small");
        }

        // decompress data
        let decompressed_size = unsafe {
            crate::fpxdec32(
                compressed.as_mut_ptr(),
                length,
                decompressed.as_mut_ptr() as *mut u32,
                0,
            )
        };

        // this should be equal (we check it in the reader)
        // here we have a problem if length is only 1 and the exponent of the
        // float is greater than 0 (e.g. the value is greater than 10)
        // NOTE: This fails with 4 != 5 in the original turbo-pfor library
        assert_eq!(decompressed_size, compressed_size);
        assert_eq!(data[..length], decompressed[..length]);
    }

    #[test]
    fn test_delta2d_decode() {
        let mut buffer: Vec<i16> = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        unsafe { crate::delta2d_decode16(2, 5, buffer.as_mut_ptr()) };
        assert_eq!(buffer, vec![1, 2, 3, 4, 5, 7, 9, 11, 13, 15]);
    }

    #[test]
    fn test_delta2d_encode() {
        let mut buffer: Vec<i16> = vec![1, 2, 3, 4, 5, 7, 9, 11, 13, 15];
        unsafe { crate::delta2d_encode16(2, 5, buffer.as_mut_ptr()) };
        assert_eq!(buffer, vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

        let mut buffer: Vec<u8> = vec![2, 0, 3, 0, 7, 0, 8, 0];
        unsafe { crate::delta2d_encode16(4, 2, buffer.as_mut_ptr() as *mut i16) }
        assert_eq!(&buffer, &[2, 0, 3, 0, 5, 0, 5, 0])
    }

    #[test]
    fn test_delta2d_decode_xor() {
        let mut buffer: Vec<f32> = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
        unsafe { crate::delta2d_decode_xor(2, 5, buffer.as_mut_ptr()) };
        let expected: Vec<f32> = vec![
            1.0,
            2.0,
            3.0,
            4.0,
            5.0,
            2.5521178e38,
            2.0571151e-38,
            3.526483e-38,
            5.2897246e-38,
            4.7019774e-38,
        ];
        assert_eq!(buffer, expected);
    }

    #[test]
    fn test_delta2d_encode_xor() {
        let mut buffer: Vec<f32> = vec![1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 5.0, 11.0, 12.0, 15.0];
        unsafe { crate::delta2d_encode_xor(2, 5, buffer.as_mut_ptr()) };
        let expected: Vec<f32> = vec![
            1.0,
            2.0,
            3.0,
            4.0,
            5.0,
            2.9774707e38,
            1.469368e-38,
            4.4081038e-38,
            7.052966e-38,
            7.6407133e-38,
        ];
        assert_eq!(buffer, expected);
    }

    #[test]
    fn test_delta2d_xor_roundtrip() {
        let mut buffer: Vec<f32> = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
        unsafe {
            crate::delta2d_encode_xor(2, 5, buffer.as_mut_ptr());
            crate::delta2d_decode_xor(2, 5, buffer.as_mut_ptr());
        }
        let expected: Vec<f32> = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
        assert_eq!(buffer, expected);
    }

    #[test]
    fn test_delta2d_roundtrip() {
        let mut buffer: Vec<i16> = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        unsafe {
            crate::delta2d_encode16(2, 5, buffer.as_mut_ptr());
            crate::delta2d_decode16(2, 5, buffer.as_mut_ptr());
        }
        let expected: Vec<i16> = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        assert_eq!(buffer, expected);
    }

    #[test]
    fn test_p4_compatibility_128v16() {
        // Test compatibility between C p4enc128v16 and Rust FastPForBlock128
        let data: Vec<u16> = (0..128).map(|i| (i % 31) as u16).collect();
        let mut input_c = data.clone();
        let mut compressed = vec![0_u8; 1024];
        let mut decompressed_c = vec![0_u16; 128];
        let mut decompressed_rs = vec![0_u32; 128];

        let out_ptr =
            unsafe { crate::p4enc128v16(input_c.as_mut_ptr(), 128, compressed.as_mut_ptr()) };
        let c_size = unsafe { out_ptr.offset_from(compressed.as_ptr()) as usize };

        // Decompress with C
        unsafe {
            crate::p4dec128v16(compressed.as_mut_ptr(), 128, decompressed_c.as_mut_ptr());
        }
        assert_eq!(data, decompressed_c, "C roundtrip failed");

        // Verify with fastpfor-rs block codec (u32 internal)
        let compressed_u32 =
            unsafe { slice::from_raw_parts(compressed.as_ptr() as *const u32, (c_size + 3) / 4) };
        let mut codec = FastPForBlock128::default();
        let mut out_vec = Vec::with_capacity(128);
        codec
            .decode_blocks(compressed_u32, Some(128), &mut out_vec)
            .unwrap();

        let data_u32: Vec<u32> = data.iter().map(|&x| x as u32).collect();
        assert_eq!(
            data_u32, out_vec,
            "fastpfor-rs FastPForBlock128 failed to decode C p4enc128v16 data"
        );
    }

    #[test]
    fn test_p4_compatibility_128v32() {
        let data: Vec<u32> = (0..128).map(|i| (i % 63) as u32).collect();
        let mut input_c = data.clone();
        let mut compressed = vec![0_u8; 1024];
        let mut decompressed_c = vec![0_u32; 128];
        let mut decompressed_rs = vec![0_u32; 128];

        let out_ptr =
            unsafe { crate::p4enc128v32(input_c.as_mut_ptr(), 128, compressed.as_mut_ptr()) };
        let c_size = unsafe { out_ptr.offset_from(compressed.as_ptr()) as usize };

        // Decompress with C
        unsafe {
            crate::p4dec128v32(compressed.as_mut_ptr(), 128, decompressed_c.as_mut_ptr());
        }
        assert_eq!(data, decompressed_c, "C roundtrip failed");

        // Verify with fastpfor-rs
        let compressed_u32 =
            unsafe { slice::from_raw_parts(compressed.as_ptr() as *const u32, (c_size + 3) / 4) };
        let mut codec = FastPForBlock128::default();
        let mut out_vec = Vec::with_capacity(128);
        codec
            .decode_blocks(compressed_u32, Some(128), &mut out_vec)
            .unwrap();

        assert_eq!(
            data, out_vec,
            "fastpfor-rs FastPForBlock128 failed to decode C p4enc128v32 data"
        );
    }

    // #[test]
    // fn test_p4_compatibility_256v32() {
    //     let data: Vec<u32> = (0..256).map(|i| (i % 127) as u32).collect();
    //     let mut input_c = data.clone();
    //     let mut compressed = vec![0_u8; 2048];
    //     let mut decompressed_c = vec![0_u32; 256];
    //     let mut decompressed_rs = vec![0_u32; 256];

    //     let out_ptr =
    //         unsafe { crate::p4enc256v32(input_c.as_mut_ptr(), 256, compressed.as_mut_ptr()) };
    //     let c_size = unsafe { out_ptr.offset_from(compressed.as_ptr()) as usize };

    //     // Decompress with C
    //     unsafe {
    //         crate::p4dec256v32(compressed.as_mut_ptr(), 256, decompressed_c.as_mut_ptr());
    //     }
    //     assert_eq!(data, decompressed_c, "C roundtrip failed");

    //     // Verify with fastpfor-rs
    //     let compressed_u32 =
    //         unsafe { slice::from_raw_parts(compressed.as_ptr() as *const u32, (c_size + 3) / 4) };
    //     let mut codec = FastPForBlock256::default();
    //     let mut out_vec = Vec::with_capacity(256);
    //     codec
    //         .decode_blocks(compressed_u32, Some(256), &mut out_vec)
    //         .unwrap();

    //     assert_eq!(
    //         data, out_vec,
    //         "fastpfor-rs FastPForBlock256 failed to decode C p4enc256v32 data"
    //     );
    // }
}
