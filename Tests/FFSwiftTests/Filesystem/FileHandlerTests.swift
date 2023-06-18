@testable import FFSwift
import XCTest
import Foundation

class FileHandlerTester: XCTestCase {
	var fileHandler: FileHandler!

	override func setUp() {
		let inodeTable = mockedInodeTable()
		let owsClient = MockedOWSClient()
		let state = mockedFilesystemState(inodeTable: inodeTable, owsClient: owsClient)

		self.fileHandler = FileHandler(state: state)
	}

	func testCloseWithNoOpenFilesThrows() async {
		do {
			try await self.fileHandler.close(0)
			XCTFail("Should have thrown")
		} catch {
			XCTAssertEqual(error as! FilesystemError, FilesystemError.fileNotOpen)
		}
	}

	func testCloseUnopenedFileThrows() async throws {
		let directory = mockedDirectory()
		let _ = fileHandler.open(inode: FILE_INODE, in: directory)
		do {
			try await self.fileHandler.close(.max)
			XCTFail("Should have thrown")
		} catch {
			XCTAssertEqual(error as! FilesystemError, FilesystemError.fileNotOpen)
		}
	}

	func testUpdateDataOnUnopenedFileThrows() throws {
		XCTAssertThrowsError(try self.fileHandler.updateData(for: .max, data: Data())) { error in
			XCTAssertEqual(error as! FilesystemError, FilesystemError.fileNotOpen)
		}
	}

	func testCanCloseOpenFile() async {
		let directory = mockedDirectory()
		let fd = fileHandler.open(inode: FILE_INODE, in: directory)
		try! await self.fileHandler.close(fd)
	}

	func testGetNextFDReturnsSameWithoutOpen() {
		let fd = fileHandler.getNextFD()
		XCTAssertEqual(fd, 0)
		let fd2 = fileHandler.getNextFD()
		XCTAssertEqual(fd2, 0)
	}

	func testGetNextFDReturnsHigherWhenOpened() {
		let directory = mockedDirectory()
		let fd = fileHandler.open(inode: FILE_INODE, in: directory)
		XCTAssertEqual(fd, 0)
		let fd2 = fileHandler.getNextFD()
		XCTAssertEqual(fd2, 1)
	}

	func testUpdateDataUpdatesData() {
		let directory = mockedDirectory()

		let fd = fileHandler.open(inode: FILE_INODE, in: directory)

		let data = Data([0x01, 0x02, 0x03])

		try! fileHandler.updateData(for: fd, data: data)

		XCTAssertEqual(fileHandler.openFiles[fd]?.data, data)
	}
}