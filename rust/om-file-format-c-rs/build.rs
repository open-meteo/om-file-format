use std::env;
use std::path::PathBuf;
use std::process::Command;

struct BuildConfig {
    // target: String,
    arch: String,
    sysroot: Option<String>,
    use_skylake: bool,
    is_windows: bool,
}

fn get_build_config() -> BuildConfig {
    BuildConfig {
        arch: env::var("CARGO_CFG_TARGET_ARCH").unwrap(),
        sysroot: env::var("SYSROOT").ok(),
        use_skylake: env::var("MARCH_SKYLAKE")
            .map(|v| v == "TRUE")
            .unwrap_or(false),
        is_windows: env::var("TARGET").unwrap().contains("windows"),
    }
}

fn get_submodule_path() -> PathBuf {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    // Navigate up two levels to get the C code we want to compile
    manifest_dir.join("./c")
}

fn setup_compiler(build: &mut cc::Build) -> cc::Tool {
    // Check if CC is set in environment
    if let Ok(cc) = env::var("CC") {
        build.compiler(cc);
    } else {
        // Try using clang if available
        let clang_available = Command::new("clang")
            .arg("--version")
            .output()
            .map(|output| output.status.success())
            .unwrap_or(false);

        if clang_available {
            build.compiler("clang");
        }
        // Otherwise cc::Build will use system default
    }

    build.get_compiler()
}

fn configure_build_flags(build: &mut cc::Build, config: &BuildConfig, compiler: &cc::Tool) {
    // Basic compiler flags
    build.flag("-O3");

    // --- Architecture-specific flags ---
    match config.arch.as_str() {
        "aarch64" => {
            // ARM64
            build.flag("-march=armv8-a");
        }
        "x86_64" => {
            // x86_64 Architecture
            if config.is_windows && compiler.is_like_msvc() {
                // No special flags needed for MSVC atm
            } else {
                // Choose between skylake and native based on environment variable
                if config.use_skylake {
                    build.flag("-march=skylake");
                } else {
                    build.flag("-march=native");
                }
            }
        }
        _ => {
            // Handle other architectures if necessary
        }
    }
}

fn generate_bindings(submodule: &str, sysroot: &Option<String>) {
    let bindings = bindgen::Builder::default()
        // Set sysroot for bindgen if specified (for cross compilation)
        .clang_arg(
            sysroot
                .as_ref()
                .map_or("".to_string(), |s| format!("--sysroot={}", s)),
        )
        .clang_arg(format!("-I{}/include", submodule))
        .header(format!("{}/include/om_file_format.h", submodule))
        .generate()
        .expect("Unable to generate bindings");

    // Write the bindings to the $OUT_DIR/bindings.rs file
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}

fn main() {
    const LIB_NAME: &str = "omfileformatc";
    let submodule_path = get_submodule_path();

    if !submodule_path.exists() {
        panic!("Could not find submodule at {:?}", submodule_path);
    }

    // Re-run build script if these files change
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=src/lib.rs");
    println!("cargo:rerun-if-changed={}", submodule_path.display());

    let config = get_build_config();
    let mut build = cc::Build::new();
    let compiler = setup_compiler(&mut build);

    println!("cargo:compiler={:?}", compiler.path());

    // Include directories
    build.include(format!("{}/include", submodule_path.display()));
    // Add all .c files from the submodule's src directory
    let src_path = format!("{}/src", submodule_path.display());
    for entry in std::fs::read_dir(&src_path).unwrap() {
        let path = entry.unwrap().path();
        if path.extension().and_then(|e| e.to_str()) == Some("c") {
            build.file(path);
        }
    }

    configure_build_flags(&mut build, &config, &compiler);

    // Set sysroot if specified
    if let Some(sysroot_path) = &config.sysroot {
        build.flag(&format!("--sysroot={}", sysroot_path));
    }

    // Print compiler information
    // print_compiler_info(&build);

    // Compile the library
    build.warnings(false);
    build.compile(LIB_NAME);

    generate_bindings(submodule_path.to_str().unwrap(), &config.sysroot);

    // Link the static library
    println!("cargo:rustc-link-lib=static={}", LIB_NAME);
}

// Add this function to print detailed compiler configuration
#[allow(dead_code)]
fn print_compiler_info(build: &cc::Build) {
    let compiler = build.get_compiler();

    println!("cargo:warning=Compiler Configuration:");
    println!("cargo:warning=Path: {:?}", compiler.path());
    println!("cargo:warning=Is Clang: {}", compiler.is_like_clang());
    println!("cargo:warning=Is Gnu: {}", compiler.is_like_gnu());
    println!("cargo:warning=Is MSVC: {}", compiler.is_like_msvc());
    println!("cargo:warning=Arguments: {:?}", compiler.args());

    // Print environment variables that might affect compilation
    let relevant_vars = [
        "CC",
        "CFLAGS",
        "CXXFLAGS",
        "RUSTFLAGS",
        "TARGET",
        "HOST",
        "CARGO_CFG_TARGET_ARCH",
    ];

    println!("cargo:warning=Relevant Environment Variables:");
    for var in relevant_vars {
        if let Ok(value) = env::var(var) {
            println!("cargo:warning={}={}", var, value);
        }
    }

    // Print all configured flags
    println!("cargo:warning=Configured Build Flags:");
    for arg in compiler.args() {
        if let Some(flag) = arg.to_str() {
            println!("cargo:warning=Flag: {}", flag);
        }
    }
}
