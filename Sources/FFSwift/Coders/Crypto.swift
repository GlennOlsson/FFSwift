import CryptoKit
import Foundation

// Function that derives a HKDF key from a password string
public func deriveKey(password: String, salt: Data, length: Int) -> SymmetricKey {
	let passwordData = Data(password.utf8)

	let key = HKDF<SHA512>.deriveKey(inputKeyMaterial: .init(data: passwordData), salt: salt, outputByteCount: length)

	return key
}

public func generateSalt(size: Int) -> Data {
	var salt = Data(count: size)
	let result = salt.withUnsafeMutableBytes {
		SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!)
	}
	assert(result == errSecSuccess, "Failed to generate random salt")
	return salt
}

public func generateIV() -> AES.GCM.Nonce? {
	var randomData = Data(count: 12)
	let result = randomData.withUnsafeMutableBytes {
		SecRandomCopyBytes(kSecRandomDefault, 12, $0.baseAddress!)
	}
	assert(result == errSecSuccess, "Failed to generate randomData for IV")
	return try? AES.GCM.Nonce(data: randomData)
}

// Encrypt data using IV and key. Tag and iv are included in the resulting data
public func encrypt(data: Data, iv: AES.GCM.Nonce, key: SymmetricKey) -> Data? {
	let sealedBox = try? AES.GCM.seal(data, using: key, nonce: iv)
	let encryptedData = sealedBox?.combined
	return encryptedData
}

public func decrypt(combinedData: Data, key: SymmetricKey) -> Data? {
	let sealedBox = try? AES.GCM.SealedBox(combined: combinedData)
	var data: Data?
	if sealedBox != nil {
		data = try? AES.GCM.open(sealedBox!, using: key)
	}
	return data
}
