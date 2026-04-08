import Foundation

#if os(Linux)
import Glibc
#endif


extension FileHandle {
    /// Create new file and convert it into a `FileHandle`. For some reason this does not exist in stock swift....
    /// Error on existing file
    /// If `temporary`, a tilde `~` is appended to the filename. On linux flag `O_TMPFILE` is used
    public static func createNewFile(file: String, size: Int? = nil, sparseSize: Int? = nil, overwrite: Bool = false, temporary: Bool = false) throws -> FileHandle {
        let flagOverwrite = overwrite ? O_TRUNC : O_EXCL
        #if os(Linux)
        let flagTemporary = temporary ? O_TMPFILE : 0
        #else
        let flagTemporary = Int32(0)
        #endif
        let flags = O_RDWR | O_CREAT | flagOverwrite | flagTemporary
        // 0644 permissions
        let fn = open(temporary ? "\(file)~" : file, flags, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH)
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
    
    /// If the file was created using `temporary: true` in `createNewFile`. Move the file to its final destination
    func moveTemporary(file: String) throws {
        #if os(Linux)
        try linkAt(file: file)
        #else
        try FileManager.default.moveItem(atPath: "\(file)~", toPath: file)
        #endif
    }
    
    /// Link the file descriptor to a named file. Only works on Linux. Used in combination with `O_TMPFILE`
    func linkAt(file: String) throws {
        #if os(Linux)
        let temporary = "\(file).\(Int32.random(in: 0..<Int32.max))~"
        let res = linkat(AT_FDCWD, "/proc/self/fd/\(fileDescriptor)", AT_FDCWD, temporary, AT_SYMLINK_FOLLOW)
        guard res >= 0 else {
            throw OmFileFormatSwiftError.linkAt(error: res)
        }
        try FileManager.default.moveItem(atPath: temporary, toPath: file)
        #endif
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
