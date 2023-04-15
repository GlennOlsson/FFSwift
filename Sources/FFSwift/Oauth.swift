//
//  Oauth.swift
//  
//
//  Created by Glenn Olsson on 2023-04-15.
//

import Foundation
import CryptoKit

// To test - subclass and override methods
public class OAuth {
	let consumerKey: String
	let consumerSecret: String
	let accessToken: String
	let accessSecret: String

	let signatureMethod = "HMAC-SHA1"
	let oauthVersion = "1.0"

	init(consumerKey: String, consumerSecret: String, accessToken: String, accessSecret: String) {
		self.consumerKey = consumerKey
		self.consumerSecret = consumerSecret
		self.accessToken = accessToken
		self.accessSecret = accessSecret
	}

	struct GeneratedParameters {
		let nonce: String
		let timestamp: String
		let signature: String
	}

	private func getNonce() -> String {
		return UUID().uuidString
	}

	private func getTimestamp() -> String {
		return "\(Int(Date().timeIntervalSince1970))"
	}

	func generateParamters(url: URL, httpMethod: String, params: [String: String] = [:]) -> GeneratedParameters {
		let parameterString = url.query ?? ""
		let encodedParameterString = parameterString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: url.query ?? "", with: encodedParameterString)

		let timestamp = self.getTimestamp()
		let encodedTimestamp = timestamp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let nonce = self.getNonce()
		let encodedNonce = nonce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let encodedMethod = httpMethod.uppercased()

		let encodedConsumerKey = self.consumerKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedAccessToken = self.accessToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let encodedSignatureMethod = self.signatureMethod.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedVersion = self.oauthVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		var allParamters = [
			"oauth_consumer_key": encodedConsumerKey,
			"oauth_nonce": encodedNonce,
			"oauth_signature_method": encodedSignatureMethod,
			"oauth_timestamp": encodedTimestamp,
			"oauth_token": encodedAccessToken,
			"oauth_version": encodedVersion,
		]
		params.forEach { key, val in
			allParamters[key] = val
		}

		let sortedParams = allParamters.sorted(by: { $0.0 < $1.0 })

		var baseString = ""
		for (key, value) in sortedParams {
			baseString.append(contentsOf: "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)!)&")
		}
		baseString = String(baseString.dropLast())

		var expectedbaseString = "oauth_consumer_key=\(encodedConsumerKey)&oauth_nonce=\(encodedNonce)&oauth_signature_method=\(encodedSignatureMethod)&oauth_timestamp=\(encodedTimestamp)&oauth_token=\(encodedAccessToken)&oauth_version=\(encodedVersion)"


		for (key, val) in params {
			let addedParam = "\(key)=\(val.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)!)"
			print(addedParam)
			expectedbaseString = "\(expectedbaseString)&\(addedParam)"
		}

		print(baseString)
		print(expectedbaseString)

		print("BASE STRING EQ", baseString == expectedbaseString)

		baseString = baseString.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)!
		baseString = "\(encodedMethod)&\(encodedUrl)&\(baseString)"

		print(encodedUrl)

		let encodedBaseString = baseString

		// Generate the signing key
		let encodedConsumerSecret = self.consumerSecret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedAccessTokenSecret = self.accessSecret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let signingKey = "\(encodedConsumerSecret)&\(encodedAccessTokenSecret)"
		print("SIG KEY \(signingKey)")

		print("BASE STR \(encodedBaseString)")


		print("EQ BASE \(encodedBaseString == expectedBase)")

		// Generate the signature

		let signature = HMAC<Insecure.SHA1>.authenticationCode(for: encodedBaseString.data(using: .utf8)!, using: .init(data: signingKey.data(using: .utf8)!))

		let encodedSignature = Data(signature).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		print(encodedSignature)
		print(encodedNonce)
		print(encodedTimestamp)

		return .init(nonce: encodedNonce, timestamp: encodedTimestamp, signature: encodedSignature)
	}
}
