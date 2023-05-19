
enum OnlineWebService: UInt16 {
	case local = 0
	case flickr = 1

	static func from(_ rawValue: UInt16) throws -> OnlineWebService {
		guard let ows = OnlineWebService(rawValue: rawValue) else {
			throw OWSError.unknownOWS
		}
		return ows
	}
}