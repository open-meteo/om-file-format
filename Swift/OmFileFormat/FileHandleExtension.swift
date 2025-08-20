import Foundation


extension FileHandle {
    /// Create new file and convert it into a `FileHandle`. For some reason this does not exist in stock swift....
    /// Error on existing file
    public static func createNewFile(file: String, size: Int? = nil, sparseSize: Int? = nil, overwrite: Bool = false) throws -> FileHandle {
        let flagOverwrite = overwrite ? O_TRUNC : O_EXCL
        let flags = O_RDWR | O_CREAT | flagOverwrite
        // 0644 permissions
        let fn = open(file, flags, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH)
        guard fn > 0 else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotCreateFile(filename: file, errno: errno, error: error)
        }

        let handle = FileHandle(fileDescriptor: fn, closeOnDealloc: true)
        if let sparseSize {
            guard ftruncate(fn, off_t(sparseSize)) == 0 else {
                let error = String(cString: strerror(errno))
                throw OmFileFormatSwiftError.cannotTruncateFile(filename: file, errno: errno, error: error)
            }
        }
        if let size {
            try handle.preAllocate(size: size)
        }
        try handle.seek(toOffset: 0)
        return handle
    }

    /// Allocate the required diskspace for a given file
    func preAllocate(size: Int) throws {
        #if os(Linux)
        let error = posix_fallocate(fileDescriptor, 0, size)
        guard error == 0 else {
            throw OmFileFormatSwiftError.posixFallocateFailed(error: error)
        }
        #else
        // Try to allocate continuous space first
        var store = fstore(fst_flags: UInt32(F_ALLOCATECONTIG), fst_posmode: F_PEOFPOSMODE, fst_offset: 0, fst_length: off_t(size), fst_bytesalloc: 0)
        var error = fcntl(fileDescriptor, F_PREALLOCATE, &store)
        if error == -1 {
            // Try non-continuous
            store.fst_flags = UInt32(F_PREALLOCATE)
            error = fcntl(fileDescriptor, F_PREALLOCATE, &store)
        }
        guard error >= 0 else {
            throw OmFileFormatSwiftError.posixFallocateFailed(error: error)
        }
        let error2 = ftruncate(fileDescriptor, off_t(size))
        guard error2 >= 0 else {
            throw OmFileFormatSwiftError.ftruncateFailed(error: error2)
        }
        #endif
    }

    /// Open file for reading
    public static func openFileReading(file: String) throws -> FileHandle {
        // 0644 permissions
        // O_TRUNC for overwrite
        let fn = open(file, O_RDONLY, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH)
        guard fn > 0 else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotOpenFile(filename: file, errno: errno, error: error)
        }
        let handle = FileHandle(fileDescriptor: fn, closeOnDealloc: true)
        return handle
    }

    /// Open file for read/write
    public static func openFileReadWrite(file: String) throws -> FileHandle {
        // 0644 permissions
        // O_TRUNC for overwrite
        let fn = open(file, O_RDWR, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH)
        guard fn > 0 else {
            let error = String(cString: strerror(errno))
            throw OmFileFormatSwiftError.cannotOpenFile(filename: file, errno: errno, error: error)
        }
        let handle = FileHandle(fileDescriptor: fn, closeOnDealloc: true)
        return handle
    }
}

/// Make `FileHandle` work as writer
extension FileHandle: OmFileWriterBackend {
    
}
