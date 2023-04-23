import CryptoKit
import Foundation

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

		return combined
	}

	// Get salt, iv, and the remaining data of the combined data
	private static func unwrap(data: Data) -> (tag: Data, iv: Data, salt: Data, cipher: Data) {
		var startIndex = 0

		let getData = { (length: Int) -> Data in
			let data = data[startIndex ..< startIndex + length]
			startIndex += length
			return data
		}

		let tag = getData(TAG_SIZE)
		let iv = getData(IV_LENGTH)
		let salt = getData(SALT_LENGTH)
		let cipherLength = UInt64(data: getData(CIPHER_LENGTH_SIZE))
		// create integer from data
		let cipher = getData(Int(cipherLength))

		return (tag: tag, iv: iv, salt: salt, cipher: cipher)
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
		guard let encryptedData = result.data else {
			throw FFSEncodeError.encryptionError
		}

		var imageData = Data()
		// Append size of encrypted data
		let size = UInt64(encryptedData.count)
		imageData.append(size.data)
		imageData.append(encryptedData)

		let combinedData = combine(data: imageData, tag: result.tag, salt: salt, iv: iv)

		return combinedData
	}

	// Decode FFS image data
	public static func decodeFFSImageData(imageData: Data, password: String) throws -> Data {
		let (tag, iv, salt, cipher) = unwrap(data: imageData)

		let key = deriveKey(password: password, salt: salt, length: KEY_LENGTH)

		guard let sealedBox = try? AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: iv), ciphertext: cipher, tag: tag) else {
			throw FFSDecodeError.decryptionError
		}

		guard let decryptedData = try? AES.GCM.open(sealedBox, using: key) else {
			throw FFSDecodeError.decryptionError
		}

		return decryptedData
	}
}
