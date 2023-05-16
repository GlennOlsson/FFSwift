@testable import FFSwift
import Foundation
import XCTest

class StorageStateTester: XCTestCase {
	let password = "password"

	var state: StorageState!
	var inodeTable: InodeTable!
	var owsClient: MockedOWSClient!

	override func setUp() {
		inodeTable = mockedInodeTable()
		state = StorageState(
			inodeTable: inodeTable,
			password: password,
			tablePosts: [
				INODE_TABLE_POST,
			]
		)
		owsClient = MockedOWSClient()
		state.addOWS(client: owsClient, for: OWS_CASE)
	}

	func testGetFileReturnsCorrectData() async {
		let data = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		owsClient._get = { _ in
			try! FFSEncoder.encode(data, password: self.password, limit: .max).first!
		}

		let fileData = try! await state.getFile(with: FILE_INODE)

		XCTAssertEqual(fileData, data)
	}

	func testGetFileThrowsForBadInode() async {
		let badInode: Inode = .max
		do {
			_ = try await state.getFile(with: badInode)
			XCTFail("Did not throw for bad inode")
		} catch {
			XCTAssertEqual(error as! FilesystemException, FilesystemException.noFileWithInode(badInode))
		}
	}

	func testGetFileThrowsForDirectory() async {
		let inode = DIR_INODE
		do {
			_ = try await state.getFile(with: inode)
			XCTFail("Did not throw for dir inode")
		} catch {
			XCTAssertEqual(error as! FilesystemException, FilesystemException.isDirectory(inode))
		}
	}

	func testGetDirectoryReturnsCorrectDirectory() async {
		let directory = mockedDirectory()
		owsClient._get = { _ in
			try! FFSEncoder.encode(directory.raw, password: self.password, limit: .max).first!
		}

		let returnedDirectory = try! await state.getDirectory(with: DIR_INODE)

		XCTAssertEqual(directory, returnedDirectory)
	}

	func testGetDirectoryThrowsForFile() async {
		let inode = FILE_INODE
		do {
			_ = try await state.getDirectory(with: inode)
			XCTFail("Did not throw for file inode")
		} catch {
			XCTAssertEqual(error as! FilesystemException, FilesystemException.isFile)
		}
	}

	func testDirectoryFileThrowsForBadInode() async throws {
		let badInode: Inode = .max
		do {
			_ = try await state.getDirectory(with: badInode)
			XCTFail("Did not throw for bad inode")
		} catch {
			XCTAssertEqual(error as! FilesystemException, FilesystemException.noFileWithInode(badInode))
		}
	}

	func testGetOWSClientThrowsForNotAddedOWS() {
		state.owsMapping.removeValue(forKey: OWS_CASE)

		XCTAssertThrowsError(try state.getOWSClient(for: OWS_CASE)) { error in
			XCTAssertEqual(error as! OWSError, OWSError.unsupportedOWS)
		}
	}

	func testGetDataReturnsAllData() async {
		let data = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		owsClient._get = { id in
			if id == FILE_POST_ID {
				return data
			} else {
				return Data()
			}
		}

		let inodeEntry = try! inodeTable.get(with: FILE_INODE)

		let receivedData = try! await state.getData(from: inodeEntry)

		XCTAssertEqual(receivedData.count, 1)
		XCTAssertEqual(receivedData.first!, data)
	}

	func testCreateFileReturnsCorrectInode() async {
		let nextInode = inodeTable.getNextInode()

		// Mock these calls but don't have to return/do anything valuable
		owsClient._delete = { _ in
		}

		owsClient._get = { _ in
			Data()
		}

		owsClient._upload = { _ in
			"mock-id"
		}

		let inode = try! await state.createFile(in: mockedDirectory(), with: "new-file.txt", using: OWS_CASE, data: Data())

		XCTAssertEqual(inode, nextInode)
	}

