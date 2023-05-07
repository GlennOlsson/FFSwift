import Foundation

class Storage {
	var owsMapping: [OnlineWebService: OWSClient?] = [:]

	func addOWS(client: OWSClient, for ows: OnlineWebService) {
		owsMapping[ows] = client
	}

	func getOWS(for ows: OnlineWebService) throws -> OWSClient {
		// check if key is in map. If key is in check if value of key is nil
		guard let valueInMap = owsMapping[ows] else {
			throw OWSError.unsupportedOWS
		}

		guard let client = valueInMap else {
			throw OWSError.notAuthenticated
		}

		return client
	}
}
