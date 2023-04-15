//
//  Oauth.swift
//
//
//  Created by Glenn Olsson on 2023-04-15.
//

import CryptoKit
import Foundation

// To test - subclass and override methods
open class OAuth {
	let consumerKey: String
	let consumerSecret: String
	let accessToken: String
	let accessSecret: String

	let signatureMethod = "HMAC-SHA1"
	let oauthVersion = "1.0"

	public init(consumerKey: String, consumerSecret: String, accessToken: String, accessSecret: String) {
		self.consumerKey = consumerKey
		self.consumerSecret = consumerSecret
		self.accessToken = accessToken
		self.accessSecret = accessSecret
	}

	struct GeneratedParameters {
		let nonce: String
		let timestamp: String
		let signature: String
		let parameters: [String: String]

		public init(nonce: String, timestamp: String, signature: String, parameters: [String: String]) {
			self.nonce = nonce
			self.timestamp = timestamp
			self.signature = signature
			self.parameters = parameters
		}

		public var allParameters : [String: String] {
			var allParameters: [String: String] = parameters
			allParameters["oauth_signature"] = signature
			allParameters["oauth_nonce"] = nonce
			allParameters["oauth_timestamp"] = timestamp
			return allParameters
		}
	}

	func getNonce() -> String {
		return UUID().uuidString
	}

	func getTimestamp() -> String {
		return "\(Int(Date().timeIntervalSince1970))"
	}

	func generateParameters(url: URL, httpMethod: String, params: [String: String] = [:]) -> GeneratedParameters {
		let parameterString: String = url.query ?? ""
		let encodedParameterString: String = parameterString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedUrl: String = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: url.query ?? "", with: encodedParameterString)

		let timestamp: String = getTimestamp()
		let encodedTimestamp: String = timestamp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let nonce: String = getNonce()
		let encodedNonce: String = nonce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let encodedMethod: String = httpMethod.uppercased()

		var allParameters: [String: String] = [
			"oauth_consumer_key": consumerKey,
			"oauth_nonce": nonce,
			"oauth_signature_method": signatureMethod,
			"oauth_timestamp": timestamp,
			"oauth_token": accessToken,
			"oauth_version": oauthVersion,
		]
		params.forEach { key, val in
			allParameters[key] = val
		}

		let sortedParams: [Dictionary<String, String>.Element] = allParameters.sorted(by: { $0.0 < $1.0 })

		var baseString = ""
		for (key, value) in sortedParams {
			baseString.append(contentsOf: "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)!)&")
		}
		baseString = String(baseString.dropLast())

		baseString = baseString.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)!
		baseString = "\(encodedMethod)&\(encodedUrl)&\(baseString)"

		let encodedBaseString = baseString

		// Generate the signing key
		let encodedConsumerSecret = consumerSecret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedAccessTokenSecret = accessSecret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let signingKey = "\(encodedConsumerSecret)&\(encodedAccessTokenSecret)"

		// Generate the signature
		let signature = HMAC<Insecure.SHA1>.authenticationCode(for: encodedBaseString.data(using: .utf8)!, using: .init(data: signingKey.data(using: .utf8)!))

		let encodedSignature = Data(signature).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		return .init(
			nonce: encodedNonce, 
			timestamp: encodedTimestamp, 
			signature: encodedSignature, 
			parameters: allParameters
		)
	}
}
