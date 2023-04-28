@testable import FFSwift
import XCTest

class FFSImageTests: XCTestCase {
	func testCreateFFSImageData() {
		let data = "Hello, World!".data(using: .utf8)!
		let password = "password"

		let imageData = try! FFSImage.createFFSImageData(data: data, password: password)

		XCTAssertNotNil(imageData)
	}

	func testDecodeFFSImageData() {
		let dataString  = "3bfcb9e97f804b7681c3e84652115e057cd9af92b77c4c16df527dbca72e16110000000000000032fa694fb509de21cd7568271170662891645e708772e72c6cb2446d28c02bc39a067ee50966e3324190ad0ce8abae4780f293"
		let imageData = Data(hexString: dataString)!

		let password = "password"

		let (decodedData, header) = try! FFSImage.decodeFFSImageData(imageData: imageData, password: password)

		let relevantData = decodedData[header.dataRange]

		let expectedData = "Hello, World!".data(using: .utf8)!

		XCTAssertEqual(relevantData, expectedData)
	}

	func testDecodeWithWrongPassword() {
		let dataString  = "3bfcb9e97f804b7681c3e84652115e057cd9af92b77c4c16df527dbca72e16110000000000000032fa694fb509de21cd7568271170662891645e708772e72c6cb2446d28c02bc39a067ee50966e3324190ad0ce8abae4780f293"
		let imageData = Data(hexString: dataString)!

		let password = "wrongPassword"

		XCTAssertThrowsError(try FFSImage.decodeFFSImageData(imageData: imageData, password: password)) { error in
			XCTAssertEqual(error as! FFSDecodeError, FFSDecodeError.decryptionError)
		}
	}

	func testDecodeWithBadData() {
		let data = "NOT ENCRYTPED DATA".data(using: .utf8)!
		let password = "password"

		XCTAssertThrowsError(try FFSImage.decodeFFSImageData(imageData: data, password: password)) { error in
			XCTAssertEqual(error as! FFSDecodeError, FFSDecodeError.invalidData)
		}
	}

}