	func testCreateFileCallsDeleteOnOldPosts() async {
		let expectation = self.expectation(description: "Delete called on expected posts")

		var expectedPostsIDs = [
			DIR_POST_ID,
			INODE_TABLE_POST_ID,
		]

		expectation.expectedFulfillmentCount = expectedPostsIDs.count

		owsClient._delete = { id in
			if let index = expectedPostsIDs.firstIndex(of: id) {
				// Make sure it is not counting the same call twice
				expectedPostsIDs.remove(at: index)
				expectation.fulfill()
			} else {
				XCTFail("Unexpected delete call on post \(id)")
			}
		}

		owsClient._get = { _ in
			Data()
		}

		owsClient._upload = { _ in
			"mock-id"
		}

		let _ = try! await state.createFile(in: mockedDirectory(), with: "new-file.txt", using: OWS_CASE, data: Data())

		await waitForExpectations(timeout: 1, handler: nil)
	}

	func testUpdateInodeTableCallsDeleteOnInodeTablePost() async {
		let expectation = self.expectation(description: "delete is called on the Inode Table Post")

		expectation.expectedFulfillmentCount = 1

		owsClient._delete = { id in
			if id == INODE_TABLE_POST_ID {
				expectation.fulfill()
			}
		}

		owsClient._get = { _ in
			Data()
		}

		owsClient._upload = { _ in
			"mock-id"
		}

		let _ = try! await state.update(inodeTable: inodeTable, to: OWS_CASE)

		await waitForExpectations(timeout: 1)
	}

	func testUploadReturnsCorrectID() async {
		let data = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		let id = "mock-id"

		owsClient.sizeLimit = .max

		owsClient._upload = { _ in
			id
		}

		let postID = try! await state.upload(data: data, to: OWS_CASE)

		// Should be 1 as the limit is so high
		XCTAssertEqual(postID.count, 1)
		XCTAssertEqual(postID.first!.id, id)
	}

	func testUploadUploadsFFSData() async {
		let data = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		// So we can expect 1 upload only
		owsClient.sizeLimit = .max

		var uploadedData: Data!
		owsClient._upload = { data in
			uploadedData = data
			return "mock-id"
		}

		let _ = try! await state.upload(data: data, to: OWS_CASE)

		// Here uploadedData will be set

		let decodedData = try! FFSDecoder.decode([uploadedData], password: password)

		XCTAssertEqual(decodedData, data)
	}

	func testUpdateDirectoryUploadsDirectoryData() async {
		let dir = mockedDirectory()

		// So we can expect 1 upload only
		owsClient.sizeLimit = .max

		var uploadedData: Data!
		owsClient._upload = { data in
			uploadedData = data
			return "mock-id"
		}

		owsClient._delete = { _ in
		}

		let _ = try! await state.update(directory: dir, to: OWS_CASE)

		// Here uploadedData will be set

		let decodedData = try! FFSDecoder.decode([uploadedData], password: password)

		XCTAssertEqual(decodedData, dir.raw)
	}

	func testUpdateDirectoryDeletesOldDirectoryPost() async {
		let dir = mockedDirectory()

		owsClient._upload = { _ in
			"mock-id"
		}

		let expectation = self.expectation(description: "delete is called on the Directory Post")
		expectation.expectedFulfillmentCount = 1

		owsClient._delete = { id in
			if id == DIR_POST_ID {
				expectation.fulfill()
			} else {
				XCTFail("Unexpected delete call on post \(id)")
			}
		}

		let _ = try! await state.update(directory: dir, to: OWS_CASE)

		await waitForExpectations(timeout: 1)
	}

	func testUpdateInodeTableUploadsInodeTableData() async {
		// So we can expect 1 upload only
		owsClient.sizeLimit = .max

		var uploadedData: Data!
		owsClient._upload = { data in
			uploadedData = data
			return "mock-id"
		}

		owsClient._delete = { _ in
		}

		let _ = try! await state.update(inodeTable: inodeTable, to: OWS_CASE)

		// Here uploadedData will be set

		let decodedData = try! FFSDecoder.decode([uploadedData], password: password)

		XCTAssertEqual(decodedData, inodeTable.raw)
	}

	func testUpdateInodeTableDeletesOldInodeTablePost() async {
		owsClient._upload = { _ in
			"mock-id"
		}

		let expectation = self.expectation(description: "delete is called on the Inode Table Post")
		expectation.expectedFulfillmentCount = 1

		owsClient._delete = { id in
			if id == INODE_TABLE_POST_ID {
				expectation.fulfill()
			} else {
				XCTFail("Unexpected delete call on post \(id)")
			}
		}

		let _ = try! await state.update(inodeTable: inodeTable, to: OWS_CASE)

		await waitForExpectations(timeout: 1)
	}
}
