import FFSwift
import XCTest

final class FlickrTest: XCTestCase {
	// MARK: - Integration test for flickr API

	let testImagePath = "Tests/Resources/test.png"
	let secretsPath = "Tests/Resources/Secrets.plist"

	public static func loadClient() -> FlickrClient? {
		// Read credentials from environment variables
		let consumerKey = ProcessInfo.processInfo.environment["FLICKR_CONSUMER_KEY"]
		let consumerSecret = ProcessInfo.processInfo.environment["FLICKR_CONSUMER_SECRET"]
		let accessToken = ProcessInfo.processInfo.environment["FLICKR_ACCESS_TOKEN"]
		let accessSecret = ProcessInfo.processInfo.environment["FLICKR_ACCESS_SECRET"]

		guard
			let key = consumerKey,
			let secret = consumerSecret,
			let token = accessToken,
			let tokenSecret = accessSecret
		else {
			return nil
		}
		return FlickrClient(consumerKey: key, consumerSecret: secret, accessToken: token, accessSecret: tokenSecret)
	}

	func uploadTest(client: FlickrClient, data: Data) async throws -> String? {
		return try await client.upload(data: data)
	}

	func getFileByIDTest(client: FlickrClient, id: String) async throws -> Data? {
		return try await client.get(with: id)
	}

	func getRecentFilesTest(client: FlickrClient, n: Int) async throws -> [String]? {
		return try await client.getRecent(n: n)
	}

	func deleteFileTest(client: FlickrClient, id: String) async {
		await client.delete(id: id)
	}

	func testFlickrIntegration() async throws {
		guard let client = FlickrTest.loadClient() else {
			throw XCTSkip("Could not load client, check environment variables")
		}

		let data = try! Data(contentsOf: URL(fileURLWithPath: testImagePath))

		let photoID = try await uploadTest(client: client, data: data)

		guard let id = photoID else {
			XCTAssertNotNil(photoID)
			return
		}

		// Test get file
		let receivedFileData = try await getFileByIDTest(client: client, id: id)
		XCTAssertNotNil(receivedFileData)

		XCTAssertEqual(data, receivedFileData)

		// Test get recent files
		let recentFiles = try await getRecentFilesTest(client: client, n: 1)
		XCTAssertNotNil(recentFiles)
		XCTAssertEqual(recentFiles!.count, 1)
		XCTAssertEqual(recentFiles![0], id)

		// Test delete file
		await deleteFileTest(client: client, id: id)

		// Test get file after delete
		let expectation = self.expectation(description: "Get file after delete throws correct error")
		expectation.expectedFulfillmentCount = 1

		do {
			let receivedFileDataAfterDelete = try await getFileByIDTest(client: client, id: id)
			XCTAssertNil(receivedFileDataAfterDelete)
		} catch {
			XCTAssertEqual(error as? OWSError, OWSError.noPostWithID(id))
			expectation.fulfill()
		}

		await waitForExpectations(timeout: 1)
	}
}
