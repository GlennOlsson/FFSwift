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

	func testCreateImageDataReturnsSameDataForSquareableData() {
		// If data count + size of data (with 8 bytes) require a square number of pixels, 
		// then the image will be square, i.e. no extra bytes are needed

		// 2 bytes per component, 4 components per pixel == 8 bytes per pixel
		// 4x4 image == 16 pixels == 128 bytes. Although, 8 bytes are needed for the data size
		// so only pass 120 bytes

		let data = Data(1...120)
		
		let (imageData, w, h) = FFSEncoder.createImageData(from: data)

		XCTAssertEqual(imageData.count, 128)
		XCTAssertEqual(w, 4)
		XCTAssertEqual(h, 4)

		// Check that the data is the same
		XCTAssertEqual(imageData[8...], data)

		// Check that the data size is correct
		XCTAssertEqual(UInt64(120).data, imageData[0..<8])
	}

	func testCreateImageDataReturnsExtraDataForNonSquareableData() {
		// Similar to above, but for 121 bytes so one extra row is needed

		let data = Data(1...121)
		
		let (imageData, w, h) = FFSEncoder.createImageData(from: data)

		// 121 + 8 bytes for data size + (4 * 8 - 1) bytes for extra row - 1 byte
		XCTAssertEqual(imageData.count, 160)
		XCTAssertEqual(w, 4)
		XCTAssertEqual(h, 5)

		// Check that the data is the same
		XCTAssertEqual(imageData[8..<129], data)

		// Check that the data size is correct
		XCTAssertEqual(UInt64(121).data, imageData[0..<8])
	}
}
