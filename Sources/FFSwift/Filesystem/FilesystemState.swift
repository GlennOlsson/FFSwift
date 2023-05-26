import Foundation

public typealias FileDescriptor = UInt64

struct OpenFile {
	let inode: Inode
	let parentInode: Inode
	// Set if file has been updated
	var data: Data? = nil
}

class FilesystemState {
	let storageState: StorageState
	var openFiles: [FileDescriptor: OpenFile]

	init(storage: StorageState) {
		self.openFiles = [:]
		self.storageState = storage
	}

	internal func getNextFD() -> FileDescriptor {
		// Append one to the max FD. Even if we would create a new descriptor every microsecond, the
		// descriptor will not overflow until after 584,942,417 years
		let maxFD = self.openFiles.keys.max()
		// First inode should be 0
		return maxFD?.advanced(by: 1) ?? 0
	}

	func open(inode: Inode, in parent: Directory) -> FileDescriptor {
		let fd = getNextFD()

		let fileStruct = OpenFile(inode: inode, parentInode: parent.selfInode)

		self.openFiles[fd] = fileStruct

		return fd
	}

	func close(_ fd: FileDescriptor) async throws {
		guard let openFile = self.openFiles[fd] else {
			throw FilesystemError.fileNotOpen
		}
		defer {
			self.openFiles.removeValue(forKey: fd)
		}

		if let data = openFile.data {
			let ows = storageState.appropriateOWS(for: data.count)
			try await self.storageState.update(fileWith: openFile.inode, to: ows, data: data)
		}
	}

	func updateData(for fd: FileDescriptor, data: Data) throws {
		guard var openFile = self.openFiles[fd] else {
			throw FilesystemError.fileNotOpen
		}

		openFile.data = data
	}
}