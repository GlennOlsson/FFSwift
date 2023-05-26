@testable import FFSwift
import Foundation
import XCTest

class StorageStateTester: XCTestCase {
	let password = "password"

	var state: StorageState!
	var inodeTable: InodeTable!
	var owsClient: MockedOWSClient!

	let EXPECTATION_TIMEOUT: TimeInterval = 10

	override func setUp() {
		inodeTable = mockedInodeTable()
		state = StorageState(
			password: password
		)
		state.inodeTable = inodeTable
		state.inodeTablePosts = [
			INODE_TABLE_POST,
		]

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
			XCTAssertEqual(error as! FilesystemError, FilesystemError.noFileWithInode(badInode))
		}
	}

	func testGetFileThrowsForDirectory() async {
		let inode = DIR_INODE
		do {
			_ = try await state.getFile(with: inode)
			XCTFail("Did not throw for dir inode")
		} catch {
			XCTAssertEqual(error as! FilesystemError, FilesystemError.isDirectory(inode))
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
			XCTAssertEqual(error as! FilesystemError, FilesystemError.isFile)
		}
	}

	func testDirectoryFileThrowsForBadInode() async throws {
		let badInode: Inode = .max
		do {
			_ = try await state.getDirectory(with: badInode)
			XCTFail("Did not throw for bad inode")
		} catch {
			XCTAssertEqual(error as! FilesystemError, FilesystemError.noFileWithInode(badInode))
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

		let inode = try! await state.create(
			fileData: Data(),
			in: mockedDirectory(),
			named: "new-file.txt",
			using: OWS_CASE
		)

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

		let _ = try! await state.create(
			fileData: Data(),
			in: mockedDirectory(),
			named: "new-file.txt",
			using: OWS_CASE
		)

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
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

		let _ = try! await state.create(
			fileData: fileData,
			in: mockedDirectory(),
			named: "new-file.txt",
			using: OWS_CASE
		)

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
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
		let _ = try! await state.create(
			fileData: Data(),
			in: directory,
			named: filename,
			using: OWS_CASE
		)

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
	}

	func testCreateFileUploadsNewInodeTable() async {
		// Test that upload is at some point called with the current inode table,
		// which then is expected to have been updated with a new entry
		let expectation = self.expectation(description: "Upload called on new directory")
		expectation.expectedFulfillmentCount = 1

		owsClient._upload = { data in
			let decodedData = try! FFSDecoder.decode([data], password: self.password)
			// Must get the raw version of the inode table because it will be updated with the new entry
			// while the create(fileData:) function is executing
			if decodedData == self.inodeTable.raw {
				expectation.fulfill()
			}
			return "mock-id"
		}

		let _ = try! await state.create(
			fileData: Data(),
			in: mockedDirectory(),
			named: "new-file.txt",
			using: OWS_CASE
		)

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
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

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
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

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
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

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
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

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
	}

	func testUpdateDirectoryReplacesPosts() async {
		let directory = mockedDirectory()

		let expectedPostID = "new-post-id"

		let expectation = self.expectation(description: "Directory is uploaded")
		expectation.expectedFulfillmentCount = 1

		owsClient._upload = { _ in
			// Should only be called once, otherwise expectation will fail
			expectation.fulfill()

			return expectedPostID
		}

		let _ = try! await state.update(directory: directory, to: OWS_CASE)

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)

		let entry = try! inodeTable.get(with: DIR_INODE)

		XCTAssertEqual(entry.posts.count, 1)
		XCTAssertEqual(entry.posts.first!.id, expectedPostID)
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

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
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

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
	}

	func testUpdateFileOnlyUploadsInodeTableAndFile() async {
		let fileData = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		let expectation = self.expectation(description: "Inode table and file are uploaded")
		expectation.expectedFulfillmentCount = 2

		owsClient._upload = { uploadedData in
			let decodedData = try! FFSDecoder.decode([uploadedData], password: self.password)

			// Current inode table, i.e. the one with updated entry
			if decodedData == self.inodeTable.raw {
				expectation.fulfill()
			} else if decodedData == fileData {
				expectation.fulfill()
			} else {
				XCTFail("Unexpected data uploaded")
			}

			return "mock-id"
		}

		let _ = try! await state.update(with: FILE_INODE, using: OWS_CASE, data: fileData)

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
	}

	func testCreateFileOnlyUploadsInodeTableAndDirAndFile() async {
		let fileData = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		let filename = "new-file.txt"

		let expectedInode = inodeTable.getNextInode()
		let expectedDirectory = mockedDirectory()
		try! expectedDirectory.add(filename: filename, with: expectedInode)
		let expectedDirectoryData = expectedDirectory.raw

		let expectation = self.expectation(description: "Inode table, directory and file are uploaded")
		expectation.expectedFulfillmentCount = 3

		owsClient._upload = { uploadedData in
			let decodedData = try! FFSDecoder.decode([uploadedData], password: self.password)

			// Current inode table, i.e. the one with updated entry
			if decodedData == self.inodeTable.raw {
				expectation.fulfill()
			} else if decodedData == fileData {
				expectation.fulfill()
			} else if decodedData == expectedDirectoryData {
				expectation.fulfill()
			} else {
				XCTFail("Unexpected data uploaded")
			}

			return "mock-id"
		}

		// Fresh directory
		let directory = mockedDirectory()
		let _ = try! await state.create(
			fileData: fileData,
			in: directory,
			named: filename,
			using: OWS_CASE
		)

		await waitForExpectations(timeout: EXPECTATION_TIMEOUT)
	}

	func testCreateFileAddsNewInodeEntry() async {
		let fileData = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		let filename = "new-file.txt"
		let expectedInode = inodeTable.getNextInode()

		let directory = mockedDirectory()

		let filePostID = "new-file-post-id"
		let otherPostID = "other-post-id"

		owsClient._upload = { data in
			let decodedData = try! FFSDecoder.decode([data], password: self.password)

			if decodedData == fileData {
				return filePostID
			} else {
				return otherPostID
			}
		}

		let entriesBefore = inodeTable.entries.count

		let timeBefore = Date()

		let _ = try! await state.create(
			fileData: fileData,
			in: directory,
			named: filename,
			using: OWS_CASE
		)

		let timeAfter = Date()

		let entriesAfter = inodeTable.entries.count

		XCTAssertEqual(entriesAfter, entriesBefore + 1)

		let newEntry = try? inodeTable.get(with: expectedInode)
		XCTAssertNotNil(newEntry)

		XCTAssertEqual(newEntry!.posts.count, 1)
		XCTAssertEqual(newEntry!.posts.first!.id, filePostID)

		let metadata = newEntry!.metadata

		// Assert size is correct
		XCTAssertEqual(metadata.size, UInt64(fileData.count))

		// Assert is not marked as directory
		XCTAssertFalse(metadata.isDirectory)

		// Assert times are within the expected range
		let timeUpdated = metadata.timeUpdated
		let timeCreated = metadata.timeCreated

		let range = UInt64(timeBefore.timeIntervalSince1970) ... UInt64(timeAfter.timeIntervalSince1970)

		XCTAssertTrue(range ~= timeUpdated)
		XCTAssertTrue(range ~= timeCreated)
	}

	func testCreateFileWaitsForAllUploadsToFinish() async {
		// Use counter instead of expectation, as we want to assert the upload count right after
		// the function has returned, proving the uploads were awaited
		var uploadCalls = 0
		let expectedUploadCalls = 3

		let timeBefore = Date()
		// Milliseconds
		let sleepTime: UInt64 = 300

		// Slow upload functions, but all of them will finish eventually
		// Expectation is only fulfilled when all uploads are done and the function has returned
		owsClient._upload = { _ in
			try! await Task.sleep(nanoseconds: sleepTime * 1_000_000)
			uploadCalls += 1
			return "mock-id"
		}

		// Fresh directory
		let directory = mockedDirectory()
		let _ = try! await state.create(
			fileData: Data(),
			in: directory,
			named: "new-file.txt",
			using: OWS_CASE
		)

		let timeAfter = Date()

		XCTAssertEqual(uploadCalls, expectedUploadCalls, "Expected \(expectedUploadCalls) upload calls, got \(uploadCalls)")

		// Assert time after is at least sleepTime seconds * 2 after timeBefore (3 calls but two
		// of them can be at the same time)

		let earliestTime = timeBefore.addingTimeInterval(TimeInterval((sleepTime * 2) / 1000))

		XCTAssertGreaterThanOrEqual(timeAfter, earliestTime)
	}

	func testCreateDirectoryAddsNewInodeEntry() async {
		let expectedInode = inodeTable.getNextInode()
		
		let newDirectory = try! Directory(inode: expectedInode)
		let newDirectoryData = newDirectory.raw

		let filename = "new-dirname"

		let parentDirectory = mockedDirectory()

		let filePostID = "new-dir-post-id"
		let otherPostID = "other-post-id"

		owsClient._upload = { data in
			let decodedData = try! FFSDecoder.decode([data], password: self.password)

			if decodedData == newDirectoryData {
				return filePostID
			} else {
				return otherPostID
			}
		}

		let entriesBefore = inodeTable.entries.count

		let timeBefore = Date()

		let _ = try! await state.create(
			directory: newDirectory,
			in: parentDirectory,
			named: filename,
			using: OWS_CASE
		)

		let timeAfter = Date()

		let entriesAfter = inodeTable.entries.count

		XCTAssertEqual(entriesAfter, entriesBefore + 1)

		let newEntry = try? inodeTable.get(with: expectedInode)
		XCTAssertNotNil(newEntry)

		XCTAssertEqual(newEntry!.posts.count, 1)
		XCTAssertEqual(newEntry!.posts.first!.id, filePostID)

		let metadata = newEntry!.metadata

		// Assert size is correct
		XCTAssertEqual(metadata.size, UInt64(newDirectoryData.count))

		// Assert is marked as directory
		XCTAssertTrue(metadata.isDirectory)

		// Assert times are within the expected range
		let timeUpdated = metadata.timeUpdated
		let timeCreated = metadata.timeCreated

		let range = UInt64(timeBefore.timeIntervalSince1970) ... UInt64(timeAfter.timeIntervalSince1970)

		XCTAssertTrue(range ~= timeUpdated)
		XCTAssertTrue(range ~= timeCreated)
	}
}
