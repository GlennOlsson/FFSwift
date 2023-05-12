@testable import FFSwift
import Foundation
import XCTest

class StorageStateTester: XCTestCase {
	let password = "password"

	var state: StorageState!
	var inodeTable: InodeTable!

	override func setUp() {
		inodeTable = mockedInodeTable()
		state = StorageState(inodeTable: inodeTable, password: password)
	}

	func addOWS(client: MockedOWSClient) {
		state.addOWS(client: client, for: OWS_CASE)
	}

	func testGetFileReturnsCorrectData() async {
		let data = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		let client = MockedOWSClient(
			get: { _ in
				try! FFSEncoder.encode(data, password: self.password, limit: .max).first!
			}
		)

		addOWS(client: client)

		let fileData = try! await state.getFile(with: FILE_INODE)

		XCTAssertEqual(fileData, data)
	}

	func testGetFileThrowsForBadInode() async {
		let client = MockedOWSClient()

		addOWS(client: client)

		let badInode: Inode = .max
		do {
			_ = try await state.getFile(with: badInode)
			XCTFail("Did not throw for bad inode")
		} catch {
			XCTAssertEqual(error as! FilesystemException, FilesystemException.noFileWithInode(badInode))
		}
	}

	func testGetFileThrowsForDirectory() async {
		let client = MockedOWSClient()

		addOWS(client: client)

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
		let client = MockedOWSClient(get: { _ in
			try! FFSEncoder.encode(directory.raw, password: self.password, limit: .max).first!
		})

		addOWS(client: client)

		let returnedDirectory = try! await state.getDirectory(with: DIR_INODE)

		XCTAssertEqual(directory, returnedDirectory)
	}

	func testGetDirectoryThrowsForFile() async {
		let client = MockedOWSClient()

		addOWS(client: client)

		let inode = FILE_INODE
		do {
			_ = try await state.getDirectory(with: inode)
			XCTFail("Did not throw for file inode")
		} catch {
			XCTAssertEqual(error as! FilesystemException, FilesystemException.isFile)
		}
	}

	func testDirectoryFileThrowsForBadInode() async throws {
		let client = MockedOWSClient()

		addOWS(client: client)

		let badInode: Inode = .max
		do {
			_ = try await state.getDirectory(with: badInode)
			XCTFail("Did not throw for bad inode")
		} catch {
			XCTAssertEqual(error as! FilesystemException, FilesystemException.noFileWithInode(badInode))
		}
	}

	func testGetOWSClientThrowsForNotAddedOWS() {
		XCTAssertThrowsError(try state.getOWSClient(for: .flickr)) { error in
			XCTAssertEqual(error as! OWSError, OWSError.unsupportedOWS)
		}
	}
}
