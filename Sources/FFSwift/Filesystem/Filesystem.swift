import Foundation

// MARK: All filesystem operation functions

class FFS {

	let fileHandler: FileHandler
	let state: FilesystemState

	init(password: String) {
		self.state = FilesystemState(password: password)
		self.fileHandler = FileHandler(state: self.state)
	}

	/// Opens file at path and returns file descriptor
	func open(_ path: String, _ flags: Int32) -> Int32 {
		// Implementation
		return 0
	}

	/// Closes file descriptor
	func close(_: Int32) -> Int32 {
		// Implementation
		return 0
	}

	/// Writes count bytes from buf to the file descriptor fd. Returns the number of bytes written
	func write(_: Int32, _: UnsafeRawPointer, _: Int) -> Int {
		// Implementation
		return 0
	}

	/// Reads count bytes from the file descriptor fd into the buffer buf. Returns the number of bytes read
	func read(_: Int32, _: UnsafeMutableRawPointer, _: Int) -> Int {
		// Implementation
		return 0
	}

	/// Creates a new file with the specified name and mode. Returns 0 on success, non-zero on failure
	func creat(_: String, _: mode_t) -> Int32 {
		// Implementation
		return 0
	}

	/// Creates a new directory with the specified name and mode. Returns 0 on success, non-zero on failure
	func mkdir(_: String, _: mode_t) -> Int32 {
		// Implementation
		return 0
	}

	/// Deletes a file at path from the filesystem. Returns 0 on success, non-zero on failure
	func unlink(_: String) -> Int32 {
		// Implementation
		return 0
	}

	/// Deletes a directory at path from the filesystem. Returns 0 on success, non-zero on failure
	func rmdir(_: String) -> Int32 {
		// Implementation
		return 0
	}

	/// Changes the name of a file from old to new. Returns 0 on success, non-zero on failure
	func rename(_: String, _: String) -> Int32 {
		// Implementation
		return 0
	}
}
