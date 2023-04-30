@testable import FFSwift
import Foundation
import XCTest

class HeaderTests: XCTestCase {
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

	func testDecodingFFSHeaderWithWrongMagic() {
		let header = FFSHeader(version: 1, dataCount: 3)

		var data = header.raw
		data[0] = "A".data(using: .utf8)![0]

		XCTAssertThrowsError(try FFSHeader(raw: data)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badMagic)
		}
	}

	func testDecodingFFSHeaderWithTooLitleData() {
		let header = FFSHeader(version: 1, dataCount: 3)

		var data = header.raw
		data.removeLast()

		XCTAssertThrowsError(try FFSHeader(raw: data)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badDataCount)
		}
	}

	func testDecodingFFSHeaderWithBadMagic() {
		let header = FFSHeader(version: 1, dataCount: 3)

		var data = header.raw
		data[0] = 0xFF

		XCTAssertThrowsError(try FFSHeader(raw: data)) { error in
			XCTAssertEqual(error as! FFSBinaryStructureError, FFSBinaryStructureError.badMagic)
		}
	}
}
