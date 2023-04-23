import Foundation

public enum FFSDecodeError: Error {
	case notFFSData
	case decryptionError
}

public enum FFSEncodeError: Error {
	case encryptionError
	case saltGenerationError
	case ivGenerationError
	case keyGenerationError
}