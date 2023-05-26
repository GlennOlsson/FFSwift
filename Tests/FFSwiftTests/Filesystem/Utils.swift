@testable import FFSwift
import Foundation

let OWS_CASE: OnlineWebService = .local
let DIR_INODE: Inode = 0
let DIR_POST_ID: String = "0"
let DIR_SIZE: UInt64 = 50

let FILE_INODE: Inode = 1
let FILE_POST_ID: String = "1"
let FILE_SIZE: UInt64 = 50
let FILE_NAME = "file.txt"

let CREATED_DATE: Date = .init()
let UPDATED_DATE: Date = UPDATED_DATE.addingTimeInterval(200)
let ACCESSED_DATE: Date = ACCESSED_DATE.addingTimeInterval(400)

let INODE_TABLE_POST_ID = "-1"
let INODE_TABLE_POST: Post = .init(ows: OWS_CASE, id: INODE_TABLE_POST_ID)

let PASSWORD = "password"

/// Client where the functions are defined in the init
class MockedOWSClient: OWSClient {
    var sizeLimit: Int = .max

	var _get: ((_: String) async throws -> Data)
	var _upload: ((_: Data) async throws -> String)
	var _getRecent: ((_: Int) async throws -> [String])
	var _delete: ((_: String) async -> Void)

	/// Only needed functions needs to be passed
	init(
		get: @escaping (_: String) async throws -> Data = { _ in Data() },
		upload: @escaping (_: Data) async throws -> String = { _ in "mocked-id"},
		getRecent: @escaping (_: Int) async throws -> [String] = { _ in ["mocked-id"] },
		delete: @escaping (_: String) async -> Void = { _ in}
	) {
		_get = get
		_upload = upload
		_getRecent = getRecent
		_delete = delete
	}

	func get(with id: String) async throws -> Data {
		return try await _get(id)
	}

	func upload(data: Data) async throws -> String {
		return try await _upload(data)
	}

	func getRecent(n: Int) async throws -> [String] {
		return try await _getRecent(n)
	}

	func delete(id: String) async {
		await _delete(id)
	}
}

// Fake inode table
func mockedInodeTable() -> InodeTable {
	InodeTable(entries: [
		DIR_INODE: InodeTableEntry( // Mocked directory
			size: DIR_SIZE,
			isDirectory: true,
			timeCreated: UInt64(CREATED_DATE.timeIntervalSince1970),
			timeUpdated: UInt64(UPDATED_DATE.timeIntervalSince1970),
			posts: [
				Post(
					ows: OWS_CASE,
					id: DIR_POST_ID
				),
			]
		),
		FILE_INODE: InodeTableEntry( // Mocked file
			size: FILE_SIZE,
			isDirectory: false,
			timeCreated: UInt64(CREATED_DATE.timeIntervalSince1970),
			timeUpdated: UInt64(UPDATED_DATE.timeIntervalSince1970),
			posts: [
				Post(
					ows: OWS_CASE,
					id: FILE_POST_ID
				),
			]
		),
	])
}

// Fake directory
func mockedDirectory() -> Directory {
	try! Directory(entries: [
		FILE_NAME: FILE_INODE,
	], inode: DIR_INODE)
}

func mockedStorageState(inodeTable: InodeTable, owsClient: OWSClient) -> StorageState {
	let state = StorageState(
		password: PASSWORD
	)
	state.inodeTable = inodeTable
	state.inodeTablePosts = [
		INODE_TABLE_POST,
	]

	state.addOWS(client: owsClient, for: OWS_CASE)

	return state
}