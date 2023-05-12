import Foundation

class StorageState {
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

	internal func upload(data: Data, to ows: OnlineWebService) async throws -> Post {
		let owsClient = try getOWSClient(for: ows)

		let postID = try await owsClient.upload(data: data)

		return Post(ows: ows, id: postID)
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

	// func createFile(
	// 	in directory: Directory, 
	// 	with name: String, 
	// 	using ows: OnlineWebService, 
	// 	data: Data
	// ) async throws -> Inode {
	// 	let owsClient = try getOWSClient(for: ows)

	// 	// TODO: This must take an argument with largest possible size, and split it
	// 	let ffsData = try FFSEncoder.encode(data, password: password)
		
	// 	try await owsClient.upload(data: ffsData)

	// 	// TODO: Add posts
	// 	let inodeTableEntry = self.createInodeEntry(with: data.count, isDirectory: false, posts: [])

	// 	// TODO: Update directory with new entry
	// 	// TODO: Upload new directory data


	// 	let inode = self.inodeTable.add(entry: entry)

	// 	return inode
	// }

	internal func getData(from entry: InodeTableEntry) async throws -> [Data] {
		let datas = try await loadAsyncList(items: entry.posts) { post async throws in
			let client = try self.getOWSClient(for: post.ows)
			return try await client.get(with: post.id)
		}

		return datas
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
