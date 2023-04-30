@testable import FFSwift
import XCTest

public class CoderTests: XCTestCase {
	func encodeAndAssert(input: String, password: String) {
		let encodedData = try! FFSEncoder.encode(input.data(using: .utf8)!, password: password)

		let decodedData = try! FFSDecoder.decode(encodedData, password: password)

		XCTAssertEqual(String(data: decodedData, encoding: .utf8), input)
	}

	func testEncodeHelloWorld() {
		// Test that encoding and decoding works with some examples
		let examples = [
			"Hello, World!",
			"123",
			"1234",
			"abc",
			"ABC",
			"!@#",
			"Hallå alla vackra människor!",
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
			"Hallå alla vackra människor!",
		]
		examples.forEach { example in
			encodeAndAssert(input: example, password: "password")
			encodeAndAssert(input: example, password: "password2")
			encodeAndAssert(input: example, password: "password3")
		}
	}

	// Assert decode throws with wrong password
	func testDecodeWrongPassword() {
		let encodedData = try! FFSEncoder.encode("Hello, World!".data(using: .utf8)!, password: "password")

		// Assert FFSDecoder.decode throws FFSDecodeException
		XCTAssertThrowsError(try FFSDecoder.decode(encodedData, password: "wrongPassword")) { error in
			XCTAssertEqual(error as! FFSDecodeError, FFSDecodeError.decryptionError)
		}
	}

	// Assert coders work for images
	func testEncodeImage() {
		let url = URL(fileURLWithPath: "Tests/resources/test.png")
		guard let data = try? Data(contentsOf: url) else {
			XCTFail("Could not load image")
			return
		}

		let password = "password"

		let encodedData = try! FFSEncoder.encode(data, password: password)

		let decodedData = try! FFSDecoder.decode(encodedData, password: password)

		XCTAssertEqual(data, decodedData)
	}

	func testBadFFSDataThrow() {
		let url = URL(fileURLWithPath: "Tests/resources/test.png")
		guard let data = try? Data(contentsOf: url) else {
			XCTFail("Could not load image")
			return
		}

		XCTAssertThrowsError(try FFSDecoder.decode(data, password: "wrongPassword")) { error in
			XCTAssertEqual(error as! FFSDecodeError, FFSDecodeError.decryptionError)
		}
	}
}