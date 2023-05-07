@testable import FFSwift
import Foundation
import XCTest

class PostTests: XCTestCase, BinaryStructureTester {
	static func mockedStructure() -> Post {
		return Post(ows: .flickr, id: "some-decodable-id", version: 1)
	}

	func testThrowsWhenBadOWS() {
		let structure = Self.mockedStructure()

		var raw = structure.raw

		let owsIndex = raw.startIndex + Post.magic.count + 1
		raw[owsIndex] = .max // Non-existing OWS
		raw[owsIndex + 1] = .max

		XCTAssertThrowsError(try Post(raw: raw)) { error in
			XCTAssertEqual(error as! OWSError, OWSError.unknownOWS)
		}
	}

	func testEncodeDecode() {
		let structure = Self.mockedStructure()

		let raw = structure.raw

		let decodedStructure = try! T(raw: raw)

		XCTAssertEqual(structure, decodedStructure)
	}	

	func testEncodeDecodeWithEmptyID() {
		let structure = Post(ows: .flickr, id: "")

		let raw = structure.raw

		let decodedStructure = try! T(raw: raw)

		XCTAssertEqual("", decodedStructure.id)
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
