@testable import FFSwift
import XCTest

final class LocalOWSTests: XCTestCase {
	// MARK: - Integration test for local OWS

	let testImagePath = "Tests/Resources/test.png"

	var client: LocalOWSClient!

	let logger = getLogger(category: "local-ows-tests")

	public static func loadClient() -> LocalOWSClient {
		return LocalOWSClient(directoryName: "test-dir")
	}

	func purgeDirectory() {
		let dirPath = client.basePath
		let fileManager = FileManager.default

		// Remove dir and files in it
		do {
			try fileManager.removeItem(atPath: dirPath.absoluteString)
		} catch {
			logger.error("Could not remove directory \(dirPath.absoluteString, privacy: .public)")
		}
	}

	override func setUp() {
		client = Self.loadClient()
	}

	override func tearDown() {
		purgeDirectory()
	}

	func testLocalOWSIntegration() async throws {
		let data = try! Data(contentsOf: URL(fileURLWithPath: testImagePath))

		let photoID = try await client.upload(data: data)

		// Test get file
		let receivedFileData = try await client.get(with: photoID)
		XCTAssertNotNil(receivedFileData)

		XCTAssertEqual(data, receivedFileData)

		// Test get recent files
		let recentFiles = try await client.getRecent(n: 1)
		XCTAssertEqual(recentFiles.count, 1)
		XCTAssertEqual(recentFiles[0], photoID)

		// Test delete file
		await client.delete(id: photoID)

		// Test get file after delete
		let expectation = self.expectation(description: "Get file after delete throws correct error")
		expectation.expectedFulfillmentCount = 1

		do {
			let receivedFileDataAfterDelete = try await client.get(with: photoID)
			XCTAssertNil(receivedFileDataAfterDelete)
		} catch {
			XCTAssertEqual(error as? OWSError, OWSError.noPostWithID(photoID))
			expectation.fulfill()
		}

		await waitForExpectations(timeout: 1)
	}

	// This test might not work for other OWSs unless they are purged before run
	func testThrowsWhenGettingFromEmpty() async {
		do {
			let _ = try await client.getRecent(n: 1)
			XCTFail("Did not throw")
		} catch {
			XCTAssertEqual(error as? OWSError, OWSError.couldNotGetRecent)
		}
	}

	// This test might not work for other OWSs unless they are purged before run
	func testThrowsWhenGettingNonExistingID() async {
		let id = "non-existing-id"
		do {
			let _ = try await client.get(with: id)
			XCTFail("Did not throw")
		} catch {
			XCTAssertEqual(error as? OWSError, OWSError.noPostWithID(id))
		}
	}
}
