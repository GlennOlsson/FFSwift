
enum OnlineWebService: UInt16 {
	case flickr = 0

	static func from(_ rawValue: UInt16) throws -> OnlineWebService {
		guard let ows = OnlineWebService(rawValue: rawValue) else {
			throw OWSError.unknownOWS
		}
		return ows
	}
}