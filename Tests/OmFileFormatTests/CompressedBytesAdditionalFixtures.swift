// Additional fixed wire bytes. Input recipes live in the main suite; none of
// these expected streams are produced by a codec at test time. Keep the bytes
// pinned across platforms and investigate failures before changing a fixture.
//
// Coverage: scalar/SIMD and second-block boundaries; packed-width transitions
// (including 31/32/33 and 62/63/64); variable-byte seed thresholds; modular
// wraparound; sparse/dense exceptions; IEEE zeros, subnormals, finite extrema,
// infinities, and distinct signed quiet/signaling NaN bit patterns.
extension CompressedBytesCompatibilityTests {
    static let additionalFixtures: [Fixture] = [
        // 8-bit delta
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 2, hex: "0000", label: "boundary-2"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 31, hex: "000124499224", label: "boundary-31"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 32, hex: "000124499224", label: "boundary-32"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 33, hex: "000124499224", label: "boundary-33"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 127, hex: "000124499224499224499224499224499224", label: "boundary-127"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 128, hex: "000124499224499224499224499224499224", label: "boundary-128"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 129, hex: "000124499224499224499224499224499224", label: "boundary-129"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 255, hex: "0001244992244992244992244992244992240149922449922449922449922449922409", label: "boundary-255"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 256, hex: "0001244992244992244992244992244992240149922449922449922449922449922449", label: "boundary-256"),
        Fixture(bits: 8, codec: .delta, pattern: .boundary, count: 257, hex: "0001244992244992244992244992244992240149922449922449922449922449922449", label: "boundary-257"),
        // 8-bit zigzag
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 2, hex: "00c202", label: "boundary-2"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 31, hex: "0003927449ba245d922e4997a403", label: "boundary-31"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 32, hex: "0003927449ba245d922e4997a40b", label: "boundary-32"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 33, hex: "0003927449ba245d922e4997a44b", label: "boundary-33"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 127, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7401
            """, label: "boundary-127"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 128, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7409
            """, label: "boundary-128"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 129, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7449
            """, label: "boundary-129"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 255, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            744903ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba2401
            """, label: "boundary-255"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 256, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            744903ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba241d
            """, label: "boundary-256"),
        Fixture(bits: 8, codec: .zigzag, pattern: .boundary, count: 257, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            744903ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba245d
            """, label: "boundary-257"),
        // 8-bit pfor
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 2, hex: "0102", label: "boundary-2"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 31, hex: "0388464423a211d18868443402", label: "boundary-31"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 32, hex: "0388464423a211d18868443422", label: "boundary-32"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 33, hex: "0388464423a211d1886844342202", label: "boundary-33"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 127, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            04
            """, label: "boundary-127"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 128, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44
            """, label: "boundary-128"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 129, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44c203
            """, label: "boundary-129"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 255, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-255"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 256, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-256"),
        Fixture(bits: 8, codec: .pfor, pattern: .boundary, count: 257, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211c101
            """, label: "boundary-257"),
        Fixture(bits: 8, codec: .pfor, pattern: .packedWidth(1), count: 128, hex: "0155555555555555555555555555555555", label: "packed-width-1"),
        Fixture(bits: 8, codec: .pfor, pattern: .packedWidth(2), count: 128, hex: "021b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b", label: "packed-width-2"),
        Fixture(bits: 8, codec: .pfor, pattern: .packedWidth(3), count: 128, hex: """
            037378157378157378157378157378157378157378157378157378157378157378157378157378157378157378157378
            15
            """, label: "packed-width-3"),
        Fixture(bits: 8, codec: .pfor, pattern: .packedWidth(7), count: 128, hex: """
            07034b8a7755f7212b5f94fc97947053739e71d235c17b4788f614d711235b927b5774604b6f9cf09115b173438675d4
            b6011b5790fa165450436b9a7f51f5a06b7f84f49396f113538e79d637403b6798fe10d590637b82735376e10b4f8cf8
            9517303363967dd0b4805b7780f21256d1
            """, label: "packed-width-7"),
        Fixture(bits: 8, codec: .pfor, pattern: .packedWidth(8), count: 128, hex: """
            080316293c576a7d90abbed1e4ff1225385366798ca7bacde0fb0e21344f627588a3b6c9dcf70a1d304b5e71849fb2c5
            d8f306192c475a6d809baec1d4ef0215284356697c97aabdd0ebfe11243f52657893a6b9cce7fa0d203b4e61748fa2b5
            c8e3f6091c374a5d708b9eb1c4dff205183346596c879aadc0dbee01142f425568
            """, label: "packed-width-8"),
        // 8-bit delta
        Fixture(bits: 8, codec: .delta, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 8-bit zigzag
        Fixture(bits: 8, codec: .zigzag, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 8-bit delta
        Fixture(bits: 8, codec: .delta, pattern: .literal([0x80]), count: 1, hex: "80", label: "seed-80"),
        // 8-bit zigzag
        Fixture(bits: 8, codec: .zigzag, pattern: .literal([0x80]), count: 1, hex: "80", label: "seed-80"),
        // 8-bit delta
        Fixture(bits: 8, codec: .delta, pattern: .wraparound, count: 129, hex: "fdc203", label: "wraparound"),
        Fixture(bits: 8, codec: .delta, pattern: .exceptionEdges, count: 129, hex: """
            fd820503000000000000c003000000000000c01042082184e0e4e4e4e4e4e4e4e4e4e4e4e4e4e404e0e4e4e4e4e4e4e4
            e4e4e4e4e4e4e404
            """, label: "exceptionEdges"),
        Fixture(bits: 8, codec: .delta, pattern: .denseExceptions, count: 129, hex: """
            fd82054992244992244992244992244992244910420821841042082184104208218410420821841042082184104224c4
            e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4
            """, label: "denseExceptions"),
        // 8-bit zigzag
        Fixture(bits: 8, codec: .zigzag, pattern: .wraparound, count: 129, hex: "fdc306", label: "wraparound"),
        Fixture(bits: 8, codec: .zigzag, pattern: .exceptionEdges, count: 129, hex: """
            fd830503000000000000c003000000000000c01042082184000dd1100dd1100dd1100dd1100dd1100dd1100dd1100d01
            000dd1100dd1100dd1100dd1100dd1100dd1100dd1100d01
            """, label: "exceptionEdges"),
        Fixture(bits: 8, codec: .zigzag, pattern: .denseExceptions, count: 129, hex: """
            fd8305499224499224499224499224499224491042082184104208218410420821841042082184104208218410421001
            c1000d11100cd01001c1000d11100cd01001c1000d11100cd01001c1000d11100cd01001c1000d11100cd01001c1
            """, label: "denseExceptions"),
        // 8-bit pfor
        Fixture(bits: 8, codec: .pfor, pattern: .wraparound, count: 128, hex: """
            08fd000306090c0f1215181b1e2124272a2d303336393c3f4245484b4e5154575a5d606366696c6f7275787b7e818487
            8a8d909396999c9fa2a5a8abaeb1b4b7babdc0c3c6c9cccfd2d5d8dbdee1e4e7eaedf0f3f6f9fcff0205080b0e111417
            1a1d202326292c2f3235383b3e4144474a4d505356595c5f6265686b6e7174777a
            """, label: "wraparound"),
        Fixture(bits: 8, codec: .pfor, pattern: .exceptionEdges, count: 128, hex: """
            820503000000000000c003000000000000c01042082184e0e4e4e4e4e4e4e4e4e4e4e4e4e4e404e0e4e4e4e4e4e4e4e4
            e4e4e4e4e4e404
            """, label: "exceptionEdges"),
        Fixture(bits: 8, codec: .pfor, pattern: .denseExceptions, count: 128, hex: """
            82054992244992244992244992244992244910420821841042082184104208218410420821841042082184104224c4e0
            24c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4
            """, label: "denseExceptions"),
        // 16-bit delta
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 2, hex: "0000", label: "boundary-2"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 31, hex: "000124499224", label: "boundary-31"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 32, hex: "000124499224", label: "boundary-32"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 33, hex: "000124499224", label: "boundary-33"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 127, hex: "000124499224499224499224499224499224", label: "boundary-127"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 128, hex: "000124499224499224499224499224499224", label: "boundary-128"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 129, hex: "000192242449499292242449499292242449", label: "boundary-129"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 255, hex: "0001922424494992922424494992922424490149922449922449922449922449922409", label: "boundary-255"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 256, hex: "0001922424494992922424494992922424490149922449922449922449922449922449", label: "boundary-256"),
        Fixture(bits: 16, codec: .delta, pattern: .boundary, count: 257, hex: "0001922424494992922424494992922424490149929224244949929224244949929224", label: "boundary-257"),
        // 16-bit zigzag
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 2, hex: "00c202", label: "boundary-2"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 31, hex: "0003927449ba245d922e4997a403", label: "boundary-31"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 32, hex: "0003927449ba245d922e4997a40b", label: "boundary-32"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 33, hex: "0003927449ba245d922e4997a44b", label: "boundary-33"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 127, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7401
            """, label: "boundary-127"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 128, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7409
            """, label: "boundary-128"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 129, hex: """
            0003922eba249274d22597a4922eba24927449975d9249bae9924bd249975d9249baa44b2e49245d744925e9a44b2e49
            245d
            """, label: "boundary-129"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 255, hex: """
            0003922eba249274d22597a4922eba24927449975d9249bae9924bd249975d9249baa44b2e49245d744925e9a44b2e49
            245d03ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba2401
            """, label: "boundary-255"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 256, hex: """
            0003922eba249274d22597a4922eba24927449975d9249bae9924bd249975d9249baa44b2e49245d744925e9a44b2e49
            245d03ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba241d
            """, label: "boundary-256"),
        Fixture(bits: 16, codec: .zigzag, pattern: .boundary, count: 257, hex: """
            0003922eba249274d22597a4922eba24927449975d9249bae9924bd249975d9249baa44b2e49245d744925e9a44b2e49
            245d03d22597a4922eba249274d22597a4922ee9924bd249975d9249bae9924bd24997744925e9a44b2e49245d744925
            e9a44b
            """, label: "boundary-257"),
        // 16-bit pfor
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 2, hex: "0102", label: "boundary-2"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 31, hex: "0388464423a211d18868443402", label: "boundary-31"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 32, hex: "0388464423a211d18868443422", label: "boundary-32"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 33, hex: "0388464423a211d1886844342202", label: "boundary-33"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 127, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            04
            """, label: "boundary-127"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 128, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44
            """, label: "boundary-128"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 129, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44c203
            """, label: "boundary-129"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 255, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-255"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 256, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-256"),
        Fixture(bits: 16, codec: .pfor, pattern: .boundary, count: 257, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211c101
            """, label: "boundary-257"),
        // 16-bit pforSIMD
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 2, hex: "0102", label: "boundary-2"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 31, hex: "0388464423a211d18868443402", label: "boundary-31"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 32, hex: "0388464423a211d18868443422", label: "boundary-32"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 33, hex: "0388464423a211d1886844342202", label: "boundary-33"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 127, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            04
            """, label: "boundary-127"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 128, hex: """
            035828a1b0c2420b8514165828a1b0c2422c14505861a185c20a0b2c14505861a1160a282cb05042618585160a282cb0
            50
            """, label: "boundary-128"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 129, hex: """
            035828a1b0c2420b8514165828a1b0c2422c14505861a185c20a0b2c14505861a1160a282cb05042618585160a282cb0
            50c203
            """, label: "boundary-129"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 255, hex: """
            035828a1b0c2420b8514165828a1b0c2422c14505861a185c20a0b2c14505861a1160a282cb05042618585160a282cb0
            500323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-255"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 256, hex: """
            035828a1b0c2420b8514165828a1b0c2422c14505861a185c20a0b2c14505861a1160a282cb05042618585160a282cb0
            50030b8514165828a1b0c2420b851416582885c20a0b2c14505861a185c20a0b2c1442618585160a282cb05042618585
            160a
            """, label: "boundary-256"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .boundary, count: 257, hex: """
            035828a1b0c2420b8514165828a1b0c2422c14505861a185c20a0b2c14505861a1160a282cb05042618585160a282cb0
            50030b8514165828a1b0c2420b851416582885c20a0b2c14505861a185c20a0b2c1442618585160a282cb05042618585
            160ac101
            """, label: "boundary-257"),
        // 16-bit pfor
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(1), count: 128, hex: "0155555555555555555555555555555555", label: "packed-width-1"),
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(2), count: 128, hex: "021b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b", label: "packed-width-2"),
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(3), count: 128, hex: """
            037378157378157378157378157378157378157378157378157378157378157378157378157378157378157378157378
            15
            """, label: "packed-width-3"),
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(7), count: 128, hex: """
            07034b8a7755f7212b5f94fc97947053739e71d235c17b4788f614d711235b927b5774604b6f9cf09115b173438675d4
            b6011b5790fa165450436b9a7f51f5a06b7f84f49396f113538e79d637403b6798fe10d590637b82735376e10b4f8cf8
            9517303363967dd0b4805b7780f21256d1
            """, label: "packed-width-7"),
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(8), count: 128, hex: """
            080316293c576a7d90abbed1e4ff1225385366798ca7bacde0fb0e21344f627588a3b6c9dcf70a1d304b5e71849fb2c5
            d8f306192c475a6d809baec1d4ef0215284356697c97aabdd0ebfe11243f52657893a6b9cce7fa0d203b4e61748fa2b5
            c8e3f6091c374a5d708b9eb1c4dff205183346596c879aadc0dbee01142f425568
            """, label: "packed-width-8"),
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(9), count: 128, hex: """
            09032da6e479556d5fc8ab7d4727ff5f42091c53cce461744a573370fb1c86a4f9546c5dc4a36d27e77e5f4107184bbc
            c421f44956316cf30c666479546b5bc09b5d07a7fe5e40051443aca4e17349552f68ebfc4524f9536a59bc934de7667e
            5e7f03103b9c84a1f348542d64e3ec25e478536957b88b3dc726fe5d7e010c338c64617348532b60dbdc05a4f8526855
            b4
            """, label: "packed-width-9"),
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(15), count: 128, hex: """
            0f036d8b484a852773d5510bf4152013ab0ddf58748d3cf7df930095907050532c33681e95117bcad5053613c191fb4c
            8779c89d66fff4171bd79d11d7a36fdb49f2857b73ff5110741860144b0e2f599c8d50f7e99315159bb055f32e835646
            94a57a94d5eab605018b9b49d766709cbafe9e17e0578051c843682b761a848f728951e5f402a009eb087f46c48ce4f6
            b393fa958df04e932bd357ee94f97abed5ff3608418c3b4a2767989ccefea817f5d78a91cde36a7b77429b23725351ca
            7475e0028b05cf446c8338f65d93cf15f0304033242354168b0d7a48d5c4b6728181db447764c09362fe7217da57fdd1
            c6
            """, label: "packed-width-15"),
        Fixture(bits: 16, codec: .pfor, pattern: .packedWidth(16), count: 128, hex: """
            1003ed169129153c99571d6a817d059089ab0dbeb1d135e4b9ff3d12a0252438a8532c66d079548cd8a75cbac0cd44e0
            c8fb4c0ef3217734fb4f7f62e3756788eba36fb613c997dc1bf79f0a021d86300a4b8e5e3271b6843a9fbeb222c5a6d8
            2af3ae062d19d12c5547d95a5d6dc180459bc9ae4dc1f1d475eff9027c15e0286443e8566c69107c949718aa9cbd00d0
            84eb08fe8c113324b73f3b52bf652378a7932ba6afb953ccd7e75bfadf0d4220c63b4a4ece617274f68f7aa2feb562c8
            e6e36af6ee096d1c1137954a195d9d70018b859e09b18dc431dfb5f23905bc182033a4462859ac6c5087d49a58addcc0
            40dbc4ee4801cf14732ff7427b55ff6863
            """, label: "packed-width-16"),
        // 16-bit pforSIMD
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(1), count: 128, hex: "01ffff0000ffff0000ffff0000ffff0000", label: "packed-width-1"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(2), count: 128, hex: "02ffffaaaa55550000ffffaaaa55550000ffffaaaa55550000ffffaaaa55550000", label: "packed-width-2"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(3), count: 128, hex: """
            03dbb6b66d49922449ffff92246ddb00006ddbdbb624499224ffff4992b66d0000b66d6ddb92244992ffff2449dbb600
            00
            """, label: "packed-width-3"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(7), count: 128, hex: """
            0783d5169fa9683c32d7ff6a89fd52101c743fd9613e9483c6e9794eacb3de18015acef31a8c6725b0ff1c906929b6c3
            0237c35c5682e9a87cdf97052a2bbd5050f564bfc9482e1293dff9a95e72a33c08375e69f79c88ce2171fba494d62d09
            c7ccb618dd6503b2291e5e6b84b4aa00d1
            """, label: "packed-width-7"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(8), count: 128, hex: """
            0803ab16be29d13ce457ff6a127d25903853fb660e79218c34a74fba62cd75e088a34bb65ec971dc84f79f0ab21dc530
            d8f39b06ae19c12cd447ef5a026d15802843eb56fe69117c24973faa52bd65d078933ba64eb961cc74e78ffaa20db520
            c8e38bf69e09b11cc437df4af25d05701833db46ee59016c14872f9a42ad55c068
            """, label: "packed-width-8"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(9), count: 128, hex: """
            090357167d29a33cc957ff6a257d4b90714fd99b71e70933a29f7ae81234ab8043377a68db993cc99d7affab40dba10c
            03c9bc8b414ec6104bd3d1965658db1b60cd43d756e069ea7cf79701aa0abd14d0d64dfc9922e648327e9ea4eaca36f0
            82de3176620e93a7c37f7417a5a8d540066ef1cfb330769138f3fb54beb54017038c6d117796801b8aa19726a1abaa30
            b4
            """, label: "packed-width-9"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(15), count: 128, hex: """
            0f03ed161129953c19579d6a017d859009d5c6df98e85af21cffde099012521c14146b19d41e35239629f72e5033b138
            129f39616ee49e66cfe97f6caceedc710dfa5e3bf17c89bd21fff920906128a3c072cc9219b365d4b1f41d156936b556
            01bb36b45c448354a965df7505052b165193439b56e369eb7cf397f8aac0bdc8d0e8756c7f90881492989f1ca980b204
            bcc4e486e959ee1bf3ddf99ffe518313886a47cbc9344c95cef65157d4b05611d939ae69ef9ed0ce117f53af94dcd50c
            175e2cf64c8e6d218ef9ae91cf29e0c000cc9018a164b1b1411d526962b5720103b689dc91029e29e65fee85f6abfed1
            c6
            """, label: "packed-width-15"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .packedWidth(16), count: 128, hex: """
            1003ed169129153c99571d6a817d059089ab0dbeb1d135e4b9ff3d12a0252438a8532c66d079548cd8a75cbac0cd44e0
            c8fb4c0ef3217734fb4f7f62e3756788eba36fb613c997dc1bf79f0a021d86300a4b8e5e3271b6843a9fbeb222c5a6d8
            2af3ae062d19d12c5547d95a5d6dc180459bc9ae4dc1f1d475eff9027c15e0286443e8566c69107c949718aa9cbd00d0
            84eb08fe8c113324b73f3b52bf652378a7932ba6afb953ccd7e75bfadf0d4220c63b4a4ece617274f68f7aa2feb562c8
            e6e36af6ee096d1c1137954a195d9d70018b859e09b18dc431dfb5f23905bc182033a4462859ac6c5087d49a58addcc0
            40dbc4ee4801cf14732ff7427b55ff6863
            """, label: "packed-width-16"),
        // 16-bit delta
        Fixture(bits: 16, codec: .delta, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 16-bit zigzag
        Fixture(bits: 16, codec: .zigzag, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 16-bit delta
        Fixture(bits: 16, codec: .delta, pattern: .literal([0x80]), count: 1, hex: "8080", label: "seed-80"),
        // 16-bit zigzag
        Fixture(bits: 16, codec: .zigzag, pattern: .literal([0x80]), count: 1, hex: "8080", label: "seed-80"),
        // 16-bit delta
        Fixture(bits: 16, codec: .delta, pattern: .literal([0x3fff]), count: 1, hex: "bfff", label: "seed-3fff"),
        // 16-bit zigzag
        Fixture(bits: 16, codec: .zigzag, pattern: .literal([0x3fff]), count: 1, hex: "bfff", label: "seed-3fff"),
        // 16-bit delta
        Fixture(bits: 16, codec: .delta, pattern: .literal([0x4000]), count: 1, hex: "c00040", label: "seed-4000"),
        // 16-bit zigzag
        Fixture(bits: 16, codec: .zigzag, pattern: .literal([0x4000]), count: 1, hex: "c00040", label: "seed-4000"),
        // 16-bit delta
        Fixture(bits: 16, codec: .delta, pattern: .wraparound, count: 129, hex: "c0fdffc203", label: "wraparound"),
        Fixture(bits: 16, codec: .delta, pattern: .exceptionEdges, count: 129, hex: """
            c0fdff420800005455aaaaffff00005555aa2aff3f00005455aaaaffff00005555aa2aff3fc04fc04fc04fc04fc04fc0
            4fc04fc04f00013e3f40417e7f
            """, label: "exceptionEdges"),
        Fixture(bits: 16, codec: .delta, pattern: .denseExceptions, count: 129, hex: """
            c0fdff820d49922449922449922449922449922449001000024000080001200004800010000240000800012000048000
            10000240000800012000048000100002400008000120000480001000024000080001200004800010000240000051148a
            a23ccf00004551288af33c00004551288af33c00001445a228cff3
            """, label: "denseExceptions"),
        // 16-bit zigzag
        Fixture(bits: 16, codec: .zigzag, pattern: .wraparound, count: 129, hex: "c0fdffc306", label: "wraparound"),
        Fixture(bits: 16, codec: .zigzag, pattern: .exceptionEdges, count: 129, hex: """
            c0fdff4308000090242449b66d000092242449b66d000049909224dbb60000499212241bb60000244949926ddb000024
            4949126d1bc04fc04fc04fc04fc04fc04fc04fc04f00013e3f40417e7f
            """, label: "exceptionEdges"),
        Fixture(bits: 16, codec: .zigzag, pattern: .denseExceptions, count: 129, hex: """
            c0fdff830d49922449922449922449922449922449001000024000080001200004800010000240000800012000048000
            100002400008000120000480001000024000080001200004800010000240000800012000048000100002400000820424
            48b061000012242041860d000009129020c3860000489082041b360000244841820d1b0000204109126cd8
            """, label: "denseExceptions"),
        // 16-bit pfor
        Fixture(bits: 16, codec: .pfor, pattern: .wraparound, count: 128, hex: """
            4901fd010c309080c1030915306cf01082c409152d60ccb09183c70f2145902c711285ca152d5dc08c319386cd1b3975
            f0ecf11388d021458d204db29489d32751a550ad72158bd62d5dbd800d33968cd93369d5b06df3168edc3975ede0cdb3
            978fdf3f8105112e741891e2458d1d418e349992e54b993571eef41994e851a54da14eb59a95eb57b165d1ae751b97ee
            5dbd7f00
            """, label: "wraparound"),
        Fixture(bits: 16, codec: .pfor, pattern: .exceptionEdges, count: 128, hex: """
            4208e0e4e4e4e4e4e4e4e4e4e4e4e4e4e404e0e4e4e4e4e4e4e4e4e4e4e4e4e4e404c04fc04fc04fc04fc04fc04fc04f
            c04f00013e3f40417e7f
            """, label: "exceptionEdges"),
        Fixture(bits: 16, codec: .pfor, pattern: .denseExceptions, count: 128, hex: """
            820d49922449922449922449922449922449001000024000080001200004800010000240000800012000048000100002
            4000080001200004800010000240000800012000048000100002400008000120000480001000024024c4e024c4e024c4
            e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4
            """, label: "denseExceptions"),
        // 16-bit pforSIMD
        Fixture(bits: 16, codec: .pforSIMD, pattern: .wraparound, count: 128, hex: """
            4901fd2b00300336063c09420c480f4e1254b428c040cc58d870e488f0a0fcb808d1d2a50206326662c69226c286f2e6
            22474ea30f24cfa48f2550a61027d0a7912852bd54c055c357c658c95acc5bcf5dd2aab5b0c1b6cdbcd9c2e5c8f1cefd
            d4092bd843085b3873688b98a3c8bbf8d428b166122772e7d2a732689228f2e853a9d3b254b4d4b555b7d6b857bad7bb
            58bd7f00
            """, label: "wraparound"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .exceptionEdges, count: 128, hex: """
            420800005455aaaaffff00005555aa2aff3f00005455aaaaffff00005555aa2aff3fc04fc04fc04fc04fc04fc04fc04f
            c04f00013e3f40417e7f
            """, label: "exceptionEdges"),
        Fixture(bits: 16, codec: .pforSIMD, pattern: .denseExceptions, count: 128, hex: """
            820d49922449922449922449922449922449001000024000080001200004800010000240000800012000048000100002
            40000800012000048000100002400008000120000480001000024000080001200004800010000240000051148aa23ccf
            00004551288af33c00004551288af33c00001445a228cff3
            """, label: "denseExceptions"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 2, hex: "0000", label: "boundary-2"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 31, hex: "000124499224", label: "boundary-31"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 32, hex: "000124499224", label: "boundary-32"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 33, hex: "000124499224", label: "boundary-33"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 127, hex: "000124499224499224499224499224499224", label: "boundary-127"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 128, hex: "000124499224499224499224499224499224", label: "boundary-128"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 129, hex: "000124499224922449924992244924499224", label: "boundary-129"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 255, hex: "0001244992249224499249922449244992240149922449922449922449922449922409", label: "boundary-255"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 256, hex: "0001244992249224499249922449244992240149922449922449922449922449922449", label: "boundary-256"),
        Fixture(bits: 32, codec: .delta, pattern: .boundary, count: 257, hex: "0001244992249224499249922449244992240149922449244992249224499249922449", label: "boundary-257"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 2, hex: "00c202", label: "boundary-2"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 31, hex: "0003927449ba245d922e4997a403", label: "boundary-31"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 32, hex: "0003927449ba245d922e4997a40b", label: "boundary-32"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 33, hex: "0003927449ba245d922e4997a44b", label: "boundary-33"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 127, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7401
            """, label: "boundary-127"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 128, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7409
            """, label: "boundary-128"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 129, hex: """
            0003ba245d92d225e992922e4997927449ba2e4997a47449ba24a44bd225245d922e4bd225e95d922e49e99274494997
            a44b
            """, label: "boundary-129"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 255, hex: """
            0003ba245d92d225e992922e4997927449ba2e4997a47449ba24a44bd225245d922e4bd225e95d922e49e99274494997
            a44b03ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba2401
            """, label: "boundary-255"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 256, hex: """
            0003ba245d92d225e992922e4997927449ba2e4997a47449ba24a44bd225245d922e4bd225e95d922e49e99274494997
            a44b03ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba241d
            """, label: "boundary-256"),
        Fixture(bits: 32, codec: .zigzag, pattern: .boundary, count: 257, hex: """
            0003ba245d92d225e992922e4997927449ba2e4997a47449ba24a44bd225245d922e4bd225e95d922e49e99274494997
            a44b03927449ba97a44bd2ba245d92d225e992245d922e25e992742e4997a47449ba244997a44b49ba245d4bd225e95d
            922e49
            """, label: "boundary-257"),
        // 32-bit pfor
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 2, hex: "0102", label: "boundary-2"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 31, hex: "0388464423a211d18868443402", label: "boundary-31"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 32, hex: "0388464423a211d18868443422", label: "boundary-32"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 33, hex: "0388464423a211d1886844342202", label: "boundary-33"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 127, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            04
            """, label: "boundary-127"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 128, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44
            """, label: "boundary-128"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 129, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44c203
            """, label: "boundary-129"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 255, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-255"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 256, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-256"),
        Fixture(bits: 32, codec: .pfor, pattern: .boundary, count: 257, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211c101
            """, label: "boundary-257"),
        // 32-bit pforSIMD
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 2, hex: "0102", label: "boundary-2"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 31, hex: "0388464423a211d18868443402", label: "boundary-31"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 32, hex: "0388464423a211d18868443422", label: "boundary-32"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 33, hex: "0388464423a211d1886844342202", label: "boundary-33"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 127, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            04
            """, label: "boundary-127"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 128, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e
            """, label: "boundary-128"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 129, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4ec203
            """, label: "boundary-129"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 255, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e0323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-255"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 256, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e0353c029e09c024e01e014700a01a7805314700a38a78053c038059c02c029e014059c024e29e014704e01a780700a
            3805
            """, label: "boundary-256"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .boundary, count: 257, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e0353c029e09c024e01e014700a01a7805314700a38a78053c038059c02c029e014059c024e29e014704e01a780700a
            3805c101
            """, label: "boundary-257"),
        // 32-bit fpx
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 2, hex: "1f0102", label: "boundary-2"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 31, hex: "1d03a0f9d07c683e341f9a0fcd07", label: "boundary-31"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 32, hex: "1d03a0f9d07c683e341f9a0fcd87", label: "boundary-32"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 33, hex: "1d03a0f9d07c683e341f9a0fcd8706", label: "boundary-33"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 127, hex: """
            1d03a0f9d07c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1
            f910
            """, label: "boundary-127"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 128, hex: """
            1d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d3
            """, label: "boundary-128"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 129, hex: """
            1d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d31fc101
            """, label: "boundary-129"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 255, hex: """
            1d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d31d037c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1f9
            d07c681e
            """, label: "boundary-255"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 256, hex: """
            1d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d31d0334739a39a799d3cc39cd9c66cc69e634cd9c664e69e634734e33a799739a39cd33a799d39a39cd9cd3cc69e6
            9c664e33
            """, label: "boundary-256"),
        Fixture(bits: 32, codec: .fpx, pattern: .boundary, count: 257, hex: """
            1d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d31d0334739a39a799d3cc39cd9c66cc69e634cd9c664e69e634734e33a799739a39cd33a799d39a39cd9cd3cc69e6
            9c664e331fc101
            """, label: "boundary-257"),
        // 32-bit pfor
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(1), count: 128, hex: "0155555555555555555555555555555555", label: "packed-width-1"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(2), count: 128, hex: "021b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b", label: "packed-width-2"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(3), count: 128, hex: """
            037378157378157378157378157378157378157378157378157378157378157378157378157378157378157378157378
            15
            """, label: "packed-width-3"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(7), count: 128, hex: """
            07034b8a7755f7212b5f94fc97947053739e71d235c17b4788f614d711235b927b5774604b6f9cf09115b173438675d4
            b6011b5790fa165450436b9a7f51f5a06b7f84f49396f113538e79d637403b6798fe10d590637b82735376e10b4f8cf8
            9517303363967dd0b4805b7780f21256d1
            """, label: "packed-width-7"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(8), count: 128, hex: """
            080316293c576a7d90abbed1e4ff1225385366798ca7bacde0fb0e21344f627588a3b6c9dcf70a1d304b5e71849fb2c5
            d8f306192c475a6d809baec1d4ef0215284356697c97aabdd0ebfe11243f52657893a6b9cce7fa0d203b4e61748fa2b5
            c8e3f6091c374a5d708b9eb1c4dff205183346596c879aadc0dbee01142f425568
            """, label: "packed-width-8"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(9), count: 128, hex: """
            09032da6e479556d5fc8ab7d4727ff5f42091c53cce461744a573370fb1c86a4f9546c5dc4a36d27e77e5f4107184bbc
            c421f44956316cf30c666479546b5bc09b5d07a7fe5e40051443aca4e17349552f68ebfc4524f9536a59bc934de7667e
            5e7f03103b9c84a1f348542d64e3ec25e478536957b88b3dc726fe5d7e010c338c64617348532b60dbdc05a4f8526855
            b4
            """, label: "packed-width-9"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(15), count: 128, hex: """
            0f036d8b484a852773d5510bf4152013ab0ddf58748d3cf7df930095907050532c33681e95117bcad5053613c191fb4c
            8779c89d66fff4171bd79d11d7a36fdb49f2857b73ff5110741860144b0e2f599c8d50f7e99315159bb055f32e835646
            94a57a94d5eab605018b9b49d766709cbafe9e17e0578051c843682b761a848f728951e5f402a009eb087f46c48ce4f6
            b393fa958df04e932bd357ee94f97abed5ff3608418c3b4a2767989ccefea817f5d78a91cde36a7b77429b23725351ca
            7475e0028b05cf446c8338f65d93cf15f0304033242354168b0d7a48d5c4b6728181db447764c09362fe7217da57fdd1
            c6
            """, label: "packed-width-15"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(16), count: 128, hex: """
            1003ed169129153c99571d6a817d059089ab0dbeb1d135e4b9ff3d12a0252438a8532c66d079548cd8a75cbac0cd44e0
            c8fb4c0ef3217734fb4f7f62e3756788eba36fb613c997dc1bf79f0a021d86300a4b8e5e3271b6843a9fbeb222c5a6d8
            2af3ae062d19d12c5547d95a5d6dc180459bc9ae4dc1f1d475eff9027c15e0286443e8566c69107c949718aa9cbd00d0
            84eb08fe8c113324b73f3b52bf652378a7932ba6afb953ccd7e75bfadf0d4220c63b4a4ece617274f68f7aa2feb562c8
            e6e36af6ee096d1c1137954a195d9d70018b859e09b18dc431dfb5f23905bc182033a4462859ac6c5087d49a58addcc0
            40dbc4ee4801cf14732ff7427b55ff6863
            """, label: "packed-width-16"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(17), count: 128, hex: """
            1103ed2c22a554e0c97cd5512d505f01c8c4ab0d7d6345d720cffddf53025409091cd4532ccda0e55161c47eca551758
            331170e4fb4c1de685dca1d9fff4576c5cdd19c4f5a36f6d27265fe2de70ff594160872118054b8ebd64c6d922d4f1e9
            5b5664b1296c15f3ae0d5a664463a972945dab6b5b30c0229bc95d9b06c7a3aef39e5f806f0538143243e8add8a641e4
            a374894195732f406842eb08fc1947cc24b9f5b343ea77d948bc53932b4c5fe74e65be76be45ff7b835010633b4a9c9c
            87c9a5b3f7a847d47fad586473e36aecdd27b4e58878534929435767b8808b853c13c436268ef95d4b3e47016f0c9033
            a48c5064b166837a484d134b2b7760a0dbc4dc91043ca798fb724f684fd57fb4b1
            """, label: "packed-width-17"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(31), count: 128, hex: """
            1f03ed92518b486c574a85c18b27b38975d5b1cb520b346ff515b0a820133755ab0dc12bdf580654748d5e8a3c3734f5
            dff36e9200d53a9590009e70509f49532c3525336830511e95ab8811bb6274ca3504d20576043513d187c091477cfb4c
            693f8779ea5fc89d008f663fa9f7f477db131b17d7d59da1ec10d72f77a36fdd38db89855cf2a59d8d7b83d776ffb97e
            531088a2751872d26014946b4b8e31322f99bf599cadea8c500702f6e9fb159315298c159bc23bb0557c1ef3ae650c83
            96694646b44783a58a4871943dabd0eaca5fb4059320008b24119bc9d909d7a6034370bcdc81ba0ef7f09e7f4e10e06b
            295480631650c88c0543e80d032bb63d401a4428808f923d7089a1e551e50cf4f4023c7fa0097538eb08601d7fc6d74e
            c44c8586e41668f3b3e3b891faadc7948d8c64f04edd2c932bd416d3d7814bee541285f99a9672be255ed1ff4e913408
            5d4a408c85273b4a081027e7bb48985c6f84ce1eddfda867f516f5ef7cd78a2db391cd6ddae36a7c6a7bf75575425bc4
            9a23e20b7d53a98856ca804f7775fe98e102cace8b85d067cf040f726c6351993866b6fc5deb2f96cf211917f04e8e31
            40b2c133a404612314397f166bae9f0deafc7f482dc5d7c4c2e4b7721ff781811af4dbc4787b7724d37dc0733b9e626e
            2bff726f9817da63b657fdefdcd1c6c2e8
            """, label: "packed-width-31"),
        Fixture(bits: 32, codec: .pfor, pattern: .packedWidth(32), count: 128, hex: """
            2003ed92d11691d8ae2915062f3c994dac571dbb2c6a81e6ad7d052c2a90899baaab0dc12bbeb10ca8d1357a29e4b9a1
            a9ff3def2612a05aa72524802738a8cfa4532c352566d060a27954ae228cd815a3a75c4320bac08ea0cd44f421e0c823
            befb4c693f0ef3d4bf2177023c34fb49bd4f7fb73d62e3e2ba7567283b88eb97bba36fdd38b6130bb9c9977636dc1bbc
            b6f79feb370a0251b41d869c34300acab54b8e31325e327fb371b6aa33843a10b09fbe5f31b22285b1c5a6f00ed82a3e
            8ff3ae650c062dd38c19d11e0d2c55448a47d9b30a5a5df98b6dc12408804592889bc9d909ae4d0786c1f17207d475b8
            87eff9e704027c2d8515e098052864c68243e80d03566c7b806910a1007c94ec8197185a1eaa9c819ebd00cf1fd0843a
            9ceb08601dfe8caf9d1133151a24b7409b3f3b8e1b52bff5986523231978a76e96932bd416a6af0397b9534914ccd7b4
            94e75be215fadf29920d42971220c6c2933b4a08104ece77916172bd1174f6e8ee8f7a566fa2fe9defb562cb6cc8e636
            ede36a7c6af6eeabea096d116b1c115fe837958a684a19f0e95d9d3f66700165e78b85d0679e091ee4b18d4565c431b3
            e5dfb5fe62f23924e305bc93631820d9e033a40461462872fe59acb97e6c50e7ff87d4527c9a5898fcaddcc77dc0400d
            fadbc4787bee48a6fb01cfed7814735bf92ff78679427bccf655ff3b77686361f4
            """, label: "packed-width-32"),
        // 32-bit pforSIMD
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(1), count: 128, hex: "01ffffffff00000000ffffffff00000000", label: "packed-width-1"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(2), count: 128, hex: "02ffffffffaaaaaaaa5555555500000000ffffffffaaaaaaaa5555555500000000", label: "packed-width-2"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(3), count: 128, hex: """
            03fbbeeffb96655996699aa66904411004beeffbbe655996659aa6699a41100441effbbeef59966559a6699aa6100441
            10
            """, label: "packed-width-3"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(7), count: 128, hex: """
            0783ebea3f16b54f62a97eb4943c0819c73ded9fa3d639c4366f86eac900d3105cfbf2333f855766d04ebc98691801cb
            026edec3cbba045695072be95e50517c28fa3739ef5f6ad23ba49c6b8409cf04d11ee3dbe24576a5476b896eac911c38
            113b3b6c5f6ed4b885906d05aac30652d0
            """, label: "packed-width-7"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(8), count: 128, hex: """
            080357abff166abe12297dd1253c90e43853a7fb4f66ba0e6279cd21758ce03488a3f74b9fb60a5eb2c91d71c5dc3084
            d8f3479bef065aae02196dc1152c80d4284397eb3f56aafe5269bd11657cd0247893e73b8fa6fa4ea2b90d61b5cc2074
            c8e3378bdff64a9ef2095db1051c70c4183387db2f469aee4259ad01556cc01468
            """, label: "packed-width-8"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(9), count: 128, hex: """
            0903afaefe16d5fa9629fb462f3c2193c73fe5d4be6046974391a759c8c1081c4da7a3ef2fb1b61578bac93bc4c4dc61
            10f934efe8916550ab2996b16dc2c61230e6f7432e6b015654f00a697a75147ca0adfb39f9f9936a5a452c9bbb91c4cb
            1cfc8e47e3bf1351f641985a09041d641c6e2efe3e947a966fbbc62e90e112c7c0e3d0b69744933ba1a555c0aa061845
            b4
            """, label: "packed-width-9"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(15), count: 128, hex: """
            0f03edabce1611b5802995be423c19c8046ae3bf376f4c026474ad8494790e07c5c53ae5ee06d5053a476d2686880547
            d2339ffea3ccc5c6b6dcebcec9ec11d7dceffbcf9213058197970e439c1b1805a1e3d337ef4c5664d0add894110e5bc5
            523aca6e26d2eaba366d0b06c7052c52d7dff343e805f8566c2bc0699051c87c144bcc3ae2558e3f435e40c4ac6802c9
            0d6737b93aea67fad26c943b6defc47c05dfee281fff3a39451086c96b31d2d991f5e3ea9bfdf66ea5c509edaecd1c11
            b8ca62e1bb8c67423e4e6ca38000710c0336433aa46784d2c497c56ae5c40605066e135feeba2385f6063cabfe52ccd1
            c6
            """, label: "packed-width-15"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(16), count: 128, hex: """
            1003ed571d16916a8129157d053c999089ab0dff3dbeb112a0d1352524e4b938a8532ca75c66d0bac07954cd448cd8e0
            c8fb4c4f7f0ef362e32177756734fb88eba36ff79fb6130a02c9971d86dc1b300a4b8e9fbe5e32b22271b6c5a6843ad8
            2af3ae47d9062d5a5d19d16dc12c5580459bc9eff9ae4d027cc1f115e0d475286443e89718566caa9c6910bd007c94d0
            84eb083f3bfe8c52bf1133652324b778a7932be75ba6affadfb9530d42ccd720c63b4a8f7a4ecea2fe6172b56274f6c8
            e6e36a3795f6ee4a19096d5d9d1c1170018b85dfb59e09f239b18d05bcc431182033a487d446289a5859acaddc6c50c0
            40dbc42ff7ee48427b01cf55ff14736863
            """, label: "packed-width-16"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(17), count: 128, hex: """
            1103edae3a1691d4022915fa0a3c992113ae36fceff9c6920044d7282193e7c64139c5f29465064d179147a599cd881d
            1ceb3ed3a798c33cb148c89dba39cd7ec4bfa36fef71b6131533c9973af5dc1b603f2f39fe047ac9940cc5d92a1410ea
            c0f43deffa1569d052369511ad56c1520528fb66f2abab6b532d5870bcb008751df7fc43e801be566c0a70691014327c
            942f31ac235539fb337b0146cca00991dcf8d931b996fa6dfa2c1b993bc23bc57ce27ccb8e5affbb93b54168980dc418
            9d92473de37351fff6dc5ab1093d64731c6a6e2a2dee9532786dbb3ac711e1021216faae352690cf61362ee09dc7c400
            c943ea90da8442138bc5ba957b0615182836b1977b3b12a13dc0f3aaffc55cb4b1
            """, label: "packed-width-17"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(31), count: 128, hex: """
            1f03ed92d11691d82e291506af3c994d2cab8e5dd6b540f396be021655c8c44d156a43f0ea6f2c034a748d5eaa796e68
            0abfe7dd340254eb648404f09407f599c4c552533a060d26d247e52a6a885d3102e51a02ed0576043926a20f85471ef1
            d133a5fd9ecc53ffc4dc09f0eaec27f510fe6e7ba3c6c575b6ce5076c9d72f77dc6fddb8fb130b39059776b60e1bbc36
            18cff5db9281289a97434e5a9c05e51aa1638cecd3ccdf4c56adeaacd80e040c5bf72b36efa43066d014de9111c5e7c1
            525ac638ca32cdd0eaedd1680b45a4002c9e556c26ca5fb836264104c7924450d76727def31d1804f8cb1d2ac0e11e50
            c8cf0943e85a0a566c310b69108c057c940d834b0c7b0055cea1805e80ec0168422dcf3a02408f3fe3e74fc44c1d0ec9
            2d58e767c76b47eab785a66c64d006efd47133b9421e63fa3a24933b95cdc27c4d6d39df1270d1ff4e446910ba4b0131
            16afec2821913839df9484c9f59ed0d9a3401ef5ac4544fd3b466ac596bb91cd6ddee36a7cdff6eeabd9096d11da1c11
            5fea9b4a456aa50cf8ebaece1f68b880b2f46221f4b4678207736c63513371cc6cf9bbd65f593e8764b9807772190324
            1b3c434a106c8422e79cc59aebcc0675fe3ea496e2d7c4c2e46fe53eee07066ad06f13e3edbb2399ee073cb7e353cc6d
            e55fee0df385f698edabfe77eed1c6c2e8
            """, label: "packed-width-31"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .packedWidth(32), count: 128, hex: """
            2003ed92d11691d8ae2915062f3c994dac571dbb2c6a81e6ad7d052c2a90899baaab0dc12bbeb10ca8d1357a29e4b9a1
            a9ff3def2612a05aa72524802738a8cfa4532c352566d060a27954ae228cd815a3a75c4320bac08ea0cd44f421e0c823
            befb4c693f0ef3d4bf2177023c34fb49bd4f7fb73d62e3e2ba7567283b88eb97bba36fdd38b6130bb9c9977636dc1bbc
            b6f79feb370a0251b41d869c34300acab54b8e31325e327fb371b6aa33843a10b09fbe5f31b22285b1c5a6f00ed82a3e
            8ff3ae650c062dd38c19d11e0d2c55448a47d9b30a5a5df98b6dc12408804592889bc9d909ae4d0786c1f17207d475b8
            87eff9e704027c2d8515e098052864c68243e80d03566c7b806910a1007c94ec8197185a1eaa9c819ebd00cf1fd0843a
            9ceb08601dfe8caf9d1133151a24b7409b3f3b8e1b52bff5986523231978a76e96932bd416a6af0397b9534914ccd7b4
            94e75be215fadf29920d42971220c6c2933b4a08104ece77916172bd1174f6e8ee8f7a566fa2fe9defb562cb6cc8e636
            ede36a7c6af6eeabea096d116b1c115fe837958a684a19f0e95d9d3f66700165e78b85d0679e091ee4b18d4565c431b3
            e5dfb5fe62f23924e305bc93631820d9e033a40461462872fe59acb97e6c50e7ff87d4527c9a5898fcaddcc77dc0400d
            fadbc4787bee48a6fb01cfed7814735bf92ff78679427bccf655ff3b77686361f4
            """, label: "packed-width-32"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0x80]), count: 1, hex: "8080", label: "seed-80"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0x80]), count: 1, hex: "8080", label: "seed-80"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0x3fff]), count: 1, hex: "bfff", label: "seed-3fff"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0x3fff]), count: 1, hex: "bfff", label: "seed-3fff"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0x4000]), count: 1, hex: "c00040", label: "seed-4000"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0x4000]), count: 1, hex: "c00040", label: "seed-4000"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0x1fffff]), count: 1, hex: "dfffff", label: "seed-1fffff"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0x1fffff]), count: 1, hex: "dfffff", label: "seed-1fffff"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0x200000]), count: 1, hex: "e0200000", label: "seed-200000"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0x200000]), count: 1, hex: "e0200000", label: "seed-200000"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0xfffffff]), count: 1, hex: "efffffff", label: "seed-fffffff"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0xfffffff]), count: 1, hex: "efffffff", label: "seed-fffffff"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .literal([0x10000000]), count: 1, hex: "f000000010", label: "seed-10000000"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .literal([0x10000000]), count: 1, hex: "f000000010", label: "seed-10000000"),
        // 32-bit delta
        Fixture(bits: 32, codec: .delta, pattern: .wraparound, count: 129, hex: "f0fdffffffc203", label: "wraparound"),
        Fixture(bits: 32, codec: .delta, pattern: .exceptionEdges, count: 129, hex: """
            f0fdffffff821d03000000000000c003000000000000c000000010000000020000400000000800000001000020000000
            040000800000000054555555aaaaaa2affffff3f0000000054555555aaaaaa2affffff3f
            """, label: "exceptionEdges"),
        Fixture(bits: 32, codec: .delta, pattern: .denseExceptions, count: 129, hex: """
            f0fdffffff821d4992244992244992244992244992244900000010000000020000400000000800000001000020000000
            040000800000001000000002000040000000080000000100002000000004000080000000100000000200004000000008
            000000010000200000000400008000000010000000020000400000000800000001000020000000040000800000001000
            00000200004000000008000000010000200000000400008000000010000000020000400000000045511445a2288aa23c
            cff33c0000000051144551288aa228cff33ccf
            """, label: "denseExceptions"),
        // 32-bit zigzag
        Fixture(bits: 32, codec: .zigzag, pattern: .wraparound, count: 129, hex: "f0fdffffffc306", label: "wraparound"),
        Fixture(bits: 32, codec: .zigzag, pattern: .exceptionEdges, count: 129, hex: """
            f0fdffffff831d03000000000000c003000000000000c000000010000000020000400000000800000001000020000000
            04000080000000009024499224499224b66ddbb60000000024499024491224496d1bb66d000000004992244992244912
            dbb66d1b
            """, label: "exceptionEdges"),
        Fixture(bits: 32, codec: .zigzag, pattern: .denseExceptions, count: 129, hex: """
            f0fdffffff831d4992244992244992244992244992244900000010000000020000400000000800000001000020000000
            040000800000001000000002000040000000080000000100002000000004000080000000100000000200004000000008
            000000010000200000000400008000000010000000020000400000000800000001000020000000040000800000001000
            0000020000400000000800000001000020000000040000800000001000000002000040000000001224489004091224b0
            61c3860000000020418204489020410d1b366c000000000912244882040912d8b061c3
            """, label: "denseExceptions"),
        // 32-bit pfor
        Fixture(bits: 32, codec: .pfor, pattern: .wraparound, count: 128, hex: """
            4901fd010c309080c1030915306cf01082c409152d60ccb09183c70f2145902c711285ca152d5dc08c319386cd1b3975
            f0ecf11388d021458d204db29489d32751a550ad72158bd62d5dbd800d33968cd93369d5b06df3168edc3975ede0cdb3
            978fdf3f8105112e741891e2458d1d418e349992e54b993571eef41994e851a54da14eb59a95eb57b165d1ae751b97ee
            5dbdf9ffff7f00
            """, label: "wraparound"),
        Fixture(bits: 32, codec: .pfor, pattern: .exceptionEdges, count: 128, hex: """
            821d03000000000000c003000000000000c00000001000000002000040000000080000000100002000000004000080e0
            e4e4e4e4e4e4e4e4e4e4e4e4e4e404e0e4e4e4e4e4e4e4e4e4e4e4e4e4e404
            """, label: "exceptionEdges"),
        Fixture(bits: 32, codec: .pfor, pattern: .denseExceptions, count: 128, hex: """
            821d49922449922449922449922449922449000000100000000200004000000008000000010000200000000400008000
            000010000000020000400000000800000001000020000000040000800000001000000002000040000000080000000100
            002000000004000080000000100000000200004000000008000000010000200000000400008000000010000000020000
            40000000080000000100002000000004000080000000100000000200004024c4e024c4e024c4e024c4e024c4e024c4e0
            24c4e024c4e024c4e024c4e024c4
            """, label: "denseExceptions"),
        // 32-bit pforSIMD
        Fixture(bits: 32, codec: .pforSIMD, pattern: .wraparound, count: 128, hex: """
            4901fd13540800186020031e6c3806247850d12247910183071231e3c79261438813285dd2d42a60d8e02b63deec2d66
            e4f809d42853210489133934e9d351644994a958bd922a5ac098aa5bc39e2b5dc6a4550bd72e6123078f6d3b37ef7953
            674f5fc1881d1f428a20dfc28b23a0438d2653d60cda59e2240a5fee3c3a65fa546a346bd9b8952b5abaf5ebdabb55ac
            5bbdf9ffff7f00
            """, label: "wraparound"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .exceptionEdges, count: 128, hex: """
            821d03000000000000c003000000000000c0000000100000000200004000000008000000010000200000000400008000
            00000054555555aaaaaa2affffff3f0000000054555555aaaaaa2affffff3f
            """, label: "exceptionEdges"),
        Fixture(bits: 32, codec: .pforSIMD, pattern: .denseExceptions, count: 128, hex: """
            821d49922449922449922449922449922449000000100000000200004000000008000000010000200000000400008000
            000010000000020000400000000800000001000020000000040000800000001000000002000040000000080000000100
            002000000004000080000000100000000200004000000008000000010000200000000400008000000010000000020000
            4000000008000000010000200000000400008000000010000000020000400000000045511445a2288aa23ccff33c0000
            000051144551288aa228cff33ccf
            """, label: "denseExceptions"),
        // 32-bit fpx
        Fixture(bits: 32, codec: .fpx, pattern: .floatEdges, count: 16, hex: "00811f74f50000004080ffff1fe0ffffdf0f000010f8ffff07fcffff030400000180c4220010031380a830019edf", label: "IEEE-edges-16"),
        Fixture(bits: 32, codec: .fpx, pattern: .floatEdges, count: 127, hex: """
            00811f74f575f575f575f575f575f575f575750000004080ffff1fe0ffffdf0f000010f8ffff07fcffff030400000180
            c4220010031380a830c13f00001000000008f0ffff03fcfffffb01000002ffffff80ffff7f8000002000905804006260
            02101526f80700000200000001feff7f80ffff7f3f000040e0ffff1ff0ffff0f1000000400128b00400c4c00a2c204ff
            00004000000020c0ffff0ff0ffffef07000008fcffff03feffff010200800040621100888109405498e01f0000080000
            0004f8ffff01fefffffd00000081ffff7fc0ffff3f4000001000482c0200313001880a13fc0300000100008000ffff3f
            c0ffffbf1f000020f0ffff0ff8ffff070800000200894500200626005161827f00002000000010e0ffff07f8fffff703
            000004feffff01ffffff000100400020b10800c4c004202a4cf00f00000400000002fcffff00ffffff7e000080c0ffff
            3fe0ffff1f2000000800241601801898009edf9edf9edf9edf9edf9edf9edf9e5f
            """, label: "IEEE-edges-127"),
        Fixture(bits: 32, codec: .fpx, pattern: .floatEdges, count: 128, hex: """
            00811f74f575f575f575f575f575f575f575f50000004080ffff1fe0ffffdf0f000010f8ffff07fcffff030400000180
            c4220010031380a830c13f00001000000008f0ffff03fcfffffb01000002ffffff80ffff7f8000002000905804006260
            02101526f80700000200000001feff7f80ffff7f3f000040e0ffff1ff0ffff0f1000000400128b00400c4c00a2c204ff
            00004000000020c0ffff0ff0ffffef07000008fcffff03feffff010200800040621100888109405498e01f0000080000
            0004f8ffff01fefffffd00000081ffff7fc0ffff3f4000001000482c0200313001880a13fc0300000100008000ffff3f
            c0ffffbf1f000020f0ffff0ff8ffff070800000200894500200626005161827f00002000000010e0ffff07f8fffff703
            000004feffff01ffffff000100400020b10800c4c004202a4cf00f00000400000002fcffff00ffffff7e000080c0ffff
            3fe0ffff1f20000008002416018018980044850900eeeeeeee55555555ddddddddffffffff
            """, label: "IEEE-edges-128"),
        Fixture(bits: 32, codec: .fpx, pattern: .floatEdges, count: 129, hex: """
            00811f74f575f575f575f575f575f575f575f50000004080ffff1fe0ffffdf0f000010f8ffff07fcffff030400000180
            c4220010031380a830c13f00001000000008f0ffff03fcfffffb01000002ffffff80ffff7f8000002000905804006260
            02101526f80700000200000001feff7f80ffff7f3f000040e0ffff1ff0ffff0f1000000400128b00400c4c00a2c204ff
            00004000000020c0ffff0ff0ffffef07000008fcffff03feffff010200800040621100888109405498e01f0000080000
            0004f8ffff01fefffffd00000081ffff7fc0ffff3f4000001000482c0200313001880a13fc0300000100008000ffff3f
            c0ffffbf1f000020f0ffff0ff8ffff070800000200894500200626005161827f00002000000010e0ffff07f8fffff703
            000004feffff01ffffff000100400020b10800c4c004202a4cf00f00000400000002fcffff00ffffff7e000080c0ffff
            3fe0ffff1f20000008002416018018980044850900eeeeeeee55555555ddddddddffffffff01dfff000040
            """, label: "IEEE-edges-129"),
        Fixture(bits: 32, codec: .fpx, pattern: .floatEdges, count: 257, hex: """
            00811f74f575f575f575f575f575f575f575f50000004080ffff1fe0ffffdf0f000010f8ffff07fcffff030400000180
            c4220010031380a830c13f00001000000008f0ffff03fcfffffb01000002ffffff80ffff7f8000002000905804006260
            02101526f80700000200000001feff7f80ffff7f3f000040e0ffff1ff0ffff0f1000000400128b00400c4c00a2c204ff
            00004000000020c0ffff0ff0ffffef07000008fcffff03feffff010200800040621100888109405498e01f0000080000
            0004f8ffff01fefffffd00000081ffff7fc0ffff3f4000001000482c0200313001880a13fc0300000100008000ffff3f
            c0ffffbf1f000020f0ffff0ff8ffff070800000200894500200626005161827f00002000000010e0ffff07f8fffff703
            000004feffff01ffffff000100400020b10800c4c004202a4cf00f00000400000002fcffff00ffffff7e000080c0ffff
            3fe0ffff1f20000008002416018018980044850900eeeeeeee55555555ddddddddffffffff00811f75f575f575f575f5
            75f575f575f575f5ff00004000000020c0ffff0ff0ffffef07000008fcffff03feffff01020080004062110088810940
            5498e01f00000800000004f8ffff01fefffffd00000081ffff7fc0ffff3f4000001000482c0200313001880a13fc0300
            000100008000ffff3fc0ffffbf1f000020f0ffff0ff8ffff070800000200894500200626005161827f00002000000010
            e0ffff07f8fffff703000004feffff01ffffff000100400020b10800c4c004202a4cf00f00000400000002fcffff00ff
            ffff7e000080c0ffff3fe0ffff1f200000080024160180189800448509fe0100800000004080ffff1fe0ffffdf0f0000
            10f8ffff07fcffff030400000180c4220010031380a830c13f00001000000008f0ffff03fcfffffb01000002ffffff80
            ffff7f800000200090580400626002101526f80700000200000001feff7f80ffff7f3f000040e0ffff1ff0ffff0f1000
            000400128b00400c4c00a2c204eeeeeeee55555555ddddddddffffffff01dfff000040
            """, label: "IEEE-edges-257"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 2, hex: "0000", label: "boundary-2"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 31, hex: "000124499224", label: "boundary-31"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 32, hex: "000124499224", label: "boundary-32"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 33, hex: "000124499224", label: "boundary-33"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 127, hex: "000124499224499224499224499224499224", label: "boundary-127"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 128, hex: "000124499224499224499224499224499224", label: "boundary-128"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 129, hex: "000124499224499224499224499224499224", label: "boundary-129"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 255, hex: "0001244992244992244992244992244992240149922449922449922449922449922409", label: "boundary-255"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 256, hex: "0001244992244992244992244992244992240149922449922449922449922449922449", label: "boundary-256"),
        Fixture(bits: 64, codec: .delta, pattern: .boundary, count: 257, hex: "0001244992244992244992244992244992240149922449922449922449922449922449", label: "boundary-257"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 2, hex: "00c202", label: "boundary-2"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 31, hex: "0003927449ba245d922e4997a403", label: "boundary-31"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 32, hex: "0003927449ba245d922e4997a40b", label: "boundary-32"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 33, hex: "0003927449ba245d922e4997a44b", label: "boundary-33"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 127, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7401
            """, label: "boundary-127"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 128, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7409
            """, label: "boundary-128"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 129, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            7449
            """, label: "boundary-129"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 255, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            744903ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba2401
            """, label: "boundary-255"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 256, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            744903ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba241d
            """, label: "boundary-256"),
        Fixture(bits: 64, codec: .zigzag, pattern: .boundary, count: 257, hex: """
            0003927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e992
            744903ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449ba245d922e4997a44bd225e9927449
            ba245d
            """, label: "boundary-257"),
        // 64-bit pfor
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 2, hex: "0102", label: "boundary-2"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 31, hex: "0388464423a211d18868443402", label: "boundary-31"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 32, hex: "0388464423a211d18868443422", label: "boundary-32"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 33, hex: "0388464423a211d1886844342202", label: "boundary-33"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 127, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            04
            """, label: "boundary-127"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 128, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44
            """, label: "boundary-128"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 129, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            44c203
            """, label: "boundary-129"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 255, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-255"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 256, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-256"),
        Fixture(bits: 64, codec: .pfor, pattern: .boundary, count: 257, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            440323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211c101
            """, label: "boundary-257"),
        // 64-bit pforSIMD
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 2, hex: "0102", label: "boundary-2"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 31, hex: "0388464423a211d18868443402", label: "boundary-31"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 32, hex: "0388464423a211d18868443422", label: "boundary-32"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 33, hex: "0388464423a211d1886844342202", label: "boundary-33"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 127, hex: """
            0388464423a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d8846
            04
            """, label: "boundary-127"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 128, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e
            """, label: "boundary-128"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 129, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4ec203
            """, label: "boundary-129"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 255, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e0323a211d188684434221a118d88464423a211d188684434221a118d88464423a211d188684434221a118d88464423
            a211
            """, label: "boundary-255"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 256, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e0353c029e09c024e01e014700a01a7805314700a38a78053c038059c02c029e014059c024e29e014704e01a780700a
            3805
            """, label: "boundary-256"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .boundary, count: 257, hex: """
            03e014700a01a780530a38059c53c029e038059c02c029e014024e01a714700a384e01a780700a38058053c029059c02
            4e0353c029e09c024e01e014700a01a7805314700a38a78053c038059c02c029e014059c024e29e014704e01a780700a
            3805c101
            """, label: "boundary-257"),
        // 64-bit fpx
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 2, hex: "3f0102", label: "boundary-2"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 31, hex: "3d03a0f9d07c683e341f9a0fcd07", label: "boundary-31"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 32, hex: "3d03a0f9d07c683e341f9a0fcd87", label: "boundary-32"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 33, hex: "3d03a0f9d07c683e341f9a0fcd8706", label: "boundary-33"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 127, hex: """
            3d03a0f9d07c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1
            f910
            """, label: "boundary-127"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 128, hex: """
            3d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d3
            """, label: "boundary-128"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 129, hex: """
            3d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d33fc101
            """, label: "boundary-129"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 255, hex: """
            3d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d33d037c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1f9d07c683e341f9a0fcd87e643f3a1f9
            d07c681e
            """, label: "boundary-255"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 256, hex: """
            3d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d33d0334739a39a799d3cc39cd9c66cc69e634cd9c664e69e634734e33a799739a39cd33a799d39a39cd9cd3cc69e6
            9c664e33
            """, label: "boundary-256"),
        Fixture(bits: 64, codec: .fpx, pattern: .boundary, count: 257, hex: """
            3d0338cd9c66cc69e634664e33a734739a394e33a799739a39cd99d3cc69cd9c664ed3cc69e69c664e33e634739a33a7
            99d33d0334739a39a799d3cc39cd9c66cc69e634cd9c664e69e634734e33a799739a39cd33a799d39a39cd9cd3cc69e6
            9c664e333fc101
            """, label: "boundary-257"),
        // 64-bit pfor
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(1), count: 128, hex: "0155555555555555555555555555555555", label: "packed-width-1"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(2), count: 128, hex: "021b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b", label: "packed-width-2"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(3), count: 128, hex: """
            037378157378157378157378157378157378157378157378157378157378157378157378157378157378157378157378
            15
            """, label: "packed-width-3"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(7), count: 128, hex: """
            07034b8a7755f7212b5f94fc97947053739e71d235c17b4788f614d711235b927b5774604b6f9cf09115b173438675d4
            b6011b5790fa165450436b9a7f51f5a06b7f84f49396f113538e79d637403b6798fe10d590637b82735376e10b4f8cf8
            9517303363967dd0b4805b7780f21256d1
            """, label: "packed-width-7"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(8), count: 128, hex: """
            080316293c576a7d90abbed1e4ff1225385366798ca7bacde0fb0e21344f627588a3b6c9dcf70a1d304b5e71849fb2c5
            d8f306192c475a6d809baec1d4ef0215284356697c97aabdd0ebfe11243f52657893a6b9cce7fa0d203b4e61748fa2b5
            c8e3f6091c374a5d708b9eb1c4dff205183346596c879aadc0dbee01142f425568
            """, label: "packed-width-8"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(9), count: 128, hex: """
            09032da6e479556d5fc8ab7d4727ff5f42091c53cce461744a573370fb1c86a4f9546c5dc4a36d27e77e5f4107184bbc
            c421f44956316cf30c666479546b5bc09b5d07a7fe5e40051443aca4e17349552f68ebfc4524f9536a59bc934de7667e
            5e7f03103b9c84a1f348542d64e3ec25e478536957b88b3dc726fe5d7e010c338c64617348532b60dbdc05a4f8526855
            b4
            """, label: "packed-width-9"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(15), count: 128, hex: """
            0f036d8b484a852773d5510bf4152013ab0ddf58748d3cf7df930095907050532c33681e95117bcad5053613c191fb4c
            8779c89d66fff4171bd79d11d7a36fdb49f2857b73ff5110741860144b0e2f599c8d50f7e99315159bb055f32e835646
            94a57a94d5eab605018b9b49d766709cbafe9e17e0578051c843682b761a848f728951e5f402a009eb087f46c48ce4f6
            b393fa958df04e932bd357ee94f97abed5ff3608418c3b4a2767989ccefea817f5d78a91cde36a7b77429b23725351ca
            7475e0028b05cf446c8338f65d93cf15f0304033242354168b0d7a48d5c4b6728181db447764c09362fe7217da57fdd1
            c6
            """, label: "packed-width-15"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(16), count: 128, hex: """
            1003ed169129153c99571d6a817d059089ab0dbeb1d135e4b9ff3d12a0252438a8532c66d079548cd8a75cbac0cd44e0
            c8fb4c0ef3217734fb4f7f62e3756788eba36fb613c997dc1bf79f0a021d86300a4b8e5e3271b6843a9fbeb222c5a6d8
            2af3ae062d19d12c5547d95a5d6dc180459bc9ae4dc1f1d475eff9027c15e0286443e8566c69107c949718aa9cbd00d0
            84eb08fe8c113324b73f3b52bf652378a7932ba6afb953ccd7e75bfadf0d4220c63b4a4ece617274f68f7aa2feb562c8
            e6e36af6ee096d1c1137954a195d9d70018b859e09b18dc431dfb5f23905bc182033a4462859ac6c5087d49a58addcc0
            40dbc4ee4801cf14732ff7427b55ff6863
            """, label: "packed-width-16"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(17), count: 128, hex: """
            1103ed2c22a554e0c97cd5512d505f01c8c4ab0d7d6345d720cffddf53025409091cd4532ccda0e55161c47eca551758
            331170e4fb4c1de685dca1d9fff4576c5cdd19c4f5a36f6d27265fe2de70ff594160872118054b8ebd64c6d922d4f1e9
            5b5664b1296c15f3ae0d5a664463a972945dab6b5b30c0229bc95d9b06c7a3aef39e5f806f0538143243e8add8a641e4
            a374894195732f406842eb08fc1947cc24b9f5b343ea77d948bc53932b4c5fe74e65be76be45ff7b835010633b4a9c9c
            87c9a5b3f7a847d47fad586473e36aecdd27b4e58878534929435767b8808b853c13c436268ef95d4b3e47016f0c9033
            a48c5064b166837a484d134b2b7760a0dbc4dc91043ca798fb724f684fd57fb4b1
            """, label: "packed-width-17"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(31), count: 128, hex: """
            1f03ed92518b486c574a85c18b27b38975d5b1cb520b346ff515b0a820133755ab0dc12bdf580654748d5e8a3c3734f5
            dff36e9200d53a9590009e70509f49532c3525336830511e95ab8811bb6274ca3504d20576043513d187c091477cfb4c
            693f8779ea5fc89d008f663fa9f7f477db131b17d7d59da1ec10d72f77a36fdd38db89855cf2a59d8d7b83d776ffb97e
            531088a2751872d26014946b4b8e31322f99bf599cadea8c500702f6e9fb159315298c159bc23bb0557c1ef3ae650c83
            96694646b44783a58a4871943dabd0eaca5fb4059320008b24119bc9d909d7a6034370bcdc81ba0ef7f09e7f4e10e06b
            295480631650c88c0543e80d032bb63d401a4428808f923d7089a1e551e50cf4f4023c7fa0097538eb08601d7fc6d74e
            c44c8586e41668f3b3e3b891faadc7948d8c64f04edd2c932bd416d3d7814bee541285f99a9672be255ed1ff4e913408
            5d4a408c85273b4a081027e7bb48985c6f84ce1eddfda867f516f5ef7cd78a2db391cd6ddae36a7c6a7bf75575425bc4
            9a23e20b7d53a98856ca804f7775fe98e102cace8b85d067cf040f726c6351993866b6fc5deb2f96cf211917f04e8e31
            40b2c133a404612314397f166bae9f0deafc7f482dc5d7c4c2e4b7721ff781811af4dbc4787b7724d37dc0733b9e626e
            2bff726f9817da63b657fdefdcd1c6c2e8
            """, label: "packed-width-31"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(32), count: 128, hex: """
            2003ed92d11691d8ae2915062f3c994dac571dbb2c6a81e6ad7d052c2a90899baaab0dc12bbeb10ca8d1357a29e4b9a1
            a9ff3def2612a05aa72524802738a8cfa4532c352566d060a27954ae228cd815a3a75c4320bac08ea0cd44f421e0c823
            befb4c693f0ef3d4bf2177023c34fb49bd4f7fb73d62e3e2ba7567283b88eb97bba36fdd38b6130bb9c9977636dc1bbc
            b6f79feb370a0251b41d869c34300acab54b8e31325e327fb371b6aa33843a10b09fbe5f31b22285b1c5a6f00ed82a3e
            8ff3ae650c062dd38c19d11e0d2c55448a47d9b30a5a5df98b6dc12408804592889bc9d909ae4d0786c1f17207d475b8
            87eff9e704027c2d8515e098052864c68243e80d03566c7b806910a1007c94ec8197185a1eaa9c819ebd00cf1fd0843a
            9ceb08601dfe8caf9d1133151a24b7409b3f3b8e1b52bff5986523231978a76e96932bd416a6af0397b9534914ccd7b4
            94e75be215fadf29920d42971220c6c2933b4a08104ece77916172bd1174f6e8ee8f7a566fa2fe9defb562cb6cc8e636
            ede36a7c6af6eeabea096d116b1c115fe837958a684a19f0e95d9d3f66700165e78b85d0679e091ee4b18d4565c431b3
            e5dfb5fe62f23924e305bc93631820d9e033a40461462872fe59acb97e6c50e7ff87d4527c9a5898fcaddcc77dc0400d
            fadbc4787bee48a6fb01cfed7814735bf92ff78679427bccf655ff3b77686361f4
            """, label: "packed-width-32"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(33), count: 128, hex: """
            2103ed92d12c22b15da75418bce0c96c6275d5b1cb522dd0bc755f018b0ac8c44d55ab0dc12b7d63195047d7e8a520cf
            0d4df5dff36e520254eb740909e0091cd46752532c3525cda0c144e751b98a60c4ae1875ca35045217d8117433117d08
            70e4115ffb4c693f1de6a97f87dc09f0a0d94feaf5f477db536c5c5c77dd19ca0ec4f5cb5da36fdd386d271672275fda
            d9e0dee0b575ffb97e5341208a768721270d1805e55a4b8e3132bd64fe66c7d9aace20d48180f5e9fb155356a43076b1
            29bc036c159f47f3ae650c0d5aa61967447b3460a9225274943dab50ab2b7f715b300902c02249449bc9d9095d9b0e0c
            07c7cb1da0aec33df49e7f4e5080afa570053866011432634143e80d03add8f600a7418402e0a3640f7489a1e5519533
            d0732fc0f30768421d4eeb08601dfd195f3b47cc546820b905daf4b3e3b851eab71e73d9c84806bc53374b932bd4164d
            5f072ee74e255160bea6a574be255e51ff3b457283d0a5041063e1493b4a08109d9cef2287c9f546a0b34777f7a867f5
            56d4bff37dadd8321b64739b76e36a7c6aeddd57d527b445ace188f8427753a9885629033e7d57e78f19b880b2738b85
            d0673d133cc8c7361695218e992df75deb2f563e87647c01efe4180c906c7033a404618d50e4fc67b1e6fa61833aff77
            482dc557130b937f2bf7711f60a0067ddbc4787bdd914cf7073cb7e3a198dbcaf7726f9857688fd97ed5ffce1db4b130
            7a
            """, label: "packed-width-33"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(62), count: 128, hex: """
            3e03ed92d1324ab5914524b6ebe28ce0935261f00294bbddf26436b17a9c4c2c571dbb2cd7ac68a95aa0796bab0aa8d1
            57c0a2a206994f42266eaa8278c408ab0dc12bf9870ea06f2c03ea6d8391175da397c2b0f8f993e786a62ac35d77ff3d
            ef2683fe2cbb04a8d669161959564202786221de6be3a03e93b2afd553532c3525a5d1c2b2193498e8d897069447e52a
            82533ce53062578cda0badbea75c43204fc8e08d2eb02368816dceda4c441f22fc139780238ff862963a9dfb4c693f51
            238684c33cf5ef4beab7187227c0436e7101d0ec27f58a72b2f94f7fb73d7b1aa49fd8b8b86e0c607f5f7786b2e39850
            b321ae5fee12dd0be4a36fdd381d7d5a97edc442eeb6fe249d7c69670309b62e716ff0dabab983c0f79feb37275478ae
            8240146d7f77ecd361c849a3bb95d8c22828d7c2051b2f4b8e3132c94e1ea997ccdfec21cdd51167ab3ac325cb4a12ea
            40c06ae0900b9fbe5f31d3a13da0ac48616cea4b9d576c0aef605629c463abf83cf24c6876f3ae650cf598d3bb41cb34
            e3acc14a9611edd180c00876b35411291ad7e15247d9b30a9ff3f1b25657fe62555e32d4164c8220716ee000164922a2
            b379b19bc9d909a1ea978d6bd381e11fd4fb1a1c2f7740e34d9250d7e11eca1ff19deff9e7044bcdb584005f4b61c052
            a358018e59e00da30da090190b52fa4ef843e80d036d246b9c15db1ee08a28689f06110a00be82bff151b207fa46c6e4
            97185a1e771f09972a67a06733a151dd0bf0fca128e0294113ea7002215ec3eb08601d19762fae3fe36be7f53f191331
            53a1c15ac6db92dc026daa8dd72f3f3b8e1b2369cda9d46f3d66beb5c65136329261cb2555e29dba593268af0a932bd4
            16c543e3a0e9ebc0e560328e973b954481751bc7335fd3525af42469e75be215efba86bbfe778a64298877d620742921
            e67a7183180b4fe250bc553b4a0810f19da4b293f35de4d3063f1426d71b411058e3d0d9a3bb0b3b34b08f7a566f9bf4
            5a8aa87fe77b949ce45a2bb6cce682bf9e209bdbb493878d9ce36a7c6abdef7885bdfbaafa5e15ac98d016b106339d08
            70447ca13b6205fb37958a6847c61e9c52067c7a079395ded5f963a65df3bac105949d43ce92e78b85d06769393c9767
            8207f9c9695d1ddb5854c6cfd23411c7cc96ebaa6ac2dfb5fe627310d2ae7c0ec97872e60a53c03b39667830a6628064
            837335e22e33a40461150bf0a9118a9cff347cf291c59aeb87ea1750b2419dff9b917b0d87d4527c3f6296a02616267f
            fdfabbd7ca7ddc271b75c2030335e8237cf369dbc4787bc144b4bb3b92e9fea7706316f0dc8e4785547c53cc6de54bd8
            48542ff78679ebbf6bb3d01eb37d68c92854f5bf73e7378aefa08d85d1d3a4c0b0
            """, label: "packed-width-62"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(63), count: 128, hex: """
            3f03ed92d1324ab5511691d8ae8b33824f2915062f40b9db6d3c994dac1e27130b571dbb2cd7ac68296a81e6adad2aa0
            467d052c2a6a90f96490899baa201e3102ab0dc12bf9870e20beb10ca8b70d465ed1357a290c8b9f7fe4b9a1a9ca70d7
            1dff3def2683fe2c3b12a05aa7596464592524802716e2bd7638a8cfa4ec6bf514532c3525a5d1c23266d060a2635f1a
            507954ae2238c5534e8cd815a3f642ab6fa75c43204fc8e00dbac08ea005b6392bcd44f421c23f7149e0c823be98a54e
            67fb4c693f512386040ef3d4bf2fa9df222177023ce416174034fb49bda29c6c7e4f7fb73d7b1aa41f62e3e2ba3180fd
            3d7567283b8e09355b88eb97bb44f70279a36fdd381d7d5a17b6130bb9dbfa9334c99776369060eb52dc1bbcb66eee20
            70f79feb372754786e0a0251b4fdddb10f1d869c34ba5b892d300acab570c1c64b4b8e3132c94e1e695e327fb3873457
            0771b6aa335cb2ac24843a10b01a38e4429fbe5f31d3a13d60b22285b1a92f751ec5a6f00e6695423cd82a3e8f3c139a
            5df3ae650cf598d37b062dd38cb3062b1919d11e0d088c60372c55448ac675b85447d9b30a9ff3f1725a5df98b5579c9
            106dc1240812e7060e80459288e86c5e2c9bc9d909a1ea974dae4d07867f50ef6bc1f1720734de2409d475b887f2477c
            27eff9e7044bcdb544027c2d85014b8d6215e09805de30da002864c68294be133e43e80d036d246b5c566c7b802ba2a0
            7d6910a100e02bf81b7c94ec81be91313997185a1e771f0957aa9c819ecd844675bd00cf1f8a029e12d0843a9c4088d7
            30eb08601d19762f2efe8caf9dd7ff644c1133151aac65bc6d24b7409b6ae3f50b3f3b8e1b2369cd2952bff598f9d61a
            4765232319b65c526578a76e960cdaab02932bd416c543e320a6af039783c9385eb953491458b7717cccd7b494163d49
            1ae75be215efba863bfadf2992a520de590d42971262ae177720c6c29338146f153b4a0810f19da4324ece77914f1bfc
            506172bd110481354e74f6e8eec20e0d6c8f7a566f9bf45a0aa2fe9def5172922bb562cb6c2ef8eb49c8e636ede46123
            67e36a7c6abdef7805f6eeabea7b55b022096d116b30d389401c115fe88e58c17e37958a6847c61e1c4a19f0e91d4c56
            3a5d9d3f66da35af5b700165e790b3e4798b85d06769393c179e091ee427a77535b18d4565fc2c4d53c431b3e5baaa9a
            70dfb5fe627310d26ef23924e3c9992b0c05bc93638607632a1820d9e05c8db84b33a40461150bf069462872fed3f0c9
            0759acb97ea87e01256c50e7ff66e45e4387d4527c3f6296609a5898fcf5ebef1eaddcc77db251273cc0400dfa08df7c
            5adbc4787bc144b47bee48a6fb9fc28d1901cfed785448c53714735bf9123612552ff78679ebbf6b73427bccf6a125a3
            1055ff3b777ea3f80e686361f43429302c
            """, label: "packed-width-63"),
        Fixture(bits: 64, codec: .pfor, pattern: .packedWidth(64), count: 128, hex: """
            3f03ed92d1324ab5d11691d8ae8b33824f2915062f40b9dbed3c994dac1e27130b571dbb2cd7ac68a96a81e6adad2aa0
            c67d052c2a6a90f96490899baa201e3182ab0dc12bf9870e20beb10ca8b70d465ed1357a290c8b9fffe4b9a1a9ca70d7
            1dff3def2683fe2cbb12a05aa7596464d92524802716e2bd7638a8cfa4ec6bf594532c3525a5d1c23266d060a2635f1a
            507954ae2238c553ce8cd815a3f642ab6fa75c43204fc8e08dbac08ea005b6392bcd44f421c23f7149e0c823be98a54e
            e7fb4c693f512386040ef3d4bf2fa9dfa22177023ce41617c034fb49bda29c6c7e4f7fb73d7b1aa49f62e3e2ba3180fd
            3d7567283b8e09355b88eb97bb44f702f9a36fdd381d7d5a17b6130bb9dbfa93b4c99776369060ebd2dc1bbcb66eee20
            70f79feb37275478ee0a0251b4fdddb10f1d869c34ba5b89ad300acab570c1c6cb4b8e3132c94e1e695e327fb3873457
            8771b6aa335cb2ac24843a10b01a38e4429fbe5f31d3a13de0b22285b1a92f751ec5a6f00e669542bcd82a3e8f3c139a
            ddf3ae650cf598d37b062dd38cb3062b9919d11e0d088c60372c55448ac675b85447d9b30a9ff3f1f25a5df98b5579c9
            106dc1240812e7068e80459288e86c5e2c9bc9d909a1ea974dae4d07867f50efebc1f1720734de2409d475b887f2477c
            a7eff9e7044bcdb5c4027c2d85014b8d6215e09805de30da802864c68294be133e43e80d036d246b5c566c7b802ba2a0
            fd6910a100e02bf81b7c94ec81be9131b997185a1e771f09d7aa9c819ecd844675bd00cf1f8a029e92d0843a9c4088d7
            30eb08601d19762faefe8caf9dd7ff64cc1133151aac65bc6d24b7409b6ae3f58b3f3b8e1b2369cd2952bff598f9d61a
            4765232319b65c52e578a76e960cdaab02932bd416c543e3a0a6af039783c938deb953491458b7717cccd7b494163d49
            9ae75be215efba863bfadf2992a520de590d42971262ae17f720c6c29338146f153b4a0810f19da4b24ece77914f1bfc
            d06172bd110481354e74f6e8eec20e0dec8f7a566f9bf45a0aa2fe9def517292abb562cb6c2ef8ebc9c8e636ede46123
            67e36a7c6abdef7885f6eeabea7b55b022096d116b30d389401c115fe88e58c1fe37958a6847c61e1c4a19f0e91d4c56
            ba5d9d3f66da35afdb700165e790b3e4798b85d06769393c979e091ee427a77535b18d4565fc2c4d53c431b3e5baaa9a
            f0dfb5fe627310d26ef23924e3c9992b8c05bc93638607632a1820d9e05c8db84b33a40461150bf0e9462872fed3f0c9
            0759acb97ea87e01a56c50e7ff66e45ec387d4527c3f6296609a5898fcf5ebef9eaddcc77db251273cc0400dfa08df7c
            5adbc4787bc144b4fbee48a6fb9fc28d1901cfed785448c5b714735bf9123612d52ff78679ebbf6b73427bccf6a125a3
            9055ff3b777ea3f80e686361f4342930ac
            """, label: "packed-width-64"),
        // 64-bit pforSIMD
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(1), count: 128, hex: "01ffffffff00000000ffffffff00000000", label: "packed-width-1"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(2), count: 128, hex: "02ffffffffaaaaaaaa5555555500000000ffffffffaaaaaaaa5555555500000000", label: "packed-width-2"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(3), count: 128, hex: """
            03fbbeeffb96655996699aa66904411004beeffbbe655996659aa6699a41100441effbbeef59966559a6699aa6100441
            10
            """, label: "packed-width-3"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(7), count: 128, hex: """
            0783ebea3f16b54f62a97eb4943c0819c73ded9fa3d639c4366f86eac900d3105cfbf2333f855766d04ebc98691801cb
            026edec3cbba045695072be95e50517c28fa3739ef5f6ad23ba49c6b8409cf04d11ee3dbe24576a5476b896eac911c38
            113b3b6c5f6ed4b885906d05aac30652d0
            """, label: "packed-width-7"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(8), count: 128, hex: """
            080357abff166abe12297dd1253c90e43853a7fb4f66ba0e6279cd21758ce03488a3f74b9fb60a5eb2c91d71c5dc3084
            d8f3479bef065aae02196dc1152c80d4284397eb3f56aafe5269bd11657cd0247893e73b8fa6fa4ea2b90d61b5cc2074
            c8e3378bdff64a9ef2095db1051c70c4183387db2f469aee4259ad01556cc01468
            """, label: "packed-width-8"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(9), count: 128, hex: """
            0903afaefe16d5fa9629fb462f3c2193c73fe5d4be6046974391a759c8c1081c4da7a3ef2fb1b61578bac93bc4c4dc61
            10f934efe8916550ab2996b16dc2c61230e6f7432e6b015654f00a697a75147ca0adfb39f9f9936a5a452c9bbb91c4cb
            1cfc8e47e3bf1351f641985a09041d641c6e2efe3e947a966fbbc62e90e112c7c0e3d0b69744933ba1a555c0aa061845
            b4
            """, label: "packed-width-9"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(15), count: 128, hex: """
            0f03edabce1611b5802995be423c19c8046ae3bf376f4c026474ad8494790e07c5c53ae5ee06d5053a476d2686880547
            d2339ffea3ccc5c6b6dcebcec9ec11d7dceffbcf9213058197970e439c1b1805a1e3d337ef4c5664d0add894110e5bc5
            523aca6e26d2eaba366d0b06c7052c52d7dff343e805f8566c2bc0699051c87c144bcc3ae2558e3f435e40c4ac6802c9
            0d6737b93aea67fad26c943b6defc47c05dfee281fff3a39451086c96b31d2d991f5e3ea9bfdf66ea5c509edaecd1c11
            b8ca62e1bb8c67423e4e6ca38000710c0336433aa46784d2c497c56ae5c40605066e135feeba2385f6063cabfe52ccd1
            c6
            """, label: "packed-width-15"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(16), count: 128, hex: """
            1003ed571d16916a8129157d053c999089ab0dff3dbeb112a0d1352524e4b938a8532ca75c66d0bac07954cd448cd8e0
            c8fb4c4f7f0ef362e32177756734fb88eba36ff79fb6130a02c9971d86dc1b300a4b8e9fbe5e32b22271b6c5a6843ad8
            2af3ae47d9062d5a5d19d16dc12c5580459bc9eff9ae4d027cc1f115e0d475286443e89718566caa9c6910bd007c94d0
            84eb083f3bfe8c52bf1133652324b778a7932be75ba6affadfb9530d42ccd720c63b4a8f7a4ecea2fe6172b56274f6c8
            e6e36a3795f6ee4a19096d5d9d1c1170018b85dfb59e09f239b18d05bcc431182033a487d446289a5859acaddc6c50c0
            40dbc42ff7ee48427b01cf55ff14736863
            """, label: "packed-width-16"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(17), count: 128, hex: """
            1103edae3a1691d4022915fa0a3c992113ae36fceff9c6920044d7282193e7c64139c5f29465064d179147a599cd881d
            1ceb3ed3a798c33cb148c89dba39cd7ec4bfa36fef71b6131533c9973af5dc1b603f2f39fe047ac9940cc5d92a1410ea
            c0f43deffa1569d052369511ad56c1520528fb66f2abab6b532d5870bcb008751df7fc43e801be566c0a70691014327c
            942f31ac235539fb337b0146cca00991dcf8d931b996fa6dfa2c1b993bc23bc57ce27ccb8e5affbb93b54168980dc418
            9d92473de37351fff6dc5ab1093d64731c6a6e2a2dee9532786dbb3ac711e1021216faae352690cf61362ee09dc7c400
            c943ea90da8442138bc5ba957b0615182836b1977b3b12a13dc0f3aaffc55cb4b1
            """, label: "packed-width-17"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(31), count: 128, hex: """
            1f03ed92d11691d82e291506af3c994d2cab8e5dd6b540f396be021655c8c44d156a43f0ea6f2c034a748d5eaa796e68
            0abfe7dd340254eb648404f09407f599c4c552533a060d26d247e52a6a885d3102e51a02ed0576043926a20f85471ef1
            d133a5fd9ecc53ffc4dc09f0eaec27f510fe6e7ba3c6c575b6ce5076c9d72f77dc6fddb8fb130b39059776b60e1bbc36
            18cff5db9281289a97434e5a9c05e51aa1638cecd3ccdf4c56adeaacd80e040c5bf72b36efa43066d014de9111c5e7c1
            525ac638ca32cdd0eaedd1680b45a4002c9e556c26ca5fb836264104c7924450d76727def31d1804f8cb1d2ac0e11e50
            c8cf0943e85a0a566c310b69108c057c940d834b0c7b0055cea1805e80ec0168422dcf3a02408f3fe3e74fc44c1d0ec9
            2d58e767c76b47eab785a66c64d006efd47133b9421e63fa3a24933b95cdc27c4d6d39df1270d1ff4e446910ba4b0131
            16afec2821913839df9484c9f59ed0d9a3401ef5ac4544fd3b466ac596bb91cd6ddee36a7cdff6eeabd9096d11da1c11
            5fea9b4a456aa50cf8ebaece1f68b880b2f46221f4b4678207736c63513371cc6cf9bbd65f593e8764b9807772190324
            1b3c434a106c8422e79cc59aebcc0675fe3ea496e2d7c4c2e46fe53eee07066ad06f13e3edbb2399ee073cb7e353cc6d
            e55fee0df385f698edabfe77eed1c6c2e8
            """, label: "packed-width-31"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(32), count: 128, hex: """
            2003ed92d11691d8ae2915062f3c994dac571dbb2c6a81e6ad7d052c2a90899baaab0dc12bbeb10ca8d1357a29e4b9a1
            a9ff3def2612a05aa72524802738a8cfa4532c352566d060a27954ae228cd815a3a75c4320bac08ea0cd44f421e0c823
            befb4c693f0ef3d4bf2177023c34fb49bd4f7fb73d62e3e2ba7567283b88eb97bba36fdd38b6130bb9c9977636dc1bbc
            b6f79feb370a0251b41d869c34300acab54b8e31325e327fb371b6aa33843a10b09fbe5f31b22285b1c5a6f00ed82a3e
            8ff3ae650c062dd38c19d11e0d2c55448a47d9b30a5a5df98b6dc12408804592889bc9d909ae4d0786c1f17207d475b8
            87eff9e704027c2d8515e098052864c68243e80d03566c7b806910a1007c94ec8197185a1eaa9c819ebd00cf1fd0843a
            9ceb08601dfe8caf9d1133151a24b7409b3f3b8e1b52bff5986523231978a76e96932bd416a6af0397b9534914ccd7b4
            94e75be215fadf29920d42971220c6c2933b4a08104ece77916172bd1174f6e8ee8f7a566fa2fe9defb562cb6cc8e636
            ede36a7c6af6eeabea096d116b1c115fe837958a684a19f0e95d9d3f66700165e78b85d0679e091ee4b18d4565c431b3
            e5dfb5fe62f23924e305bc93631820d9e033a40461462872fe59acb97e6c50e7ff87d4527c9a5898fcaddcc77dc0400d
            fadbc4787bee48a6fb01cfed7814735bf92ff78679427bccf655ff3b77686361f4
            """, label: "packed-width-32"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(33), count: 128, hex: """
            2103ed92d12c22b15da75418bce0c96c6275d5b1cb522dd0bc755f018b0ac8c44d55ab0dc12b7d63195047d7e8a520cf
            0d4df5dff36e520254eb740909e0091cd46752532c3525cda0c144e751b98a60c4ae1875ca35045217d8117433117d08
            70e4115ffb4c693f1de6a97f87dc09f0a0d94feaf5f477db536c5c5c77dd19ca0ec4f5cb5da36fdd386d271672275fda
            d9e0dee0b575ffb97e5341208a768721270d1805e55a4b8e3132bd64fe66c7d9aace20d48180f5e9fb155356a43076b1
            29bc036c159f47f3ae650c0d5aa61967447b3460a9225274943dab50ab2b7f715b300902c02249449bc9d9095d9b0e0c
            07c7cb1da0aec33df49e7f4e5080afa570053866011432634143e80d03add8f600a7418402e0a3640f7489a1e5519533
            d0732fc0f30768421d4eeb08601dfd195f3b47cc546820b905daf4b3e3b851eab71e73d9c84806bc53374b932bd4164d
            5f072ee74e255160bea6a574be255e51ff3b457283d0a5041063e1493b4a08109d9cef2287c9f546a0b34777f7a867f5
            56d4bff37dadd8321b64739b76e36a7c6aeddd57d527b445ace188f8427753a9885629033e7d57e78f19b880b2738b85
            d0673d133cc8c7361695218e992df75deb2f563e87647c01efe4180c906c7033a404618d50e4fc67b1e6fa61833aff77
            482dc557130b937f2bf7711f60a0067ddbc4787bdd914cf7073cb7e3a198dbcaf7726f9857688fd97ed5ffce1db4b130
            7a
            """, label: "packed-width-33"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(62), count: 128, hex: """
            3e03ed92d1324ab5914524b6ebe28ce0935261f00294bbddf26436b17a9c4c2c571dbb2cd7ac68a95aa0796bab0aa8d1
            57c0a2a206994f42266eaa8278c408ab0dc12bf9870ea06f2c03ea6d8391175da397c2b0f8f993e786a62ac35d77ff3d
            ef2683fe2cbb04a8d669161959564202786221de6be3a03e93b2afd553532c3525a5d1c2b2193498e8d897069447e52a
            82533ce53062578cda0badbea75c43204fc8e08d2eb02368816dceda4c441f22fc139780238ff862963a9dfb4c693f51
            238684c33cf5ef4beab7187227c0436e7101d0ec27f58a72b2f94f7fb73d7b1aa49fd8b8b86e0c607f5f7786b2e39850
            b321ae5fee12dd0be4a36fdd381d7d5a97edc442eeb6fe249d7c69670309b62e716ff0dabab983c0f79feb37275478ae
            8240146d7f77ecd361c849a3bb95d8c22828d7c2051b2f4b8e3132c94e1ea997ccdfec21cdd51167ab3ac325cb4a12ea
            40c06ae0900b9fbe5f31d3a13da0ac48616cea4b9d576c0aef605629c463abf83cf24c6876f3ae650cf598d3bb41cb34
            e3acc14a9611edd180c00876b35411291ad7e15247d9b30a9ff3f1b25657fe62555e32d4164c8220716ee000164922a2
            b379b19bc9d909a1ea978d6bd381e11fd4fb1a1c2f7740e34d9250d7e11eca1ff19deff9e7044bcdb584005f4b61c052
            a358018e59e00da30da090190b52fa4ef843e80d036d246b9c15db1ee08a28689f06110a00be82bff151b207fa46c6e4
            97185a1e771f09972a67a06733a151dd0bf0fca128e0294113ea7002215ec3eb08601d19762fae3fe36be7f53f191331
            53a1c15ac6db92dc026daa8dd72f3f3b8e1b2369cda9d46f3d66beb5c65136329261cb2555e29dba593268af0a932bd4
            16c543e3a0e9ebc0e560328e973b954481751bc7335fd3525af42469e75be215efba86bbfe778a64298877d620742921
            e67a7183180b4fe250bc553b4a0810f19da4b293f35de4d3063f1426d71b411058e3d0d9a3bb0b3b34b08f7a566f9bf4
            5a8aa87fe77b949ce45a2bb6cce682bf9e209bdbb493878d9ce36a7c6abdef7885bdfbaafa5e15ac98d016b106339d08
            70447ca13b6205fb37958a6847c61e9c52067c7a079395ded5f963a65df3bac105949d43ce92e78b85d06769393c9767
            8207f9c9695d1ddb5854c6cfd23411c7cc96ebaa6ac2dfb5fe627310d2ae7c0ec97872e60a53c03b39667830a6628064
            837335e22e33a40461150bf0a9118a9cff347cf291c59aeb87ea1750b2419dff9b917b0d87d4527c3f6296a02616267f
            fdfabbd7ca7ddc271b75c2030335e8237cf369dbc4787bc144b4bb3b92e9fea7706316f0dc8e4785547c53cc6de54bd8
            48542ff78679ebbf6bb3d01eb37d68c92854f5bf73e7378aefa08d85d1d3a4c0b0
            """, label: "packed-width-62"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(63), count: 128, hex: """
            3f03ed92d1324ab5511691d8ae8b33824f2915062f40b9db6d3c994dac1e27130b571dbb2cd7ac68296a81e6adad2aa0
            467d052c2a6a90f96490899baa201e3102ab0dc12bf9870e20beb10ca8b70d465ed1357a290c8b9f7fe4b9a1a9ca70d7
            1dff3def2683fe2c3b12a05aa7596464592524802716e2bd7638a8cfa4ec6bf514532c3525a5d1c23266d060a2635f1a
            507954ae2238c5534e8cd815a3f642ab6fa75c43204fc8e00dbac08ea005b6392bcd44f421c23f7149e0c823be98a54e
            67fb4c693f512386040ef3d4bf2fa9df222177023ce416174034fb49bda29c6c7e4f7fb73d7b1aa41f62e3e2ba3180fd
            3d7567283b8e09355b88eb97bb44f70279a36fdd381d7d5a17b6130bb9dbfa9334c99776369060eb52dc1bbcb66eee20
            70f79feb372754786e0a0251b4fdddb10f1d869c34ba5b892d300acab570c1c64b4b8e3132c94e1e695e327fb3873457
            0771b6aa335cb2ac24843a10b01a38e4429fbe5f31d3a13d60b22285b1a92f751ec5a6f00e6695423cd82a3e8f3c139a
            5df3ae650cf598d37b062dd38cb3062b1919d11e0d088c60372c55448ac675b85447d9b30a9ff3f1725a5df98b5579c9
            106dc1240812e7060e80459288e86c5e2c9bc9d909a1ea974dae4d07867f50ef6bc1f1720734de2409d475b887f2477c
            27eff9e7044bcdb544027c2d85014b8d6215e09805de30da002864c68294be133e43e80d036d246b5c566c7b802ba2a0
            7d6910a100e02bf81b7c94ec81be91313997185a1e771f0957aa9c819ecd844675bd00cf1f8a029e12d0843a9c4088d7
            30eb08601d19762f2efe8caf9dd7ff644c1133151aac65bc6d24b7409b6ae3f50b3f3b8e1b2369cd2952bff598f9d61a
            4765232319b65c526578a76e960cdaab02932bd416c543e320a6af039783c9385eb953491458b7717cccd7b494163d49
            1ae75be215efba863bfadf2992a520de590d42971262ae177720c6c29338146f153b4a0810f19da4324ece77914f1bfc
            506172bd110481354e74f6e8eec20e0d6c8f7a566f9bf45a0aa2fe9def5172922bb562cb6c2ef8eb49c8e636ede46123
            67e36a7c6abdef7805f6eeabea7b55b022096d116b30d389401c115fe88e58c17e37958a6847c61e1c4a19f0e91d4c56
            3a5d9d3f66da35af5b700165e790b3e4798b85d06769393c179e091ee427a77535b18d4565fc2c4d53c431b3e5baaa9a
            70dfb5fe627310d26ef23924e3c9992b0c05bc93638607632a1820d9e05c8db84b33a40461150bf069462872fed3f0c9
            0759acb97ea87e01256c50e7ff66e45e4387d4527c3f6296609a5898fcf5ebef1eaddcc77db251273cc0400dfa08df7c
            5adbc4787bc144b47bee48a6fb9fc28d1901cfed785448c53714735bf9123612552ff78679ebbf6b73427bccf6a125a3
            1055ff3b777ea3f80e686361f43429302c
            """, label: "packed-width-63"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .packedWidth(64), count: 128, hex: """
            3f03ed92d1324ab5d11691d8ae8b33824f2915062f40b9dbed3c994dac1e27130b571dbb2cd7ac68a96a81e6adad2aa0
            c67d052c2a6a90f96490899baa201e3182ab0dc12bf9870e20beb10ca8b70d465ed1357a290c8b9fffe4b9a1a9ca70d7
            1dff3def2683fe2cbb12a05aa7596464d92524802716e2bd7638a8cfa4ec6bf594532c3525a5d1c23266d060a2635f1a
            507954ae2238c553ce8cd815a3f642ab6fa75c43204fc8e08dbac08ea005b6392bcd44f421c23f7149e0c823be98a54e
            e7fb4c693f512386040ef3d4bf2fa9dfa22177023ce41617c034fb49bda29c6c7e4f7fb73d7b1aa49f62e3e2ba3180fd
            3d7567283b8e09355b88eb97bb44f702f9a36fdd381d7d5a17b6130bb9dbfa93b4c99776369060ebd2dc1bbcb66eee20
            70f79feb37275478ee0a0251b4fdddb10f1d869c34ba5b89ad300acab570c1c6cb4b8e3132c94e1e695e327fb3873457
            8771b6aa335cb2ac24843a10b01a38e4429fbe5f31d3a13de0b22285b1a92f751ec5a6f00e669542bcd82a3e8f3c139a
            ddf3ae650cf598d37b062dd38cb3062b9919d11e0d088c60372c55448ac675b85447d9b30a9ff3f1f25a5df98b5579c9
            106dc1240812e7068e80459288e86c5e2c9bc9d909a1ea974dae4d07867f50efebc1f1720734de2409d475b887f2477c
            a7eff9e7044bcdb5c4027c2d85014b8d6215e09805de30da802864c68294be133e43e80d036d246b5c566c7b802ba2a0
            fd6910a100e02bf81b7c94ec81be9131b997185a1e771f09d7aa9c819ecd844675bd00cf1f8a029e92d0843a9c4088d7
            30eb08601d19762faefe8caf9dd7ff64cc1133151aac65bc6d24b7409b6ae3f58b3f3b8e1b2369cd2952bff598f9d61a
            4765232319b65c52e578a76e960cdaab02932bd416c543e3a0a6af039783c938deb953491458b7717cccd7b494163d49
            9ae75be215efba863bfadf2992a520de590d42971262ae17f720c6c29338146f153b4a0810f19da4b24ece77914f1bfc
            d06172bd110481354e74f6e8eec20e0dec8f7a566f9bf45a0aa2fe9def517292abb562cb6c2ef8ebc9c8e636ede46123
            67e36a7c6abdef7885f6eeabea7b55b022096d116b30d389401c115fe88e58c1fe37958a6847c61e1c4a19f0e91d4c56
            ba5d9d3f66da35afdb700165e790b3e4798b85d06769393c979e091ee427a77535b18d4565fc2c4d53c431b3e5baaa9a
            f0dfb5fe627310d26ef23924e3c9992b8c05bc93638607632a1820d9e05c8db84b33a40461150bf0e9462872fed3f0c9
            0759acb97ea87e01a56c50e7ff66e45ec387d4527c3f6296609a5898fcf5ebef9eaddcc77db251273cc0400dfa08df7c
            5adbc4787bc144b4fbee48a6fb9fc28d1901cfed785448c5b714735bf9123612d52ff78679ebbf6b73427bccf6a125a3
            9055ff3b777ea3f80e686361f4342930ac
            """, label: "packed-width-64"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x7f]), count: 1, hex: "7f", label: "seed-7f"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x80]), count: 1, hex: "8080", label: "seed-80"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x80]), count: 1, hex: "8080", label: "seed-80"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x3fff]), count: 1, hex: "bfff", label: "seed-3fff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x3fff]), count: 1, hex: "bfff", label: "seed-3fff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x4000]), count: 1, hex: "c00040", label: "seed-4000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x4000]), count: 1, hex: "c00040", label: "seed-4000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x1fffff]), count: 1, hex: "dfffff", label: "seed-1fffff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x1fffff]), count: 1, hex: "dfffff", label: "seed-1fffff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x200000]), count: 1, hex: "e0200000", label: "seed-200000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x200000]), count: 1, hex: "e0200000", label: "seed-200000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0xfffffff]), count: 1, hex: "efffffff", label: "seed-fffffff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0xfffffff]), count: 1, hex: "efffffff", label: "seed-fffffff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x10000000]), count: 1, hex: "f000000010", label: "seed-10000000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x10000000]), count: 1, hex: "f000000010", label: "seed-10000000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x7ffffffff]), count: 1, hex: "f7ffffffff", label: "seed-7ffffffff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x7ffffffff]), count: 1, hex: "f7ffffffff", label: "seed-7ffffffff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x800000000]), count: 1, hex: "f80800000000", label: "seed-800000000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x800000000]), count: 1, hex: "f80800000000", label: "seed-800000000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x3ffffffffff]), count: 1, hex: "fbffffffffff", label: "seed-3ffffffffff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x3ffffffffff]), count: 1, hex: "fbffffffffff", label: "seed-3ffffffffff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x40000000000]), count: 1, hex: "fc000400000000", label: "seed-40000000000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x40000000000]), count: 1, hex: "fc000400000000", label: "seed-40000000000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x1ffffffffffff]), count: 1, hex: "fdffffffffffff", label: "seed-1ffffffffffff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x1ffffffffffff]), count: 1, hex: "fdffffffffffff", label: "seed-1ffffffffffff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x2000000000000]), count: 1, hex: "fe02000000000000", label: "seed-2000000000000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x2000000000000]), count: 1, hex: "fe02000000000000", label: "seed-2000000000000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0xffffffffffffff]), count: 1, hex: "feffffffffffffff", label: "seed-ffffffffffffff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0xffffffffffffff]), count: 1, hex: "feffffffffffffff", label: "seed-ffffffffffffff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x100000000000000]), count: 1, hex: "ff0000000000000001", label: "seed-100000000000000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x100000000000000]), count: 1, hex: "ff0000000000000001", label: "seed-100000000000000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x7fffffffffffffff]), count: 1, hex: "ffffffffffffffff7f", label: "seed-7fffffffffffffff"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x7fffffffffffffff]), count: 1, hex: "ffffffffffffffff7f", label: "seed-7fffffffffffffff"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .literal([0x8000000000000000]), count: 1, hex: "ff0000000000000080", label: "seed-8000000000000000"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .literal([0x8000000000000000]), count: 1, hex: "ff0000000000000080", label: "seed-8000000000000000"),
        // 64-bit delta
        Fixture(bits: 64, codec: .delta, pattern: .wraparound, count: 129, hex: "fffdffffffffffffffc203", label: "wraparound"),
        Fixture(bits: 64, codec: .delta, pattern: .exceptionEdges, count: 129, hex: """
            fffdffffffffffffff823d03000000000000c003000000000000c0000000000000001000000000000000020000000000
            00400000000000000008000000000000000100000000000020000000000000000400000000000080e0e4e4e4e4e4e4e4
            e4e4e4e4e4e4e404e0e4e4e4e4e4e4e4e4e4e4e4e4e4e404
            """, label: "exceptionEdges"),
        Fixture(bits: 64, codec: .delta, pattern: .denseExceptions, count: 129, hex: """
            fffdffffffffffffff823d49922449922449922449922449922449000000000000001000000000000000020000000000
            004000000000000000080000000000000001000000000000200000000000000004000000000000800000000000000010
            000000000000000200000000000040000000000000000800000000000000010000000000002000000000000000040000
            000000008000000000000000100000000000000002000000000000400000000000000008000000000000000100000000
            000020000000000000000400000000000080000000000000001000000000000000020000000000004000000000000000
            080000000000000001000000000000200000000000000004000000000000800000000000000010000000000000000200
            000000000040000000000000000800000000000000010000000000002000000000000000040000000000008000000000
            0000001000000000000000020000000000004024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4
            e024c4
            """, label: "denseExceptions"),
        // 64-bit zigzag
        Fixture(bits: 64, codec: .zigzag, pattern: .wraparound, count: 129, hex: "fffdffffffffffffffc306", label: "wraparound"),
        Fixture(bits: 64, codec: .zigzag, pattern: .exceptionEdges, count: 129, hex: """
            fffdffffffffffffff833d03000000000000c003000000000000c0000000000000001000000000000000020000000000
            00400000000000000008000000000000000100000000000020000000000000000400000000000080000dd1100dd1100d
            d1100dd1100dd1100dd1100dd1100d01000dd1100dd1100dd1100dd1100dd1100dd1100dd1100d01
            """, label: "exceptionEdges"),
        Fixture(bits: 64, codec: .zigzag, pattern: .denseExceptions, count: 129, hex: """
            fffdffffffffffffff833d49922449922449922449922449922449000000000000001000000000000000020000000000
            004000000000000000080000000000000001000000000000200000000000000004000000000000800000000000000010
            000000000000000200000000000040000000000000000800000000000000010000000000002000000000000000040000
            000000008000000000000000100000000000000002000000000000400000000000000008000000000000000100000000
            000020000000000000000400000000000080000000000000001000000000000000020000000000004000000000000000
            080000000000000001000000000000200000000000000004000000000000800000000000000010000000000000000200
            000000000040000000000000000800000000000000010000000000002000000000000000040000000000008000000000
            000000100000000000000002000000000000401001c1000d11100cd01001c1000d11100cd01001c1000d11100cd01001
            c1000d11100cd01001c1000d11100cd01001c1
            """, label: "denseExceptions"),
        // 64-bit pfor
        Fixture(bits: 64, codec: .pfor, pattern: .wraparound, count: 128, hex: """
            4901fd010c309080c1030915306cf01082c409152d60ccb09183c70f2145902c711285ca152d5dc08c319386cd1b3975
            f0ecf11388d021458d204db29489d32751a550ad72158bd62d5dbd800d33968cd93369d5b06df3168edc3975ede0cdb3
            978fdf3f8105112e741891e2458d1d418e349992e54b993571eef41994e851a54da14eb59a95eb57b165d1ae751b97ee
            5dbdfdffffffffffff7f00
            """, label: "wraparound"),
        Fixture(bits: 64, codec: .pfor, pattern: .exceptionEdges, count: 128, hex: """
            823d03000000000000c003000000000000c0000000000000001000000000000000020000000000004000000000000000
            08000000000000000100000000000020000000000000000400000000000080e0e4e4e4e4e4e4e4e4e4e4e4e4e4e404e0
            e4e4e4e4e4e4e4e4e4e4e4e4e4e404
            """, label: "exceptionEdges"),
        Fixture(bits: 64, codec: .pfor, pattern: .denseExceptions, count: 128, hex: """
            823d49922449922449922449922449922449000000000000001000000000000000020000000000004000000000000000
            080000000000000001000000000000200000000000000004000000000000800000000000000010000000000000000200
            000000000040000000000000000800000000000000010000000000002000000000000000040000000000008000000000
            000000100000000000000002000000000000400000000000000008000000000000000100000000000020000000000000
            000400000000000080000000000000001000000000000000020000000000004000000000000000080000000000000001
            000000000000200000000000000004000000000000800000000000000010000000000000000200000000000040000000
            000000000800000000000000010000000000002000000000000000040000000000008000000000000000100000000000
            0000020000000000004024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4e024c4
            """, label: "denseExceptions"),
        // 64-bit pforSIMD
        Fixture(bits: 64, codec: .pforSIMD, pattern: .wraparound, count: 128, hex: """
            4901fd13540800186020031e6c3806247850d12247910183071231e3c79261438813285dd2d42a60d8e02b63deec2d66
            e4f809d42853210489133934e9d351644994a958bd922a5ac098aa5bc39e2b5dc6a4550bd72e6123078f6d3b37ef7953
            674f5fc1881d1f428a20dfc28b23a0438d2653d60cda59e2240a5fee3c3a65fa546a346bd9b8952b5abaf5ebdabb55ac
            5bbdfdffffffffffff7f00
            """, label: "wraparound"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .exceptionEdges, count: 128, hex: """
            823d03000000000000c003000000000000c0000000000000001000000000000000020000000000004000000000000000
            080000000000000001000000000000200000000000000004000000000000800000000054555555aaaaaa2affffff3f00
            00000054555555aaaaaa2affffff3f
            """, label: "exceptionEdges"),
        Fixture(bits: 64, codec: .pforSIMD, pattern: .denseExceptions, count: 128, hex: """
            823d49922449922449922449922449922449000000000000001000000000000000020000000000004000000000000000
            080000000000000001000000000000200000000000000004000000000000800000000000000010000000000000000200
            000000000040000000000000000800000000000000010000000000002000000000000000040000000000008000000000
            000000100000000000000002000000000000400000000000000008000000000000000100000000000020000000000000
            000400000000000080000000000000001000000000000000020000000000004000000000000000080000000000000001
            000000000000200000000000000004000000000000800000000000000010000000000000000200000000000040000000
            000000000800000000000000010000000000002000000000000000040000000000008000000000000000100000000000
            000002000000000000400000000045511445a2288aa23ccff33c0000000051144551288aa228cff33ccf
            """, label: "denseExceptions"),
        // 64-bit fpx
        Fixture(bits: 64, codec: .fpx, pattern: .floatEdges, count: 16, hex: """
            00813f74f5000000000000004000fcffffffffff1f00ffffffffffffdf7f00000000000010c0ffffffffffff07e0ffff
            ffffffff03200000000000000100482c6a1e59bd0080cecf4ecfce4f0044f5ec3d20b1089edf
            """, label: "IEEE-edges-16"),
        Fixture(bits: 64, codec: .fpx, pattern: .floatEdges, count: 127, hex: """
            008b3534f535f535f535f535f535f535f53575000000000000d0fffffffffffffdffffffffffffffffffffffffffffff
            ffffffff05000000000020406251f3c8ea059d9f9d9e9d9fa27af61e90582400000000000002000000000040ffffffff
            fffff7ffffffffffffffffffffffffffffffffffffff17000000000080008945cd23ab17747e767a767e8aead97b4062
            9100000000000008000000000000fdffffffffffdfffffffffffffffffffffffffffffffffffffff5f00000000000002
            2416358fac5ed0f9d9e9d9f929aa67ef01894502000000000020000000000000f4ffffffffff7fffffffffffffffffff
            ffffffffffffffffffff7f010000000000089058d43cb27a41e767a767e7a7a89ebd0724160900000000008000000000
            0000d0fffffffffffffdffffffffffffffffffffffffffffffffffffff05000000000020406251f3c8ea059d9f9d9e9d
            9fa27af61e90582400000000000002000000000040fffffffffffff7ffffffffffffffffffffffffffffffffffffff17
            000000000080008945cd23ab17747e767a767e8aead97b40629100000000000008000000000000fdffffffffffdfffff
            ffffffffffffffffffffffffffffffffff5f000000000000022416358fac5ed0f9d9e9d9f929aa67ef01894502000000
            000020000000000000f4ffffffffff7fffffffffffffffffffffffffffffffffffffff7f010000000000089058d43cb2
            7a41e767a767e7270008400002100000f03f000308400002100000042000fe0f400002100000f03f0003084000021000
            00042000fe0f400002100000f03f000308400002100000042000fe0f400002100000f03f000308400002100000042000
            fe0f400002100000f03f000308400002100000042000fe0f400002100000f03f000308400002100000042000fe0f4000
            02100000f03f000308400002100000042000fe0f400002100000f03f0003084000021000000400
            """, label: "IEEE-edges-127"),
        Fixture(bits: 64, codec: .fpx, pattern: .floatEdges, count: 128, hex: """
            008b3534f535f535f535f535f535f535f535f5000000000000d0fffffffffffffdffffffffffffffffffffffffffffff
            ffffffff05000000000020406251f3c8ea059d9f9d9e9d9fa27af61e90582400000000000002000000000040ffffffff
            fffff7ffffffffffffffffffffffffffffffffffffff17000000000080008945cd23ab17747e767a767e8aead97b4062
            9100000000000008000000000000fdffffffffffdfffffffffffffffffffffffffffffffffffffff5f00000000000002
            2416358fac5ed0f9d9e9d9f929aa67ef01894502000000000020000000000000f4ffffffffff7fffffffffffffffffff
            ffffffffffffffffffff7f010000000000089058d43cb27a41e767a767e7a7a89ebd0724160900000000008000000000
            0000d0fffffffffffffdffffffffffffffffffffffffffffffffffffff05000000000020406251f3c8ea059d9f9d9e9d
            9fa27af61e90582400000000000002000000000040fffffffffffff7ffffffffffffffffffffffffffffffffffffff17
            000000000080008945cd23ab17747e767a767e8aead97b40629100000000000008000000000000fdffffffffffdfffff
            ffffffffffffffffffffffffffffffffff5f000000000000022416358fac5ed0f9d9e9d9f929aa67ef01894502000000
            000020000000000000f4ffffffffff7fffffffffffffffffffffffffffffffffffffff7f010000000000089058d43cb2
            7a41e767a767e7a7a89ebd072416010008c0000100400001e07f000108400002e0ff0000100000021000fe021080000c
            2000fe0400000107200001042000010fc0000200400000e07f000208400002e0ff000c100000041000fe071080000420
            00fe0f00000100200001e020000108c00002e0400000107f00021040000210ff000c200000040000fe07208000042000
            fe0fc0000100400001e07f000108400002e0ff000010000002100000021080000c200000040000fe07200000042000
            """, label: "IEEE-edges-128"),
        Fixture(bits: 64, codec: .fpx, pattern: .floatEdges, count: 129, hex: """
            008b3534f535f535f535f535f535f535f535f5000000000000d0fffffffffffffdffffffffffffffffffffffffffffff
            ffffffff05000000000020406251f3c8ea059d9f9d9e9d9fa27af61e90582400000000000002000000000040ffffffff
            fffff7ffffffffffffffffffffffffffffffffffffff17000000000080008945cd23ab17747e767a767e8aead97b4062
            9100000000000008000000000000fdffffffffffdfffffffffffffffffffffffffffffffffffffff5f00000000000002
            2416358fac5ed0f9d9e9d9f929aa67ef01894502000000000020000000000000f4ffffffffff7fffffffffffffffffff
            ffffffffffffffffffff7f010000000000089058d43cb27a41e767a767e7a7a89ebd0724160900000000008000000000
            0000d0fffffffffffffdffffffffffffffffffffffffffffffffffffff05000000000020406251f3c8ea059d9f9d9e9d
            9fa27af61e90582400000000000002000000000040fffffffffffff7ffffffffffffffffffffffffffffffffffffff17
            000000000080008945cd23ab17747e767a767e8aead97b40629100000000000008000000000000fdffffffffffdfffff
            ffffffffffffffffffffffffffffffffff5f000000000000022416358fac5ed0f9d9e9d9f929aa67ef01894502000000
            000020000000000000f4ffffffffff7fffffffffffffffffffffffffffffffffffffff7f010000000000089058d43cb2
            7a41e767a767e7a7a89ebd072416010008c0000100400001e07f000108400002e0ff0000100000021000fe021080000c
            2000fe0400000107200001042000010fc0000200400000e07f000208400002e0ff000c100000041000fe071080000420
            00fe0f00000100200001e020000108c00002e0400000107f00021040000210ff000c200000040000fe07208000042000
            fe0fc0000100400001e07f000108400002e0ff000010000002100000021080000c200000040000fe0720000004200001
            ffff07000000000040
            """, label: "IEEE-edges-129"),
        Fixture(bits: 64, codec: .fpx, pattern: .floatEdges, count: 257, hex: """
            008b3534f535f535f535f535f535f535f535f5000000000000d0fffffffffffffdffffffffffffffffffffffffffffff
            ffffffff05000000000020406251f3c8ea059d9f9d9e9d9fa27af61e90582400000000000002000000000040ffffffff
            fffff7ffffffffffffffffffffffffffffffffffffff17000000000080008945cd23ab17747e767a767e8aead97b4062
            9100000000000008000000000000fdffffffffffdfffffffffffffffffffffffffffffffffffffff5f00000000000002
            2416358fac5ed0f9d9e9d9f929aa67ef01894502000000000020000000000000f4ffffffffff7fffffffffffffffffff
            ffffffffffffffffffff7f010000000000089058d43cb27a41e767a767e7a7a89ebd0724160900000000008000000000
            0000d0fffffffffffffdffffffffffffffffffffffffffffffffffffff05000000000020406251f3c8ea059d9f9d9e9d
            9fa27af61e90582400000000000002000000000040fffffffffffff7ffffffffffffffffffffffffffffffffffffff17
            000000000080008945cd23ab17747e767a767e8aead97b40629100000000000008000000000000fdffffffffffdfffff
            ffffffffffffffffffffffffffffffffff5f000000000000022416358fac5ed0f9d9e9d9f929aa67ef01894502000000
            000020000000000000f4ffffffffff7fffffffffffffffffffffffffffffffffffffff7f010000000000089058d43cb2
            7a41e767a767e7a7a89ebd072416010008c0000100400001e07f000108400002e0ff0000100000021000fe021080000c
            2000fe0400000107200001042000010fc0000200400000e07f000208400002e0ff000c100000041000fe071080000420
            00fe0f00000100200001e020000108c00002e0400000107f00021040000210ff000c200000040000fe07208000042000
            fe0fc0000100400001e07f000108400002e0ff000010000002100000021080000c200000040000fe0720000004200000
            8b3535f535f535f535f535f535f535f535f501000000000010000000000000faffffffffffbfffffffffffffffffffff
            ffffffffffffffffffbf00000000000004482c6a1e59bda0f3b3d3b3f35354cfde03128b040000000000400000000000
            00e8fffffffffffffeffffffffffffffffffffffffffffffffffffff0200000000001020b1a87964f582cecf4ecfce4f
            513d7b0f482c12000000000000010000000000a0fffffffffffffbffffffffffffffffffffffffffffffffffffff0b00
            000000004080c4a2e691d50b3a3f3b3d3b3f45f5ec3d20b14800000000000004000000000080feffffffffffefffffff
            ffffffffffffffffffffffffffffffff2f00000000000001128b9a47562fe8fcecf4ecfc14d5b3f780c4220100000000
            0010000000000000faffffffffffbfffffffffffffffffffffffffffffffffffffffbf00000000000004482c6a1e59bd
            a0f3b3d3b3f35354cfde03128b04000000000040000000000000e8fffffffffffffeffffffffffffffffffffffffffff
            ffffffffff0200000000001020b1a87964f582cecf4ecfce4f513d7b0f482c12000000000000010000000000a0ffffff
            fffffffbffffffffffffffffffffffffffffffffffffff0b00000000004080c4a2e691d50b3a3f3b3d3b3f45f5ec3d20
            b14800000000000004000000000080feffffffffffefffffffffffffffffffffffffffffffffffffff2f000000000000
            01128b9a47562fe8fcecf4ecfc14d5b3f780c422fe0fc0000100400001e07f000108400002e0ff0000100000021000fe
            021080000c2000fe0400000107200001042000010fc0000200400000e07f000208400002e0ff000c100000041000fe07
            108000042000fe0f00000100200001e020000108c00002e0400000107f00021040000210ff000c200000040000fe0720
            8000042000fe0fc0000100400001e07f000108400002e0ff000010000002100000021080000c200000040000fe072000
            0004200001ffff07000000000040
            """, label: "IEEE-edges-257"),
    ]
}
