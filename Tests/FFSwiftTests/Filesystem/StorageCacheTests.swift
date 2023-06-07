@testable import FFSwift
import Foundation
import XCTest

class StorageCacheTests: XCTestCase {
	
	var cache: StorageCache!

	override func setUp() {
		cache = StorageCache()
	}

	func testGettingFromEmptyCacheReturnsNil() {
		let posts = [
			Post(ows: .local, id: "some-id")
		]
		let data = cache.get(posts)

		XCTAssertNil(data)
	}

	func testGettingWrongPostsReturnsNil() {
		let insertedPosts = [
			Post(ows: .local, id: "some-id")
		]

		cache.cache(insertedPosts, with: Data())

		let notInsertedPosts = [
			Post(ows: .flickr, id: "some-other-id")	
		]
		let data = cache.get(notInsertedPosts)

		XCTAssertNil(data)
	}

	func testCanGetCachedData() {
		let posts = [
			Post(ows: .local, id: "some-id")
		]
		let data = Data([0, 1, 2, 3, 4, 5])

		cache.cache(posts, with: data)

		let cachedData = cache.get(posts)

		XCTAssertEqual(data, cachedData)
	}

	func testCanGetCachedDataAfterMultipleCaches() {
		// Cache actual data
		let actualPosts = [
			Post(ows: .local, id: "some-id")
		]
		let actualData = Data([0, 1, 2, 3, 4, 5])
		cache.cache(actualPosts, with: actualData)

		// Cache something else
		let otherPosts = [
			Post(ows: .flickr, id: "some-other-id")
		]
		let otherData = Data([9, 8, 7, 6])

		// Retrieve original data
		cache.cache(otherPosts, with: otherData)

		let cachedData = cache.get(actualPosts)

		XCTAssertEqual(actualData, cachedData)
	}

	func testRemoveRemovedCachedData() {
		let posts = [
			Post(ows: .local, id: "some-id")
		]
		let data = Data([0, 1, 2, 3, 4, 5])

		cache.cache(posts, with: data)

		// Make sure is in cache first
		var cachedData = cache.get(posts)
		XCTAssertEqual(data, cachedData)

		cache.remove(posts)

		// Assert data is nil after remove
		cachedData = cache.get(posts)
		XCTAssertNil(cachedData)
	}
}