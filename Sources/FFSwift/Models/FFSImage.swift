import CryptoKit
import Foundation

public enum FFSImage {

	// 256 bits
	private static let KEY_LENGTH = 32
	private static let SALT_LENGTH = 32

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
	private static func unwrap(data: Data) throws -> (salt: Data, cipher: Data) {
		var startIndex = 0

		let getData = { (length: Int) -> Data in
			guard startIndex + length <= data.count else {
				throw FFSDecodeError.invalidData
			}
			let data = data[startIndex ..< startIndex + length]
			startIndex += length
			return data
		}

		let salt = try getData(SALT_LENGTH)

		let cipherLength = UInt64(data: try getData(CIPHER_LENGTH_SIZE))

		let cipher = try getData(Int(cipherLength))

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

		guard let iv = generateIV() else {
			throw FFSEncodeError.ivGenerationError
		}

		var unencryptedData = Data()
		unencryptedData.append(contentsOf: header.raw)
		unencryptedData.append(contentsOf: data)

		// Encrypt data
		guard let encryptedData = encrypt(data: unencryptedData, iv: iv, key: key) else {
			throw FFSEncodeError.encryptionError
		}

		let imageData = combine(data: encryptedData, salt: salt)

		return imageData
	}

	// Decode FFS image data
	public static func decodeFFSImageData(imageData: Data, password: String) throws -> (Data, FFSHeader) {
		let (salt, cipher) = try unwrap(data: imageData)

		let key = deriveKey(password: password, salt: salt, length: KEY_LENGTH)

		guard let decryptedData = decrypt(combinedData: cipher, key: key) else {
			throw FFSDecodeError.decryptionError
		}

		guard let header = try? FFSHeader(raw: decryptedData) else {
			throw FFSDecodeError.notFFSData
		}

		guard decryptedData.count >= header.dataCount else {
			throw FFSDecodeError.notEnoughData
		}

		return (decryptedData, header)
	}
}
