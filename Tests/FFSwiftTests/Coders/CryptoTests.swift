import CryptoKit
import FFSwift
import Foundation
import XCTest
public class CryptTests: XCTestCase {
	func testSimpleEncrypt() {
		let input = "Hello, World!".data(using: .utf8)!
		let password = "password"

		// Generate parameters
		let salt = generateSalt(size: 32)
		let key = deriveKey(password: password, salt: salt, length: 16)
		let iv = generateIV()!

		// Encrypt
		let encryptedData = encrypt(data: input, iv: iv, key: key)
		XCTAssertNotNil(encryptedData)

		// Decrypt
		let decryptedData = decrypt(combinedData: encryptedData!, key: key)
		XCTAssertNotNil(decryptedData)

		XCTAssertEqual(decryptedData, input)
	}

	func testReturnsNilForBadDecrypt() {
		let input = "NOT ENCRYPTED".data(using: .utf8)!

		let password = "password"
		let key = deriveKey(password: password, salt: Data(), length: 16)

		let decryptedData = decrypt(combinedData: input, key: key)
		XCTAssertNil(decryptedData)
	}

	func testReturnsNilForTamperedData() {
		let input = "Hello, World!".data(using: .utf8)!
		let password = "password"

		// Generate parameters
		let salt = generateSalt(size: 32)
		let key = deriveKey(password: password, salt: salt, length: 16)
		let iv = generateIV()!

		// Encrypt
		let encryptedData = encrypt(data: input, iv: iv, key: key)

		var tamperedData = encryptedData!.dropLast()
		var decryptedData = decrypt(combinedData: tamperedData, key: key)
		XCTAssertNil(decryptedData)

		tamperedData = encryptedData! + Data([0x00])
		decryptedData = decrypt(combinedData: tamperedData, key: key)
		XCTAssertNil(decryptedData)
	}

	func testDecryptRaw() {
		let keyData = Data(hexString: "84709f382df3b45c3780cb89ce3a9fea")!
		let key = SymmetricKey(data: keyData)

		let encryptedData = Data(hexString: "d014021edbdf2cc157c8416680a01ecc44c9191ad38568a3ecdca10d45d7c384448bf12da6f7b6e868")!

		let decodedData = decrypt(combinedData: encryptedData, key: key)

		let expectedData = "Hello, World!".data(using: .utf8)!

		XCTAssertEqual(decodedData, expectedData)
	}

	func testDecryptReturnsNilForBadKey() {
		let keyData = "BAD PASSWORD".data(using: .utf8)!
		let key = SymmetricKey(data: keyData)

		let encryptedData = Data(hexString: "d014021edbdf2cc157c8416680a01ecc44c9191ad38568a3ecdca10d45d7c384448bf12da6f7b6e868")!

		let decodedData = decrypt(combinedData: encryptedData, key: key)

		XCTAssertNil(decodedData)
	}

	func testEncryptReturnsNilForEmptyKey() {
		let iv = generateIV()!
		let data = "Hello, World!".data(using: .utf8)!
		let key = SymmetricKey(data: Data())

		let encryptedData = encrypt(data: data, iv: iv, key: key)
		XCTAssertNil(encryptedData)
	}

	func testCanEncryptEmptyData() {
		let iv = generateIV()!

		let data = Data()
		let salt = generateSalt(size: 32)
		let password = "password"
		
		let key = deriveKey(password: password, salt: salt, length: 16)

		let encryptedData = encrypt(data: data, iv: iv, key: key)
		XCTAssertNotNil(encryptedData)
	}
}
