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
		let dataString  = "f11adf55157218315acbd083f4dbc0a6ac72e78956dfb2ad704734df049fdb98000000000000003110b9b02b328b1389576ff2905bb8166ed00c0eb5f1480b7b05bc09fbd690cab6250e80e9ec9cbf6c3ab41101c6a49ab1ea"
		let imageData = Data(hexString: dataString)!

		let password = "password"

		let (decodedData, header) = try! FFSImage.decodeFFSImageData(imageData: imageData, password: password)

		let relevantData = decodedData[header.dataRange]

		let expectedData = "Hello, World!".data(using: .utf8)!

		XCTAssertEqual(relevantData, expectedData)
	}

	func testDecodeWithWrongPassword() {
		let dataString  = "f11adf55157218315acbd083f4dbc0a6ac72e78956dfb2ad704734df049fdb98000000000000003110b9b02b328b1389576ff2905bb8166ed00c0eb5f1480b7b05bc09fbd690cab6250e80e9ec9cbf6c3ab41101c6a49ab1ea"
		let imageData = Data(hexString: dataString)!

		let password = "wrongPassword"

		XCTAssertThrowsError(try FFSImage.decodeFFSImageData(imageData: imageData, password: password)) { error in
			XCTAssertEqual(error as! FFSDecodeError, FFSDecodeError.decryptionError)
		}
	}

	func testDecodeWithBadData() {
		let data = "NOT ENCRYPTED DATA".data(using: .utf8)!
		let password = "password"

		XCTAssertThrowsError(try FFSImage.decodeFFSImageData(imageData: data, password: password)) { error in
			XCTAssertEqual(error as! FFSDecodeError, FFSDecodeError.invalidData)
		}
	}

}