//
//  File.swift
//  
//
//  Created by Glenn Olsson on 2023-04-13.
//

import Foundation
import Alamofire



public func upload() throws {
	print("Uploading")

	let oauthGenerator = OAuth(
		consumerKey: 
		consumerSecret: 
		accessToken: 
		accessSecret: 
	)

	let extraParams = [
		"title": "skitunge",
		"description": "Ska väl du skita i"
	]

	let url = URL(string: "https://api.flickr.com/services/upload")!
//	let url = URL(string: "http://127.0.0.1:8080")!

	let paramters = oauthGenerator.generateParamters(url: url, httpMethod: "POST", params: extraParams)

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

//
//		formData.append("hej hopp".data(using: .utf8)!, withName: "title")

		for (key, str) in formParams {
			formData.append(str.data(using: .utf8)!, withName: key)
		}

		for (key, str) in extraParams {
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

