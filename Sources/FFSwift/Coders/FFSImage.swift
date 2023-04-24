import CryptoKit
import Foundation
import os

let logger = Logger(subsystem: "se.glennolsson.ffswift", category: "ffs-image")

public class FFSImage {
	// 128 bits
	private static let SALT_LENGTH = 16
	private static let KEY_LENGTH = 16

	private static let TAG_SIZE = 16 // https://developer.apple.com/documentation/cryptokit/aes/gcm/sealedbox/tag

	private static let IV_LENGTH = 12 // https://developer.apple.com/documentation/cryptokit/aes/gcm/sealedbox/combined

	// 64 bit integer
	private static let CIPHER_LENGTH_SIZE = UInt64.bitWidth / 8

	// Combine encrypted data, key salt and encryption iv
	private static func combine(data: Data, tag: Data, salt: Data, iv: AES.GCM.Nonce) -> Data {
		var combined = Data(iv)
		combined.append(tag)
		combined.append(salt)
		combined.append(UInt64(data.count).data)
		combined.append(data)

		logger.notice("Appended \(salt.hexEncodedString(), privacy: .public) salt, \(data.count) of data to \(combined.count) bytes of data")

		return combined
	}

	// Get salt, iv, and the remaining data of the combined data
	private static func unwrap(data: Data) -> (salt: Data, cipher: Data) {
		var startIndex = 0

		let getData = { (length: Int) -> Data in
			let data = data[startIndex ..< startIndex + length]
			startIndex += length
			return data
		}

		logger.notice("Total data size: \(data.count)")

		let salt = getData(SALT_LENGTH)

		logger.notice("SALT: \(salt.hexEncodedString(), privacy: .public), startIndex: \(startIndex)")

		let cipherLengthData = getData(CIPHER_LENGTH_SIZE)
		logger.notice("Cipher length data: \(cipherLengthData.hexEncodedString(), privacy: .public), ")
		let cipherLength = UInt64(data: cipherLengthData)

		logger.notice("Got \(salt.count) bytes of salt, \(cipherLength) size of data")

		// create integer from data
		let cipher = getData(Int(cipherLength))

		return (salt: salt, cipher: cipher)
	}

	// Create image data for FFS image, including FFS header, encrypting data and adding salts
	public static func createFFSImageData(data: Data, password: String) throws -> Data {
		logger.notice("Creating FFS image data")
		// Create header
		let header = FFSHeader(dataCount: data.count)

		// Create salt
		let salt = generateSalt(size: SALT_LENGTH)
		guard salt.count == SALT_LENGTH else {
			throw FFSEncodeError.saltGenerationError
		}

		// Create key
		let key = deriveKey(password: password, salt: salt, length: KEY_LENGTH)
		guard key.bitCount == KEY_LENGTH * 8 else {
			throw FFSEncodeError.keyGenerationError
		}

		guard let iv = generateIV(size: IV_LENGTH) else {
			throw FFSEncodeError.ivGenerationError
		}

		var unencryptedData = Data()
		unencryptedData.append(contentsOf: header.raw())
		unencryptedData.append(contentsOf: data)

		// Encrypt data
		let result = encrypt(data: unencryptedData, iv: iv, key: key)
		guard let encryptedData = result else {
			throw FFSEncodeError.encryptionError
		}

		var imageData = Data()
		imageData.append(salt)

		// Append size of encrypted data
		let size = UInt64(encryptedData.count)
		imageData.append(size.data)

		imageData.append(encryptedData)

		// Log key as hex string
		// let keyData = key.withUnsafeBytes { Data($0) }
		// logger.notice("Encrypted using: \nKey: \(keyData.hexEncodedString(), privacy: .public), \ntag: \(result.tag.hexEncodedString(), privacy: .public), \nsalt: \(salt.hexEncodedString(), privacy: .public), \niv: \(iv.withUnsafeBytes({ Data($0) }) .hexEncodedString(), privacy: .public), \ncipher: \(imageData.hexEncodedString(), privacy: .public)")

		return imageData
	}

	// Decode FFS image data
	public static func decodeFFSImageData(imageData: Data, password: String) throws -> Data {
		let (salt, cipher) = unwrap(data: imageData)

		let key = deriveKey(password: password, salt: salt, length: KEY_LENGTH)

		// let keyData = key.withUnsafeBytes { Data($0) }
		// logger.notice("Decrypting using: \nKey: \(keyData.hexEncodedString(), privacy: .public), \ntag: \(tag.hexEncodedString(), privacy: .public), \nsalt: \(salt.hexEncodedString(), privacy: .public), \niv: \(iv.withUnsafeBytes({ Data($0) }) .hexEncodedString(), privacy: .public), \ncipher: \(cipher.hexEncodedString(), privacy: .public)")

		// logger.notice("Cipher length \(cipher.count), integer length \(CIPHER_LENGTH_SIZE), range \(0 ..< CIPHER_LENGTH_SIZE, privacy: .public))")

		// let cipherLengthData = Data(cipher)[0 ..< CIPHER_LENGTH_SIZE]
		// logger.notice("Cipher length data: \(cipherLengthData.hexEncodedString(), privacy: .public)")
		// let cipherLength = UInt64(data: cipherLengthData)
		// logger.notice("Cipher length: \(cipherLength)")
		// let cipherData = Data(Data(cipher)[CIPHER_LENGTH_SIZE ..< (Int(cipherLength) + CIPHER_LENGTH_SIZE)])

		// logger.notice("CIPHER CLEAN \(cipherData.hexEncodedString(), privacy: .public)")

		guard var decryptedData = decrypt(combinedData: cipher, key: key) else{
			logger.notice("Could not decrypt data")
			throw FFSDecodeError.decryptionError
		}

		var asBytes = [UInt8](decryptedData)

		let header = FFSHeader(raw: &asBytes)

		logger.notice("Decrypted, \(String(decoding: decryptedData, as: UTF8.self), privacy: .public)")

		return Data(asBytes)
	}
}
