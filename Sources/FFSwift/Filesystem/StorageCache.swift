import Foundation

private class CacheKey {
	let hash: Int

	init(_ posts: [Post]) {
		self.hash = posts.reduce(0) { $0.hashValue ^ $1.hashValue }
	}
}

private class CacheValue {
	let data: Data

	init(_ data: Data) {
		self.data = data
	}
}

/// Cache for storing posts with their data
class StorageCache {
	private let cache: NSCache<CacheKey, CacheValue>

	/// Initialize the cache with a size limit of 5Mb. When data exceeding this limit are cached, 
	/// cache elements are removed
	init(costLimit: Int = 5_000_000) {
		self.cache = NSCache()
		self.cache.totalCostLimit = costLimit
	}

	/// Cache data that are associated with the list of posts
	func cache(_ posts: [Post], with data: Data) {
		let key = CacheKey(posts)
		let value = CacheValue(data)

		self.cache.setObject(value, forKey: key, cost: data.count)
	}

	/// Get the data associated with the posts, if stored in the cache. Otherwise, 
	/// returns nil
	func get(_ posts: [Post]) -> Data? {
		let key = CacheKey(posts)
		let value = self.cache.object(forKey: key)

		return value?.data
	}

	func remove(_ posts: [Post]) {
		let key = CacheKey(posts)

		self.cache.removeObject(forKey: key)
	}
}