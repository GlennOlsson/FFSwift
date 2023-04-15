//
//  File.swift
//  
//
//  Created by Glenn Olsson on 2023-04-13.
//

import Foundation
import Alamofire

import CryptoKit

class OAuthParamters {
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

	func generateParamters(url: URL, httpMethod: String) -> GeneratedParameters {
		let parameterString = url.query ?? ""
		let encodedParameterString = parameterString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: url.query ?? "", with: encodedParameterString)

		let timestamp = "\(Int(Date().timeIntervalSince1970))"
//		let timestamp = "\(1681543834)"
		let encodedTimestamp = timestamp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let nonce = UUID().uuidString
//		let nonce = "nonce" //"ipN5SW6A40hWrD31MrMV38sgKSwZ/TzjGd1+861o2Vg="
		let encodedNonce = nonce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let encodedMethod = httpMethod.uppercased()

		let encodedConsumerKey = self.consumerKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedAccessToken = self.accessToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		let encodedSignatureMethod = self.signatureMethod.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedVersion = self.oauthVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

		var baseString = "oauth_consumer_key=\(encodedConsumerKey)&oauth_nonce=\(encodedNonce)&oauth_signature_method=\(encodedSignatureMethod)&oauth_timestamp=\(encodedTimestamp)&oauth_token=\(encodedAccessToken)&oauth_version=\(encodedVersion)&title=hejhopp"
		baseString = baseString.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)!
		baseString = "\(httpMethod)&\(encodedUrl)&\(baseString)"

		print(encodedUrl)

		let encodedBaseString = baseString

		// Generate the signing key
		let encodedConsumerSecret = self.consumerSecret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let encodedAccessTokenSecret = self.accessSecret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let signingKey = "\(encodedConsumerSecret)&\(encodedAccessTokenSecret)"
		print("SIG KEY \(signingKey)")

		print("BASE STR \(encodedBaseString)")


		//POST&http%3A%2F%2F127.0.0.1%3A8080&oauth_consumer_key%3D04b22819363cb16310bd583b6d176852%26oauth_nonce%3Dnonce%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1681543834%26oauth_token%3D72157720851762173-94f64f0374b4c646%26oauth_version%3D1.0%26title%3Dhejhopp
		//POST&http%3A%2F%2F127.0.0.1%3A8080&oauth_consumer_key%3D04b22819363cb16310bd583b6d176852%26oauth_nonce%3Dnonce%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1681543834%26oauth_token%3D72157720851762173-94f64f0374b4c646%26oauth_version%3D1.0%26title%3Dhej%2520hopp

		let expectedBase = ""

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


public func upload() throws {
	print("Uploading")

	let oauthGenerator = OAuthParamters(
		consumerKey:
		consumerSecret:
		accessToken:
		accessSecret:
	)

	let url = URL(string: "https://api.flickr.com/services/upload")!
//	let url = URL(string: "http://127.0.0.1:8080")!

	let paramters = oauthGenerator.generateParamters(url: url, httpMethod: "POST")

	let formParams: [String: String] = [
		"oauth_nonce": paramters.nonce,
		"oauth_timestamp": paramters.timestamp,
		"oauth_consumer_key": oauthGenerator.consumerKey,
		"oauth_signature_method": oauthGenerator.signatureMethod,
		"oauth_version": oauthGenerator.oauthVersion,
		"oauth_token": oauthGenerator.accessToken,
		"oauth_signature": paramters.signature,
	]

	let expectedSig = "loh3fdkYTfQhTEKrQV4byQOm3NA="

	print("sig \(paramters.signature), eq? \(expectedSig == paramters.signature)")
//	var urlWithQuery = URLComponents(url: url, resolvingAgainstBaseURL: false)
//	urlWithQuery?.queryItems = formParams.map { kv in
//		URLQueryItem(name: kv.key, value: kv.value)
//	}

//	print("URL", urlWithQuery!.url!.absoluteString)

	let uploader = AF.upload(multipartFormData: { formData in
		formData.append(URL(fileURLWithPath: "/tmp/hej.png"), withName: "photo")

		formData.append("skitungen".data(using: .utf8)!, withName: "title")

		for (key, str) in formParams {
			formData.append(str.data(using: .utf8)!, withName: key)
		}

//		formData.append(oauthGenerator.accessToken.data(using: .utf8)!, withName: "oauth_token")
//		formData.append(oauthGenerator.consumerKey.data(using: .utf8)!, withName: "oauth_consumer_key")

	}, to: url.absoluteString).response { response in
		switch response.result {
		case .success(let data):
			print("SUCCESS", String(data: data!, encoding: .utf8)!)
		case .failure(let err):
			print("FAILURE", err)
		}
	}

	Thread.sleep(forTimeInterval: 20)
}

