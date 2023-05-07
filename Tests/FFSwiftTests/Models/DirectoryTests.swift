@testable import FFSwift
import Foundation
import XCTest

class DirectoryTests: XCTestCase, BinaryStructureTester {
	static func mockedStructure() -> Directory {
		return try! Directory(entries: [
			"file1": 0,
			"file2": 1,
		]
		)
	}

	func testEncodeDecode() {
		let structure = Self.mockedStructure()

		let raw = structure.raw

		let decodedStructure = try! T(raw: raw)

		XCTAssertEqual(structure, decodedStructure)
	}

	func testCountIsCorrect() {
		let structure = Self.mockedStructure()

		XCTAssertEqual(structure.count, structure.raw.count)
	}

	func testMinCountIsLessThanCount() {
		let structure = Self.mockedStructure()

		XCTAssertLessThanOrEqual(T.minCount, structure.count)
	}

	func testThrowsForBadMagic() {
		let structure = Self.mockedStructure()

		var raw = structure.raw

		raw[0] = 0

		XCTAssertThrowsError(try T(raw: raw)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badMagic)
		}
	}

	func testThrowsForWrongMagic() {
		let structure = Self.mockedStructure()

		var raw = structure.raw

		raw[0] = "$".utf8.first! // "$" is hopefully not the first character of any magic string :)

		XCTAssertThrowsError(try T(raw: raw)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badMagic)
		}
	}

	func testThrowsForBadDataCount() {
		let structure = Self.mockedStructure()

		let raw = structure.raw

		let dataToDrop = raw.count - T.minCount + 1

		let modifiedData: Data = raw.dropLast(dataToDrop)

		XCTAssertThrowsError(try T(raw: modifiedData)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badDataCount)
		}
	}

	func testAddThrowsForTooLongName() {
		let directory = try! Directory()

		let name = String(repeating: "a", count: 1000)

		XCTAssertThrowsError(try directory.add(filename: name, with: 0)) { error in
			XCTAssertEqual(error as! DirectoryError, DirectoryError.nameTooLong)
		}
	}

	func testInitThrowsForTooLongName() {
		let name = String(repeating: "a", count: 1000)

		XCTAssertThrowsError(try Directory(entries: [
			name: 0,
		])) { error in
			XCTAssertEqual(error as! DirectoryError, DirectoryError.nameTooLong)
		}
	}

	func testThrowsForSameName() {
		let directory = try! Directory()

		let name = "some-filename"

		try! directory.add(filename: name, with: 0)

		XCTAssertThrowsError(try directory.add(filename: name, with: 1)) { error in
			XCTAssertEqual(error as! DirectoryError, DirectoryError.filenameExists)
		}
	}

	func testThrowsForNonExistingFilename() {
		let directory = try! Directory()

		let name = "some-filename"

		// Test with empty dir
		XCTAssertThrowsError(try directory.inode(of: name)) { error in
			XCTAssertEqual(error as! DirectoryError, DirectoryError.noEntryWithName)
		}

		try! directory.add(filename: "some-other-name", with: 0)

		// Test with non-empty dir
		XCTAssertThrowsError(try directory.inode(of: name)) { error in
			XCTAssertEqual(error as! DirectoryError, DirectoryError.noEntryWithName)
		}
	}
}
