import Foundation

/// Cache for storing posts with their data
class StorageCache {
	private let cache: NSCache<NSNumber, NSData>

	/// Initialize the cache with a size limit of 5Mb. When data exceeding this limit are cached, 
	/// cache elements are removed
	init(sizeLimit: Int = 5_000_000) {
		self.cache = NSCache()
		self.cache.totalCostLimit = sizeLimit
	}

	internal func key(of posts: [Post]) -> NSNumber {
		let keyHash = posts.reduce(0) { $0.hashValue ^ $1.hashValue }
		return NSNumber(value: keyHash)
	}

	/// Cache data that are associated with the list of posts
	func cache(_ posts: [Post], with data: Data) {
		let key = key(of: posts)
		let value = NSData(data: data)	

		self.cache.setObject(value, forKey: key, cost: data.count)
	}

	/// Get the data associated with the posts, if stored in the cache. Otherwise, 
	/// returns nil
	func get(_ posts: [Post]) -> Data? {
		let key = key(of: posts)
		let value = self.cache.object(forKey: key)

		// Convert NSData to Data
		return value != nil ? Data(referencing: value!) : nil
	}

	/// Remove cached posts
	func remove(_ posts: [Post]) {
		let key = key(of: posts)

		self.cache.removeObject(forKey: key)
	}
}