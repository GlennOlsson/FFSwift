import FFSwift
import XCTest

public class CryptTests: XCTestCase {

	func testEncryptingHelloWord() {
		let input = "Hello, World!".data(using: .utf8)!
		let password = "password"

		let imageData = try! FFSImage.createFFSImageData(data: input, password: password)
		
		let unencryptedData = try! FFSImage.decodeFFSImageData(imageData: imageData, password: password)

		XCTAssertEqual(unencryptedData, input)
	}
}