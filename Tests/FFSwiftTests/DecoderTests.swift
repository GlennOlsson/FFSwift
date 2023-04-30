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
}
