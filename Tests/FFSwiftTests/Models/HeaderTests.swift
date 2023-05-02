@testable import FFSwift
import Foundation
import XCTest

class HeaderTests: XCTestCase, BinaryStructureTester {
	static func mockedStructure() -> FFSHeader {
		return FFSHeader(version: 1, dataCount: 3)
	}

	func testEncodingHeader() throws {
		let version = UInt8(0)
		let dataCount = UInt32(3)

		let header = FFSHeader(version: version, dataCount: dataCount)

		let raw = header.raw

		XCTAssertEqual(raw.count, 8)

		let decodedHeader = try FFSHeader(raw: raw)

		XCTAssertNotNil(decodedHeader)
		XCTAssertEqual(decodedHeader.version, version)
		XCTAssertEqual(decodedHeader.dataCount, dataCount)
	}

	// MARK: - BinaryStructureTester
	func testDecodingFFSHeaderWithWrongMagic() {
		let header = Self.mockedStructure()

		var data = header.raw
		data[0] = "A".data(using: .utf8)![0]

		XCTAssertThrowsError(try FFSHeader(raw: data)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badMagic)
		}
	}

	func testDecodingFFSHeaderWithTooLittleData() {
		let header = Self.mockedStructure()

		var data = header.raw
		data.removeLast()

		XCTAssertThrowsError(try FFSHeader(raw: data)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badDataCount)
		}
	}

	func testDecodingFFSHeaderWithBadMagic() {
		let header = Self.mockedStructure()

		var data = header.raw
		data[0] = 0xFF

		XCTAssertThrowsError(try FFSHeader(raw: data)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badMagic)
		}
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
