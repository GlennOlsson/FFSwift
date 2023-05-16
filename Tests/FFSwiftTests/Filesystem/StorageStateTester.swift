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
		state = StorageState(inodeTable: inodeTable, password: password)
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
}
