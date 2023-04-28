@testable import FFSwift
import XCTest

class FFSImageTests: XCTestCase {
	func testCreateFFSImageData() {
		let data = "Hello, World!".data(using: .utf8)!
		let password = "password"

		let imageData = try! FFSImage.createFFSImageData(data: data, password: password)

		print(imageData.hexadecimal)

		XCTAssertNotNil(imageData)
	}

	func testDecodeFFSImageData() {
		let dataString  = "7c40b75ee2d4d5cfa67f2d674b624d36ea251bef19012325367f82d4984278d0000000000000003247c401a521bd7065654464660fceddae8256fbde1ddd85d5a25852e3c9b1c75ac993b8fa7c3b9b69409825203ab9be553053"
		let imageData = Data(hexString: dataString)!

		let password = "password"

		let (decodedData, _) = try! FFSImage.decodeFFSImageData(imageData: imageData, password: password)

		let expectedData = "Hello, World!".data(using: .utf8)!

		XCTAssertEqual(decodedData, expectedData)
	}

	func testDecodeWithWrongPassword() {
		let dataString  = "7c40b75ee2d4d5cfa67f2d674b624d36ea251bef19012325367f82d4984278d0000000000000003247c401a521bd7065654464660fceddae8256fbde1ddd85d5a25852e3c9b1c75ac993b8fa7c3b9b69409825203ab9be553053"
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