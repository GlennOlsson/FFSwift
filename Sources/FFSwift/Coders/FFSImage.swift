import CryptoKit
import Foundation
import os

let logger = Logger(subsystem: "se.glennolsson.ffswift", category: "ffs-image")

public enum FFSImage {
	// 128 bits
	private static let SALT_LENGTH = 16
	private static let KEY_LENGTH = 16

	private static let TAG_SIZE = 16 // https://developer.apple.com/documentation/cryptokit/aes/gcm/sealedbox/tag

	private static let IV_LENGTH = 12 // https://developer.apple.com/documentation/cryptokit/aes/gcm/sealedbox/combined

	// 64 bit integer
	private static let CIPHER_LENGTH_SIZE = UInt64.bitWidth / 8

	// Combine encrypted data, key salt and encryption iv
	private static func combine(data: Data, salt: Data) -> Data {
		var combined = Data()

		combined.append(salt)

		let size = UInt64(data.count)
		combined.append(size.data)

		combined.append(data)

		return combined
	}

	// Get salt and the cipher data of the combined data
	private static func unwrap(data: Data) -> (salt: Data, cipher: Data) {
		var startIndex = 0

		let getData = { (length: Int) -> Data in
			let data = data[startIndex ..< startIndex + length]
			startIndex += length
			return data
		}

		let salt = getData(SALT_LENGTH)

		let cipherLength = UInt64(data: getData(CIPHER_LENGTH_SIZE))

		let cipher = getData(Int(cipherLength))

		return (salt: salt, cipher: cipher)
	}

	// Create image data for FFS image, including FFS header, encrypting data and adding salts
	public static func createFFSImageData(data: Data, password: String) throws -> Data {
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

		let imageData = combine(data: encryptedData, salt: salt)

		return imageData
	}

	// Decode FFS image data
	public static func decodeFFSImageData(imageData: Data, password: String) throws -> Data {
		let (salt, cipher) = unwrap(data: imageData)

		let key = deriveKey(password: password, salt: salt, length: KEY_LENGTH)

		guard var decryptedData = decrypt(combinedData: cipher, key: key) else {
			logger.notice("Could not decrypt data")
			throw FFSDecodeError.decryptionError
		}

		guard let header = FFSHeader(raw: &decryptedData) else {
			logger.notice("Could not decode header")
			throw FFSDecodeError.notFFSData
		}

		guard decryptedData.count >= header.dataCount else {
			logger.notice("Decrypted data is smaller than header data count")
			throw FFSDecodeError.notEnoughData
		}

		return decryptedData
	}
}
