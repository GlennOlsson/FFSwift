import CryptoKit
import FFSwift
import Foundation
import os
import XCTest

let logger = Logger(subsystem: "se.glennolsson.ffswift", category: "ffs-image")
public class CryptTests: XCTestCase {
	func testEncryptingHelloWord() {
		let input = "Hello, World!".data(using: .utf8)!
		let password = "password"

		let imageData = try! FFSImage.createFFSImageData(data: input, password: password)

		let unencryptedData = try! FFSImage.decodeFFSImageData(imageData: imageData, password: password)

		XCTAssertEqual(unencryptedData, input)
	}

	func testSimpleEncrypt() {
		let input = "Hello, World!".data(using: .utf8)!
		let password = "password"

		// Generate parameters
		let salt = generateSalt(size: 32)
		let key = deriveKey(password: password, salt: salt, length: 16)
		let iv = generateIV(size: 12)!

		// Encrypt
		let encryptedData = encrypt(data: input, iv: iv, key: key)

		// Decrypt
		let decryptedData = decrypt(combinedData: encryptedData!, key: key)

		XCTAssertEqual(decryptedData, input)
	}
}
