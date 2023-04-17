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

	func uploadTest(client: FlickrClient, data: Data) async -> String? {
		return await client.uploadFile(data: data)
	}

	func getFileByIDTest(client: FlickrClient, id: String) async -> Data? {
		return await client.getFile(id: id)
	}

	func getRecentFilesTest(client: FlickrClient, n: Int) async -> [String]? {
		return await client.getRecentFiles(n: n)
	}

	func deleteFileTest(client: FlickrClient, id: String) async {
		await client.deleteFile(id: id)
	}

	func testFlickrIntegration() async {
		guard let client = FlickrTest.loadClient() else {
			XCTFail("Could not load client, check environment variables")
			return
		}

		let data = try! Data(contentsOf: URL(fileURLWithPath: testImagePath))

		let photoID = await uploadTest(client: client, data: data)

		guard let id = photoID else {
			XCTAssertNotNil(photoID)
			return
		}

		// Test get file
		let recievedFileData = await getFileByIDTest(client: client, id: id)
		XCTAssertNotNil(recievedFileData)

		XCTAssertEqual(data, recievedFileData)

		// Test get recent files
		let recentFiles = await getRecentFilesTest(client: client, n: 1)
		XCTAssertNotNil(recentFiles)
		XCTAssertEqual(recentFiles!.count, 1)
		XCTAssertEqual(recentFiles![0], id)

		// Test delete file
		await deleteFileTest(client: client, id: id)

		// Test get file after delete
		let recievedFileDataAfterDelete = await getFileByIDTest(client: client, id: id)
		XCTAssertNil(recievedFileDataAfterDelete)
	}
}
