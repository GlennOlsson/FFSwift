//
//  File.swift
//
//
//  Created by Glenn Olsson on 2023-04-13.
//

import Alamofire
import Foundation

private let uploadURL = URL(string: "https://api.flickr.com/services/upload")!
private let apiURL = URL(string: "https://api.flickr.com/services/rest")!
	// private let uploadURL = URL(string: "http://127.0.0.1:8080")!

public class FlickrClient: OWS {
	let consumerKey: String
	let consumerSecret: String
	let accessToken: String
	let accessSecret: String

	public init(consumerKey: String, consumerSecret: String, accessToken: String, accessSecret: String) {
		self.consumerKey = consumerKey
		self.consumerSecret = consumerSecret
		self.accessToken = accessToken
		self.accessSecret = accessSecret
	}

	func getOauthGenerator() -> OAuth {
		return OAuth(
			consumerKey: consumerKey,
			consumerSecret: consumerSecret,
			accessToken: accessToken,
			accessSecret: accessSecret
		)
	}

	public func uploadFile(data: Data) async -> String? {
		print("Uploading file...")

		let response = await withCheckedContinuation { completion in
			self.upload(data: data).response { response in
				switch response.result {
				case let .success(data):
					print("Successfully uploaded!")
					completion.resume(returning: data)
				case let .failure(error):
					print("ERROR WITH UPLOAD: \(error)")
					completion.resume(returning: nil)
				}
			}
		}

		// write raw response to file
		let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
			.appendingPathComponent("uploadResponse.json")
		try? response?.write(to: fileURL)

		if let responseData = response, let photoID = parsePhotoId(from: responseData) {
			return photoID
		} else {
			return nil
		}
	}

	public func deleteFile(id _: String) async {
		// TODO:
	}

	public func getRecentFiles(n _: Int) async -> [String]? {
		// TODO:
		return []
	}

	public func getFile(id _: String) async -> Data? {
		// TODO:
		return Data()
	}

	private func upload(
		data: Data,
		title: String? = nil,
		description: String? = nil,
		tags: [String] = []
	) -> Alamofire.UploadRequest {
		let oauthGenerator = getOauthGenerator()

		var extraParams: [String: String] = [
			"jsoncallback": "1",
			"format": "json",
		]
		if let title = title {
			extraParams["title"] = title
		}
		if let description = description {
			extraParams["description"] = description
		}
		if tags.count > 0 {
			extraParams["tags"] = tags.joined(separator: ",")
		}

		let url = uploadURL

		print("URL: \(url.absoluteString)")

		let paramters = oauthGenerator.generateParamters(
			url: url, httpMethod: "POST", params: extraParams
		)

		var formParams: [String: String] = [
			"oauth_nonce": paramters.nonce,
			"oauth_timestamp": paramters.timestamp,
			"oauth_consumer_key": oauthGenerator.consumerKey,
			"oauth_signature_method": oauthGenerator.signatureMethod,
			"oauth_version": oauthGenerator.oauthVersion,
			"oauth_token": oauthGenerator.accessToken,
			"oauth_signature": paramters.signature,
		]

		extraParams.forEach { key, val in
			formParams[key] = val
		}

		// Unique filename
		let filename = UUID().uuidString + ".png"

		return AF.upload(
			multipartFormData: { formData in
				formData.append(data, withName: "photo", fileName: filename, mimeType: "image/png")

				for (key, val) in formParams {
					formData.append(val.data(using: .utf8)!, withName: key)
				}
			}, to: url.absoluteString
		)
	}

	public func getImage(id: String) {
		let method = "flickr.photos.getSizes"
		let oauthGenerator = getOauthGenerator()
		let parameters = oauthGenerator.generateParamters(
			url: apiURL, httpMethod: "GET", params: ["method": method, "photo_id": id]
		)

		AF.request(apiURL, method: .get, parameters: [
			"method": method,
			"photo_id": id,
			"oauth_nonce": parameters.nonce,
			"oauth_timestamp": parameters.timestamp,
			"oauth_consumer_key": oauthGenerator.consumerKey,
			"oauth_signature_method": oauthGenerator.signatureMethod,
			"oauth_version": oauthGenerator.oauthVersion,
			"oauth_token": oauthGenerator.accessToken,
			"oauth_signature": parameters.signature,
		]).response { response in
			print(response)
		}
	}

	public func testAuth() -> DataRequest {
		let method = "flickr.test.login"
		let oauthGenerator = getOauthGenerator()
		let parameters = oauthGenerator.generateParamters(
			url: apiURL, httpMethod: "GET", params: ["method": method]
		)

		return AF.request(apiURL, method: .get, parameters: [
			"method": method,
			"oauth_nonce": parameters.nonce,
			"oauth_timestamp": parameters.timestamp,
			"oauth_consumer_key": oauthGenerator.consumerKey,
			"oauth_signature_method": oauthGenerator.signatureMethod,
			"oauth_version": oauthGenerator.oauthVersion,
			"oauth_token": oauthGenerator.accessToken,
			"oauth_signature": parameters.signature,
		])
	}
}
