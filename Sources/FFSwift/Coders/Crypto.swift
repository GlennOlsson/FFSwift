import CryptoKit
import Foundation

// Function that derives a HKDF key from a password string
func deriveKey(password: String, salt: Data, length: Int) -> SymmetricKey {
	let passwordData = Data(password.utf8)

	let key = HKDF<SHA512>.deriveKey(inputKeyMaterial: .init(data: passwordData), salt: salt, outputByteCount: length)

	return key
}

func generateSalt(size: Int) -> Data {
	var salt = Data(count: size)
	let result = salt.withUnsafeMutableBytes {
		SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!)
	}
	assert(result == errSecSuccess, "Failed to generate random salt")
	return salt
}

func generateIV(size: Int) -> AES.GCM.Nonce? {
	var randomData = Data(count: size)
	let result = randomData.withUnsafeMutableBytes {
		SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!)
	}
	assert(result == errSecSuccess, "Failed to generate randomData for IV")
	return try? AES.GCM.Nonce(data: randomData)
}

func encrypt(data: Data, iv: AES.GCM.Nonce, key: SymmetricKey) -> (data: Data?, tag: Data) {
	let sealedBox = try! AES.GCM.seal(data, using: key, nonce: iv)
	let encryptedData = sealedBox.combined
	return (data: encryptedData, sealedBox.tag)
}