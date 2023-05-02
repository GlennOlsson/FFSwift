@testable import FFSwift
import Foundation
import XCTest

class InodeTableEntryTests: XCTestCase, BinaryStructureTester {
	static func mockedStructure() -> InodeTableEntry {
		// Mocked inode table entry
		return InodeTableEntry(
			size: 12345,
			isDirectory: false,
			timeCreated: UInt64(Date().timeIntervalSince1970),
			timeUpdated: UInt64(Date().timeIntervalSince1970),
			timeAccessed: UInt64(Date().timeIntervalSince1970),
			posts: [
				PostTests.mockedStructure(),
				PostTests.mockedStructure()
			]
		)
	}

	func testEncodeDecodeWithEmptyPosts() {
		let structure = InodeTableEntry(
			size: 12345,
			isDirectory: false,
			timeCreated: UInt64(Date().timeIntervalSince1970),
			timeUpdated: UInt64(Date().timeIntervalSince1970),
			timeAccessed: UInt64(Date().timeIntervalSince1970),
			posts: []
		)

		let raw = structure.raw

		let decodedStructure = try! InodeTableEntry(raw: raw)

		XCTAssertEqual(structure, decodedStructure)
	}

	func testEncodeDecodeDirectory() {
		let structure = InodeTableEntry(
			size: 12345,
			isDirectory: true,
			timeCreated: UInt64(Date().timeIntervalSince1970),
			timeUpdated: UInt64(Date().timeIntervalSince1970),
			timeAccessed: UInt64(Date().timeIntervalSince1970),
			posts: [
				PostTests.mockedStructure(),
				PostTests.mockedStructure()
			]
		)

		let raw = structure.raw

		let decodedStructure = try! InodeTableEntry(raw: raw)

		XCTAssertEqual(structure, decodedStructure)
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
}
