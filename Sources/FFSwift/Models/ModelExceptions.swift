

public enum FFSBinaryStructureError: Error {
	case badDataCount
	case badMagic
	case badVersion
	case badStructure
	case badOWS
}