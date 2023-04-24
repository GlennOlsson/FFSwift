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

	func testTest() {
		let keyStr = "d5a423f64b607ea7c65b311d855dc48f36114b227bd0c7a3d403f6158a9e4412"
		let key = SymmetricKey(data: Data(hexString: keyStr)!)
		

		let ciphertext = Data(base64Encoded: "LzpSalRKfL47H5rUhqvA")
		let nonce = Data(hexString: "131348c0987c7eece60fc0bc") // = initialization vector
		let tag = Data(hexString: "5baa85ff3e7eda3204744ec74b71d523")

		let plainData = "This is a plain text".data(using: .utf8)
		let sealedData = try! AES.GCM.seal(plainData!, using: key, nonce: AES.GCM.Nonce(data:nonce!))
		let encryptedContent = try! sealedData.combined!

		logger.notice("Nonce: \(sealedData.nonce.withUnsafeBytes { Data(Array($0)).hexadecimal }, privacy: .public)")
		logger.notice("Tag: \(sealedData.tag.hexadecimal, privacy: .public)")
		logger.notice("Data: \(sealedData.ciphertext.base64EncodedString(), privacy: .public)")

		logger.notice("Encrypted content: \(encryptedContent.hexadecimal, privacy: .public)")


		let sealedBox = try! AES.GCM.SealedBox(combined: encryptedContent)

		let decryptedData = try! AES.GCM.open(sealedBox, using: key)
		logger.notice("last \(String(decoding: decryptedData, as: UTF8.self), privacy: .public)")
	}
}
