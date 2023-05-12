@testable import FFSwift
import PNG
import XCTest

public class DecoderTests: XCTestCase {
	func testPixelsToBytesReturnsCorrectData() {

		var pixel: PNG.RGBA<UInt16> = .init(0)
		pixel.r = 0x0001
		pixel.g = 0x0203
		pixel.b = 0x0405
		pixel.a = 0x0607

		let data = pixelsToBytes([pixel])

		let expectedData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])

		XCTAssertEqual(data, expectedData)
	}

	func testExtractRelevantImageDataThrowsForHighDataCount() {
		// Set as 6 bytes, only 5 bytes available
		let data = UInt64(6).data + Data([0x00, 0x00, 0x00, 0x00, 0x00])

		XCTAssertThrowsError(try FFSDecoder.extractRelevantImageData(from: data)) { error in
			XCTAssertEqual(error as? FFSDecodeError, FFSDecodeError.notEnoughData)
		}
	}

	func testExtractRelevantImageDataThrowsForTooLittleData() {
		// Pass only 7 bytes, at least 8 bytes expected
		let data = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

		XCTAssertThrowsError(try FFSDecoder.extractRelevantImageData(from: data)) { error in
			XCTAssertEqual(error as? FFSDecodeError, FFSDecodeError.notEnoughData)
		}
	}

	func testExtractRelevantImageDataReturnsCorrectCorrectData() {
		let expectedData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05])

		let data = UInt64(6).data + expectedData

		let extractedData = try! FFSDecoder.extractRelevantImageData(from: data)

		XCTAssertEqual(extractedData, expectedData)
	}

	func testReturnsNoDataFor0Count() {
		let data = UInt64(0).data

		let extractedData = try! FFSDecoder.extractRelevantImageData(from: data)

		XCTAssertEqual(extractedData.count, 0)
	}
}
