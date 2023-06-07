import Foundation

class Storage {

	let cache: StorageCache

	init() {
		cache = StorageCache()
	}

	/// Upload data to the FFS. The data is encrypted and encoded before being uploaded. The uploaded
	/// data is cached.
	func upload(data: Data, to owsClient: OWSClient, with password: String) async throws -> [Post] {
		let encodedData = try FFSEncoder.encode(data, password: password, limit: owsClient.sizeLimit)

		let postIDs = try await loadAsyncList(items: encodedData, using: owsClient.upload(data:))

		let posts = postIDs.map { Post(ows: owsClient.ows, id: $0) }

		self.cache.cache(posts, with: data)

		return posts
	}

	/// Download data from the FFS. The data is decoded and decrypted after being downloaded. The
	/// cache is checked before downloading the data.
	func download(posts: [Post], with password: String, mapping: [OnlineWebService: OWSClient]) async throws -> Data {
		let cachedData = self.cache.get(posts)
		if cachedData != nil {
			return cachedData!
		}

		let imagesData: [Data] = try await loadAsyncList(items: posts) { post async throws in
			let owsClient = try getOWSClient(of: post.ows, with: mapping)
			return try await owsClient.get(with: post.id)
		}

		let decodedData = try FFSDecoder.decode(imagesData, password: password)

		return decodedData
	}

	/// Remove posts from the FFS. The data is removed from the cache and from the OWS.
	func remove(posts: [Post], with mapping: [OnlineWebService: OWSClient]) async throws {
		self.cache.remove(posts)

		for post in posts {
			let client = try getOWSClient(of: post.ows, with: mapping)
			await client.delete(id: post.id)
		}
	}
}