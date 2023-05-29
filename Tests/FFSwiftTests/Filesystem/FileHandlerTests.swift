@testable import FFSwift
import XCTest
import Foundation

class FileHandlerTester: XCTestCase {
	var fsState: FileHandler!

	override func setUp() {
		let inodeTable = mockedInodeTable()
		let owsClient = MockedOWSClient()
		let state = mockedFilesystemState(inodeTable: inodeTable, owsClient: owsClient)

		self.fsState = FileHandler(state: state)
	}

	func testCloseWithNoOpenFilesThrows() async {
		do {
			try await self.fsState.close(0)
			XCTFail("Should have thrown")
		} catch {
			XCTAssertEqual(error as! FilesystemError, FilesystemError.fileNotOpen)
		}
	}

	func testCloseUnopenedFileThrows() async throws {
		let directory = mockedDirectory()
		let _ = fsState.open(inode: FILE_INODE, in: directory)
		do {
			try await self.fsState.close(.max)
			XCTFail("Should have thrown")
		} catch {
			XCTAssertEqual(error as! FilesystemError, FilesystemError.fileNotOpen)
		}
	}

	func testUpdateDataOnUnopenedFileThrows() throws {
		XCTAssertThrowsError(try self.fsState.updateData(for: .max, data: Data())) { error in
			XCTAssertEqual(error as! FilesystemError, FilesystemError.fileNotOpen)
		}
	}

	func testCanCloseOpenFile() async {
		let directory = mockedDirectory()
		let fd = fsState.open(inode: FILE_INODE, in: directory)
		try! await self.fsState.close(fd)
	}

	func testGetNextFDReturnsSameWithoutOpen() {
		let fd = fsState.getNextFD()
		XCTAssertEqual(fd, 0)
		let fd2 = fsState.getNextFD()
		XCTAssertEqual(fd2, 0)
	}

	func testGetNextFDReturnsHigherWhenOpened() {
		let directory = mockedDirectory()
		let fd = fsState.open(inode: FILE_INODE, in: directory)
		XCTAssertEqual(fd, 0)
		let fd2 = fsState.getNextFD()
		XCTAssertEqual(fd2, 1)
	}
}