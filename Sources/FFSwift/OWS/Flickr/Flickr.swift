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
			print("COULD NOT PARSE PHOTO ID FROM \(String(data: response!, encoding: .utf8)!)")
			return nil
		}
	}

	public func deleteFile(id: String) async {
		// Remove photo from Flickr
		let method = "flickr.photos.delete"
		let oauthGenerator = getOauthGenerator()
		let parameters = oauthGenerator.generateParameters(
			url: apiURL, httpMethod: "GET", params: ["method": method, "photo_id": id]
		)

		await withCheckedContinuation { completion in
			AF.request(apiURL, method: .get, parameters: parameters.allParameters).response { response in
				// print resp data as string
				switch response.result {
				case let .success(data):
					print("Successfully uploaded! \(String(data: data!, encoding: .utf8)!)")
				case let .failure(error):
					print("ERROR WITH UPLOAD: \(error)")
				}

				completion.resume()
			}
		}
	}

	public func getRecentFiles(n _: Int) async -> [String]? {
		// TODO:
		return []
	}

	public func getFile(id: String) async -> Data? {
		let data = await withCheckedContinuation { completion in
			self.getImage(id: id).response { response in
				switch response.result {
				case let .success(data):
					print("Successfully uploaded!")
					// Decode JSON
					let decoder = JSONDecoder()
					let response = try? decoder.decode(FlickrGetSizesResponse.self, from: data!)
					if response == nil {
						// print data as string
						print("Get sizes response: \(String(data: data!, encoding: .utf8)!)")
					} else {
						print("Get sizes response: \(response!.description)")
					}
					print("Get sizes response: \(response)")
					completion.resume(returning: data)
				case let .failure(error):
					print("ERROR WITH UPLOAD: \(error)")
					completion.resume(returning: nil)
				}
			}
		}
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

		let parameters = oauthGenerator.generateParameters(
			url: url, httpMethod: "POST", params: extraParams
		)

		var formParams = parameters.allParameters

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

	private func getImage(id: String) -> Alamofire.DataRequest {
		let method = "flickr.photos.getSizes"
		let oauthGenerator = getOauthGenerator()
		print("ID: \(id)")
		let parameters = oauthGenerator.generateParameters(
			url: apiURL, 
			httpMethod: "GET", 
			params: [
				"method": method, 
				"photo_id": id, 
				"format": "json", 
				"nojsoncallback": "1"
			]
		)

		return AF.request(apiURL, method: .get, parameters: parameters.allParameters)
	}

	public func testAuth() -> DataRequest {
		let method = "flickr.test.login"
		let oauthGenerator = getOauthGenerator()
		let parameters = oauthGenerator.generateParameters(
			url: apiURL, httpMethod: "GET", params: ["method": method]
		)

		return AF.request(apiURL, method: .get, parameters: parameters.allParameters)
	}
}
