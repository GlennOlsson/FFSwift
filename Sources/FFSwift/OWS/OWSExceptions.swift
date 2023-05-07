
enum OWSError: Error, Equatable {
	case unknownOWS
	case unsupportedOWS
	case notAuthenticated
	case noPostWithID(String)
	case couldNotGet
	case couldNotUpload
	case couldNotGetRecent
}