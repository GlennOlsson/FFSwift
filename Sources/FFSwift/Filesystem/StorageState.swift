import Foundation

class StorageState {
	var inodeTablePosts: [Post] = []
	let inodeTable: InodeTable
	let password: String // TODO: Find better way to store password

	init(inodeTable: InodeTable, password: String) {
		self.inodeTable = inodeTable
		self.password = password
	}

	func getFile(with inode: Inode) async throws -> Data {
		guard let entry = inodeTable.entries[inode] else {
			throw FilesystemException.noFileWithInode(inode)
		}

		if entry.metadata.isDirectory {
			throw FilesystemException.isDirectory(inode)
		}

		let imageData = try await getData(from: entry)

		let fileData = try FFSDecoder.decode(imageData, password: password)

		return fileData
	}

	func getDirectory(with inode: Inode) async throws -> Directory {
		guard let entry = inodeTable.entries[inode] else {
			throw FilesystemException.noFileWithInode(inode)
		}

		if !entry.metadata.isDirectory {
			throw FilesystemException.isFile
		}

		let imageData = try await getData(from: entry)

		let directoryData = try FFSDecoder.decode(imageData, password: password)

		return try Directory(raw: directoryData)
	}

	internal func upload(data: Data, to ows: OnlineWebService) async throws -> [Post] {
		let owsClient = try getOWSClient(for: ows)

		let encodedData = try FFSEncoder.encode(data, password: password, limit: owsClient.sizeLimit)

		let postIDs = try await loadAsyncList(items: encodedData, using: owsClient.upload(data:))

		let posts = postIDs.map { Post(ows: ows, id: $0) }

		return posts
	}

	internal func delete(post: Post) async throws {
		let owsClient = try getOWSClient(for: post.ows)

		await owsClient.delete(id: post.id)
	}

	internal func createInodeEntry(
		with size: UInt64,
		isDirectory: Bool,
		posts: [Post]
	) -> InodeTableEntry {
		let currentTime = UInt64(Date().timeIntervalSince1970)

		let entry = InodeTableEntry(
			size: size,
			isDirectory: isDirectory,
			timeCreated: currentTime,
			timeUpdated: currentTime,
			timeAccessed: currentTime,
			posts: posts
		)

		return entry
	}

	func createFile(
		in directory: Directory,
		with name: String,
		using ows: OnlineWebService,
		data: Data
	) async throws -> Inode {
		// Upload file data
		let filePosts = try await upload(data: data, to: ows)

		// Add file entry in inode table
		let inodeTableEntry = createInodeEntry(
			with: UInt64(data.count), 
			isDirectory: false, 
			posts: filePosts
		)
		let inode = inodeTable.add(entry: inodeTableEntry)

		// Add file to directory
		try directory.add(filename: name, with: inode)

		let directoryInodeEntry = try inodeTable.get(with: directory.selfInode)

		let currentDirectoryPosts = directoryInodeEntry.posts
		let currentInodeTablePosts = inodeTablePosts

		// Upload new directory data
		let rawDirectory = directory.raw
		let updatedDirectoryPosts = try await upload(data: rawDirectory, to: ows)

		// Update directory entry in inode table
		directoryInodeEntry.posts = updatedDirectoryPosts

		// Update inode table on ows
		inodeTablePosts = try await upload(data: inodeTable.raw, to: ows)

		// Remove old posts of directory and inode table on another thread
		// We don't care about the result of this task
		Task {
			for post in currentDirectoryPosts + currentInodeTablePosts {
				try await delete(post: post)
			}
		}

		return inode
	}

	internal func getData(from entry: InodeTableEntry) async throws -> [Data] {
		let data: [Data] = try await loadAsyncList(items: entry.posts) { post async throws in
			let client = try self.getOWSClient(for: post.ows)
			return try await client.get(with: post.id)
		}

		return data
	}

	var owsMapping: [OnlineWebService: OWSClient] = [:]

	func addOWS(client: OWSClient, for ows: OnlineWebService) {
		owsMapping[ows] = client
	}

	func getOWSClient(for ows: OnlineWebService) throws -> OWSClient {
		// check if key is in map
		guard let client = owsMapping[ows] else {
			throw OWSError.unsupportedOWS
		}

		return client
	}
}
