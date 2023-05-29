import Foundation

class FilesystemState {
	internal var inodeTablePosts: [Post]!
	internal var inodeTable: InodeTable!
	internal let password: String // TODO: Find better way to store password

	var owsMapping: [OnlineWebService: OWSClient] = [:]

	/// Get the post as an Inode table using the password for decrypting
	internal func getInodeTable(from ows: OWSClient, postID: String) async throws -> InodeTable {
		let postData = try await ows.get(with: postID)

		let inodeTableData = try FFSDecoder.decode([postData], password: password)

		let inodeTable = try InodeTable.init(raw: inodeTableData)

		return inodeTable
	}

	/// If the ID is know, it should be passed. Otherwise, the first post stored on the
	/// ows will be used.
	func loadInodeTable(from ows: OnlineWebService, with knownPostID: String? = nil) async throws {
		let owsClient = try getOWSClient(for: ows)
		let postID: String!
		if knownPostID == nil {
			let postIDs = try await owsClient.getRecent(n: 1)

			guard let firstPostID = postIDs.first else {
				throw FilesystemStateError.couldNotInitialize
			}
			postID = firstPostID
		} else {
			postID = knownPostID
		}

		let post = Post(ows: ows, id: postID)
		self.inodeTablePosts = [post]

		self.inodeTable = try await getInodeTable(from: owsClient, postID: postID)
	}

	/// Initializes the state with a password. Before any other function can be called,
	/// the inode table needs to be loaded using `loadInodeTable`. The OWS storing the 
	/// inode table must first be added using `addOWS`.
	init(password: String) {
		self.password = password
	}

	/// Get the file data from a file with a given inode
	func getFile(with inode: Inode) async throws -> Data {
		guard let entry = inodeTable.entries[inode] else {
			throw FilesystemError.noFileWithInode(inode)
		}

		if entry.metadata.isDirectory {
			throw FilesystemError.isDirectory(inode)
		}

		let fileData = try await getData(from: entry)

		return fileData
	}

	/// Get a directory with the inode from the OWS
	func getDirectory(with inode: Inode) async throws -> Directory {
		guard let entry = inodeTable.entries[inode] else {
			throw FilesystemError.noFileWithInode(inode)
		}

		if !entry.metadata.isDirectory {
			throw FilesystemError.isFile
		}

		let directoryData = try await getData(from: entry)

		return try Directory(raw: directoryData)
	}

	internal func createInodeEntry(
		isDirectory: Bool
	) -> Inode {
		let currentDate = Date()
		// Converting Double to UInt64 is safe, only loosing < second precision
		let currentTime = UInt64(currentDate.timeIntervalSince1970)

		let entry = InodeTableEntry(
			size: 0,
			isDirectory: isDirectory,
			timeCreated: currentTime,
			timeUpdated: currentTime,
			posts: []
		)

		let inode = inodeTable.add(entry: entry)

		return inode
	}

	/// Delete a post from its ows
	internal func delete(post: Post) async throws {
		try await Storage.remove(post: post, with: owsMapping)
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
		let currentInodeTablePosts = self.inodeTablePosts!

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
	internal func update(fileWith inode: Inode, to ows: OnlineWebService, data: Data) async throws {
		let inodeTableEntry = try inodeTable.get(with: inode)
		let currentFilePosts = inodeTableEntry.posts

		inodeTableEntry.posts = try await upload(data: data, to: ows)
		inodeTableEntry.metadata.size = UInt64(data.count)
		inodeTableEntry.metadata.timeUpdated = UInt64(Date().timeIntervalSince1970)

		delete(posts: currentFilePosts)
	}

	func upload(data: Data, to: OnlineWebService) async throws -> [Post] {
		let owsClient = try getOWSClient(for: to)

		return try await Storage.upload(data: data, to: owsClient, with: password)
	}

	/// Create an entry in the directory, and upload the file data to the OWS
	internal func create(
		in directory: Directory,
		with inode: Inode,
		named name: String,
		using ows: OnlineWebService,
		isDirectory: Bool,
		data: Data
	) async throws -> Inode {
		
		// Add file to directory
		try directory.add(filename: name, with: inode)

		try await withThrowingTaskGroup(of: Void.self) { group async throws in
			group.addTask {
				// Upload file data
				try await self.update(fileWith: inode, to: ows, data: data)
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

	/// Create a file in the filesystem with the provided data, in the parent directory
	/// Stored on the provided OWS
	func create(
		fileData: Data,
		in parentDirectory: Directory,
		named name: String,
		using ows: OnlineWebService
	) async throws -> Inode {
		let inode = createInodeEntry(
			isDirectory: false
		)

		return try await self.create(
			in: parentDirectory, 
			with: inode,
			named: name, 
			using: ows, 
			isDirectory: true,
			data: fileData
		)
	}

	/// Create a directory in the filesystem with the provided data, in the parent directory
	/// Stored on the provided OWS
	func create(
		directory: Directory,
		in parentDirectory: Directory,
		named name: String,
		using ows: OnlineWebService
	) async throws -> Inode {
		let inode = createInodeEntry(
			isDirectory: true
		)

		directory.selfInode = inode

		return try await self.create(
			in: parentDirectory, 
			with: inode,
			named: name, 
			using: ows, 
			isDirectory: true,
			data: directory.raw
		)
	}

	/// Update a file with an inode with the provided data, on the provided OWS
	// Does not have to update parent dir as the name and id does not change
	func update(
		with inode: Inode,
		using ows: OnlineWebService,
		data: Data
	) async throws {
		// Update file data
		try await update(fileWith: inode, to: ows, data: data)

		// Update inode table
		try await update(inodeTable: inodeTable, to: ows)
	}

	/// Update a directory with an inode with the provided data, on the provided OWS
	func update(
		with inode: Inode,
		using ows: OnlineWebService,
		directory: Directory
	) async throws {
		try await self.update(with: inode, using: ows, data: directory.raw)
	}

	// Download the posts of an inode table entry from the OWS, 
	// decode the images and decrypt the data. Returns the pure FFS data stored 
	// on the OWS for the entry
	internal func getData(from entry: InodeTableEntry) async throws -> Data {
		return try await Storage.download(posts: entry.posts, with: password, mapping: owsMapping)
	}

	/// Add an OWS to the filesystem 
	func addOWS(client: OWSClient) {
		owsMapping[client.ows] = client
	}

	func getOWSClient(for ows: OnlineWebService) throws -> OWSClient {
		return try FFSwift.getOWSClient(of: ows, with: owsMapping)
	}

	/// Get an OWS that is appropriate for the provided data count
	/// TODO: Optimize this
	func appropriateOWS(for dataCount: Int) -> OnlineWebService {
		return .local
	}
}
