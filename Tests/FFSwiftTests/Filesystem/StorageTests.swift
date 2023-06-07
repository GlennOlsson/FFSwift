@testable import FFSwift
import Foundation
import XCTest

class StorageTests: XCTestCase {
	var client: MockedOWSClient!
	var owsMapping: [OnlineWebService: OWSClient]!

	var storage: Storage!

	override func setUp() {
		client = MockedOWSClient()
		owsMapping = [.local: client]

		storage = Storage()
	}

	func testInCacheAfterUpload() async {
		let data = Data([0, 1, 2, 3, 4, 5])

		let posts = try! await storage.upload(data: data, to: client, with: "password")

		let cachedData = storage.cache.get(posts)

		// Cannot assert exactly the same as the data is encrypted, i.e. different every time
		XCTAssertNotNil(cachedData)
	}

	// Tests that the cache is used instead of downloading fromm the OWS
	func testOWSIsNotCalledAfterGettingUploadedData() async {
		let data = Data([0, 1, 2, 3, 4, 5])

		client._get = { _ in
			XCTFail("Client should not be called")
			return Data()
		}

		let posts = try! await storage.upload(data: data, to: client, with: "password")

		let cachedData = storage.cache.get(posts)

		XCTAssertEqual(data, cachedData)
	}

	func testOWSIsCalledWhenNotInCache() async {
		let data = Data([0, 1, 2, 3, 4, 5])

		let expectation = self.expectation(description: "OWS Client _get is called")
		expectation.expectedFulfillmentCount = 1

		let password = "password"

		client._get = { _ in
			expectation.fulfill()
			return try! FFSEncoder.encode(data, password: password, limit: .max).first!
		}

		// let posts = try! await storage.upload(data: data, to: client, with: password)

		// The ID is not important here
		let cachedData = try! await storage.download(
			posts: [.init(ows: OWS_CASE, id: "some-id")], 
			with: password, 
			mapping: owsMapping
		)

		await waitForExpectations(timeout: 5)

		XCTAssertEqual(cachedData, data)
	}

	func testRemoveRemovesFromCache() async {
		let data = Data([0, 1, 2, 3, 4, 5])

		client._upload = { _ in
			return "some-id"
		}

		let posts = try! await storage.upload(data: data, to: client, with: "password")

		// Make sure is in cache after upload
		let cachedData = storage.cache.get(posts)
		XCTAssertNotNil(cachedData)

		try! await storage.remove(posts: posts, with: owsMapping)

		// Make sure has been removed from cache
		let cachedData2 = storage.cache.get(posts)
		XCTAssertNil(cachedData2)
	}
}
