import Foundation

class StorageState {
	var inodeTablePosts: [Post]
	let inodeTable: InodeTable
	let password: String // TODO: Find better way to store password

	init(inodeTable: InodeTable, password: String, tablePosts: [Post]) {
		self.inodeTable = inodeTable
		self.password = password
		inodeTablePosts = tablePosts
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
			posts: posts
		)

		return entry
	}

	/// Delete a post from its ows
	internal func delete(post: Post) async throws {
		let owsClient = try getOWSClient(for: post.ows)

		await owsClient.delete(id: post.id)
	}

	/// Deletes the posts from the OWS in a background task
	internal func delete(posts: [Post]) {
		// Remove old posts of directory and inode table on another thread
		// We don't care about the result of this task
		Task {
			for post in posts {
				try await delete(post: post)
			}
		}
	}

	/// Update the inode table on the OWS, and remove the old data
	internal func update(inodeTable: InodeTable, to ows: OnlineWebService) async throws {
		let currentInodeTablePosts = inodeTablePosts

		// Update inode table on ows
		inodeTablePosts = try await upload(data: inodeTable.raw, to: ows)

		delete(posts: currentInodeTablePosts)
	}

	/// Update the directory on the OWS, and remove the old data. Updates the current instance
	/// of the inode table, but doesn't update it on the OWS
	internal func update(directory: Directory, to ows: OnlineWebService) async throws {
		let directoryInodeEntry = try inodeTable.get(with: directory.selfInode)

		let currentDirectoryPosts = directoryInodeEntry.posts

		// Upload new directory data
		let rawDirectory = directory.raw
		let updatedDirectoryPosts = try await upload(data: rawDirectory, to: ows)

		// Update directory entry in inode table
		directoryInodeEntry.posts = updatedDirectoryPosts

		delete(posts: currentDirectoryPosts)
	}

	/// Update the file data on the OWS, and remove the old data. Updates the current instance
	/// of the inode table, but doesn't update it on the OWS
	internal func update(file withInodeEntry: InodeTableEntry, to ows: OnlineWebService, data: Data) async throws {
		let currentFilePosts = withInodeEntry.posts

		withInodeEntry.posts = try await upload(data: data, to: ows)
		withInodeEntry.metadata.size = UInt64(data.count)
		withInodeEntry.metadata.timeUpdated = UInt64(Date().timeIntervalSince1970)

		delete(posts: currentFilePosts)
	}

	func createFile(
		in directory: Directory,
		with name: String,
		using ows: OnlineWebService,
		data: Data
	) async throws -> Inode {
		// Add file entry in inode table with no posts, they will be added later
		// Calling delete on an empty list will do nothing
		let inodeTableEntry = createInodeEntry(
			with: UInt64(data.count),
			isDirectory: false,
			posts: []
		)
		let inode = inodeTable.add(entry: inodeTableEntry)

		// Add file to directory
		try directory.add(filename: name, with: inode)

		await withThrowingTaskGroup(of: Void.self) { group async in
			group.addTask {
				// Upload file data
				try await self.update(file: inodeTableEntry, to: ows, data: data)
			}

			group.addTask {
				// Update directory as it has been modified
				try await self.update(directory: directory, to: ows)
			}
		}

		// Update inode table. This must be done after the directory and file have been updated
		// so their new posts are accounted for
		try await update(inodeTable: inodeTable, to: ows)

		return inode
	}

	func updateFile(
		in directory: Directory,
		with name: String,
		using ows: OnlineWebService,
		data: Data
	) async throws {
		// Get inode of file
		let inode = try directory.inode(of: name)

		// Get inode entry
		let inodeEntry = try inodeTable.get(with: inode)

		// Update file data
		try await update(file: inodeEntry, to: ows, data: data)

		// Update inode table
		try await update(inodeTable: inodeTable, to: ows)
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
