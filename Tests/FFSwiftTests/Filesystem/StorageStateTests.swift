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

		let _ = try! await state.createFile(in: mockedDirectory(), with: "new-file.txt", using: OWS_CASE, data: Data())

		await waitForExpectations(timeout: 1, handler: nil)
	}

	func testCreateFileCallsUploadOnNewFile() async {
		let expectation = self.expectation(description: "Upload called on new file")

		let fileData = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		expectation.expectedFulfillmentCount = 1

		owsClient._upload = { data in
			let decodedData = try! FFSDecoder.decode([data], password: self.password)
			// Multiple data will be uploaded (dir, inode table), so cannot only assert equality
			if decodedData == fileData {
				expectation.fulfill()
			}
			return "mock-id"
		}

		let _ = try! await state.createFile(in: mockedDirectory(), with: "new-file.txt", using: OWS_CASE, data: fileData)

		await waitForExpectations(timeout: 1, handler: nil)
	}

	func testCreateFileUploadsNewDirectory() async {
		let filename = "new-file.txt"
		let expectedInode = inodeTable.getNextInode()

		let modifiedDirectory = mockedDirectory()
		try! modifiedDirectory.add(filename: filename, with: expectedInode)
		let dirData = modifiedDirectory.raw

		let expectation = self.expectation(description: "Upload called on new directory")
		expectation.expectedFulfillmentCount = 1

		owsClient._upload = { data in
			let decodedData = try! FFSDecoder.decode([data], password: self.password)
			// Multiple data will be uploaded (file, inode table), so cannot only assert equality
			if decodedData == dirData {
				expectation.fulfill()
			}
			return "mock-id"
		}

		// Fresh copy of the directory without the new file
		let directory = mockedDirectory()
		let _ = try! await state.createFile(in: directory, with: filename, using: OWS_CASE, data: Data())

		await waitForExpectations(timeout: 5)
	}

	func testCreateFileUploadsNewInodeTable() async {
		// Test that upload is at some point called with the current inode table,
		// which then is expected to have been updated with a new entry
		let expectation = self.expectation(description: "Upload called on new directory")
		expectation.expectedFulfillmentCount = 1

		owsClient._upload = { data in
			let decodedData = try! FFSDecoder.decode([data], password: self.password)
			// Must get the raw version of the inode table because it will be updated with the new entry
			// while the createFile function is executing
			if decodedData == self.inodeTable.raw {
				expectation.fulfill()
			}
			return "mock-id"
		}

		let _ = try! await state.createFile(in: mockedDirectory(), with: "new-file.txt", using: OWS_CASE, data: Data())

		await waitForExpectations(timeout: 5)
	}

	func testUpdateInodeTableCallsDeleteOnInodeTablePost() async {
		let expectation = self.expectation(description: "delete is called on the Inode Table Post")

		expectation.expectedFulfillmentCount = 1

		owsClient._delete = { id in
			if id == INODE_TABLE_POST_ID {
				expectation.fulfill()
			}
		}

		let _ = try! await state.update(inodeTable: inodeTable, to: OWS_CASE)

		await waitForExpectations(timeout: 5)
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

		let expectation = self.expectation(description: "Upload called with correct data")
		expectation.expectedFulfillmentCount = 1

		owsClient._upload = { uploadedData in
			let decodedData: Data = try! FFSDecoder.decode([uploadedData], password: self.password)

			XCTAssertEqual(decodedData, data)

			expectation.fulfill()

			return "mock-id"
		}

		let _ = try! await state.upload(data: data, to: OWS_CASE)

		await waitForExpectations(timeout: 5)
	}

	func testUpdateDirectoryUploadsDirectoryData() async {
		let dir = mockedDirectory()

		// So we can expect 1 upload only
		owsClient.sizeLimit = .max

		let expectation = self.expectation(description: "Directory data is uploaded")
		expectation.expectedFulfillmentCount = 1

		owsClient._upload = { uploadedData in
			let decodedData = try! FFSDecoder.decode([uploadedData], password: self.password)

			XCTAssertEqual(decodedData, dir.raw)

			expectation.fulfill()
			return "mock-id"
		}

		let _ = try! await state.update(directory: dir, to: OWS_CASE)

		await waitForExpectations(timeout: 5)
	}

	func testUpdateDirectoryDeletesOldDirectoryPost() async {
		let dir = mockedDirectory()

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

		await waitForExpectations(timeout: 5)
	}

	func testUpdateInodeTableUploadsInodeTableData() async {
		// So we can expect 1 upload only
		owsClient.sizeLimit = .max

		let expectation = self.expectation(description: "Inode table data is uploaded")

		let expectedInodeTableData = inodeTable.raw

		owsClient._upload = { uploadedData in
			let decodedData = try! FFSDecoder.decode([uploadedData], password: self.password)
			XCTAssertEqual(decodedData, expectedInodeTableData)
			expectation.fulfill()
			return "mock-id"
		}

		let _ = try! await state.update(inodeTable: inodeTable, to: OWS_CASE)

		await waitForExpectations(timeout: 5)
	}

	func testUpdateInodeTableDeletesOldInodeTablePost() async {
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

		await waitForExpectations(timeout: 5)
	}
}
