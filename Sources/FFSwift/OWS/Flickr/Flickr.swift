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

let logger = getLogger(category: "flickr")
public class FlickrClient: OWSClient {
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
		let response = await withCheckedContinuation { completion in
			self.upload(data: data).response { response in
				switch response.result {
				case let .success(data):
					completion.resume(returning: data)
				case let .failure(error):
					logger.error("ERROR WITH UPLOAD: \(error)")
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
			logger.error("COULD NOT PARSE PHOTO ID FROM \(String(data: response!, encoding: .utf8)!)")
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
				switch response.result {
				case .success:
					logger.info("Successfully deleted file")
				case let .failure(error):
					logger.error("ERROR WITH UPLOAD: \(error)")
				}

				completion.resume()
			}
		}
	}

	public func getRecentFiles(n: Int) async -> [String]? {
		// Get recent photos from Flickr
		return await getMostRecentImageIDs(n: n)
	}

	public func getFile(id: String) async -> Data? {
		let url = await getImageURL(id: id)

		// Get data from url
		if let url = url {
			let data = await withCheckedContinuation { completion in
				AF.request(url).response { response in
					switch response.result {
					case let .success(data):
						completion.resume(returning: data)
					case let .failure(error):
						logger.error("Error with getting file data from url: \(error)")
						completion.resume(returning: nil)
					}
				}
			}
			return data
		} else {
			return nil
		}
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

		let parameters = oauthGenerator.generateParameters(
			url: url, httpMethod: "POST", params: extraParams
		)

		let formParams = parameters.allParameters

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

	private func getImageURL(id: String) async -> String? {
		let method = "flickr.photos.getSizes"
		let oauthGenerator = getOauthGenerator()
		let parameters = oauthGenerator.generateParameters(
			url: apiURL,
			httpMethod: "GET",
			params: [
				"method": method,
				"photo_id": id,
				"format": "json",
				"nojsoncallback": "1",
			]
		)

		let responseURL: String? = await withCheckedContinuation { continuation in

			AF.request(
				apiURL,
				method: .get,
				parameters: parameters.allParameters
			).response { response in
				// Get the original size url from the response
				switch response.result {
				case let .success(data):
					// Decode JSON
					let decoder = JSONDecoder()
					var url: String? = nil
					if let response = try? decoder.decode(FlickrGetSizesResponse.self, from: data!) {
						response.sizes.size.forEach { size in
							if size.label == "Original" {
								url = size.source
							}
						}

					} else {
						logger.warning("Could not parse getSizes response")
					}
					continuation.resume(returning: url)
				case let .failure(error):
					logger.error("Error with getSizes response: \(error)")
					continuation.resume(returning: nil)
				}
			}
		}

		return responseURL
	}

	private func getMostRecentImageIDs(n: Int) async -> [String] {
		let method = "flickr.photos.getRecent"
		let oauthGenerator = getOauthGenerator()
		let parameters = oauthGenerator.generateParameters(
			url: apiURL,
			httpMethod: "GET",
			params: [
				"method": method,
				"format": "json",
				"nojsoncallback": "1",
				"extras": "url_o",
				"per_page": String(n),
				"user_id": "me",
			]
		)

		let responseIDs: [String] = await withCheckedContinuation { continuation in

			AF.request(
				apiURL,
				method: .get,
				parameters: parameters.allParameters
			).response { response in
				// Get the original size url from the response
				switch response.result {
				case let .success(data):
					// Decode JSON
					let decoder = JSONDecoder()
					var ids: [String] = []
					if let response = try? decoder.decode(FlickrGetRecentResponse.self, from: data!) {
						ids = response.photos.photo.map { $0.id }
					} else {
						logger.warning("Could not parse getRecent response: \(String(data: data!, encoding: .utf8)!)")
					}
					continuation.resume(returning: ids)
				case let .failure(error):
					logger.error("Error with getRecent response: \(error)")
					continuation.resume(returning: [])
				}
			}
		}

		return responseIDs
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
