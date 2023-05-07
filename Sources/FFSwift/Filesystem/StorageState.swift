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

	internal func getData(from entry: InodeTableEntry) async throws -> Data {
		let data = try await concatAsyncData(items: entry.posts) { post async throws in
			let client = try self.getOWS(for: post.ows)
			return try await client.get(with: post.id)
		}

		return data
	}

	var owsMapping: [OnlineWebService: OWSClient?] = [:]

	func addOWS(client: OWSClient, for ows: OnlineWebService) {
		owsMapping[ows] = client
	}

	func getOWS(for ows: OnlineWebService) throws -> OWSClient {
		// check if key is in map. If key is in check if value of key is nil
		guard let valueInMap = owsMapping[ows] else {
			throw OWSError.unsupportedOWS
		}

		guard let client = valueInMap else {
			throw OWSError.notAuthenticated
		}

		return client
	}
}
