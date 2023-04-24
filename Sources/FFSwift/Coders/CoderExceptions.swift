import Foundation

public enum FFSDecodeError: Error {
	case notFFSData
	case decryptionError
	case notEnoughData
}

public enum FFSEncodeError: Error {
	case encryptionError
	case saltGenerationError
	case ivGenerationError
	case keyGenerationError
}