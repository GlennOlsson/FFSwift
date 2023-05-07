@testable import FFSwift
import Foundation
import XCTest

class InodeTableTests: XCTestCase, BinaryStructureTester {
	static func mockedStructure() -> InodeTable {
		return InodeTable(entries: [
				0: InodeTableEntryTests.mockedStructure(),
				1: InodeTableEntryTests.mockedStructure(),
			]
		)
	}

	func testEncodeDecodeWithEmptyEntries() {
		let structure = InodeTable(entries: [:])

		let raw = structure.raw

		let decodedStructure = try! InodeTable(raw: raw)

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
