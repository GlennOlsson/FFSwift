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
		let dataString  = "6735ed6618a36318e4f5ba0dd3967dc400000000000000324e039e7ef137cf0bdd1ac374ad1d7e5a2650c6cffd806809bc1046e711da13007fb54bf9674ad1e4ca900de591bcc42c853a"
		let imageData = Data(hexString: dataString)!

		let password = "password"

		let decodedData = try! FFSImage.decodeFFSImageData(imageData: imageData, password: password)

		let expectedData = "Hello, World!".data(using: .utf8)!

		XCTAssertEqual(decodedData, expectedData)
	}

	func testDecodeWithWrongPassword() {
		let dataString  = "6735ed6618a36318e4f5ba0dd3967dc400000000000000324e039e7ef137cf0bdd1ac374ad1d7e5a2650c6cffd806809bc1046e711da13007fb54bf9674ad1e4ca900de591bcc42c853a"
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

	// func 
}