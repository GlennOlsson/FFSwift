@testable import FFSwift
import XCTest

public class EncoderTests: XCTestCase {
	func testBytesToPixelsReturnsCorrectPixels() {
		// 8 bytes
		let data = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])

		let pixels = try! bytesToPixels(data)

		XCTAssertEqual(pixels.count, 1)
		XCTAssertEqual(pixels[0].r, 0x0001)
		XCTAssertEqual(pixels[0].g, 0x0203)
		XCTAssertEqual(pixels[0].b, 0x0405)
		XCTAssertEqual(pixels[0].a, 0x0607)
	}
	
	func testBytesToPixelsThrowsForBadDataCount() throws {
		let asserter = { count in 
			let data = Data(repeating: 0x00, count: count)
			XCTAssertThrowsError(try bytesToPixels(data), "Should throw for count \(count)", { error in
				XCTAssertEqual(error as? FFSEncodeError, FFSEncodeError.badDataCount)
			})
		}

		try [
			1,
			7,
			9,
			15
		].forEach(asserter)
	}

	func testEncodeSplitsDataForLimit() {
		let data = Data(repeating: 0x00, count: 6)

		let encodedData = try! FFSEncoder.encode(data, password: "password", limit: 5)

		// Not sure exactly how many images will be generated due to size of encrypted FFS data, but
		// should be at least 2 when the limit is smaller than the data count
		XCTAssertGreaterThanOrEqual(encodedData.count, 2)
	}
}
