import FFSwift
import XCTest

public class CoderTests: XCTestCase {

	func encodeAndAssert(input: String, password: String) {
		let encodedData = FFSEncoder.encode(input.data(using: .utf8)!, password: password)

		let decodedData = FFSDecoder.decode(encodedData, password: password)

		XCTAssertEqual(String(data: decodedData, encoding: .utf8), input)
	}

	func testEncodeHellWorld() {
		// Test that encoding and decoding works with some examples
		let examples = [
			"Hello, World!",
			"123",
			"abc",
			"ABC",
			"!@#",
			"Hallå alla vackra människor!"
		]
		examples.forEach { example in
			encodeAndAssert(input: example, password: "password")
		}
	}

	// Assert coders work with different passwords
	func testDifferentPasswords() {
		let examples = [
			"Hello, World!",
			"123",
			"abc",
			"ABC",
			"!@#",
			"Hallå alla vackra människor!"
		]
		examples.forEach { example in
			encodeAndAssert(input: example, password: "password")
			encodeAndAssert(input: example, password: "password2")
			encodeAndAssert(input: example, password: "password3")
		}
	}

	// Assert decode throws with wrong password
	func testDecodeWrongPassword() {
		let encodedData = FFSEncoder.encode("Hello, World!".data(using: .utf8)!, password: "password")

		XCTAssertThrowsError(try FFSDecoder.decode(encodedData, password: "wrongPassword"))
	}

	// Assert coders work for images
	func testEncodeImage() {
		let data = try! Data(contentsOf: URL(fileURLWithPath: "Tests/resources/test.png"))

		let password = "password"

		let encodedData = FFSEncoder.encode(data, password: password)

		let decodedData = FFSDecoder.decode(encodedData, password: password)

		XCTAssertEqual(data, decodedData)
	}
}