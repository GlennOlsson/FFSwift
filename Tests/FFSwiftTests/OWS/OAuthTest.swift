@testable import FFSwift
import XCTest

class OAuthMock: OAuth {
	let nonceFunc: () -> String
	let timestampFunc: () -> String

	public init(
		consumerKey: String,
		consumerSecret: String,
		accessToken: String,
		accessSecret: String,
		nonceFunc: (() -> String)? = nil,
		timestampFunc: (() -> String)? = nil
	) {
		self.nonceFunc = nonceFunc ?? { UUID().uuidString }
		self.timestampFunc = timestampFunc ?? { "\(Int(Date().timeIntervalSince1970))" }
		super.init(
			consumerKey: consumerKey,
			consumerSecret: consumerSecret,
			accessToken: accessToken,
			accessSecret: accessSecret
		)
	}

	override func getNonce() -> String {
		return nonceFunc()
	}

	override func getTimestamp() -> String {
		return timestampFunc()
	}

	public func parameters(url: URL, httpMethod: String, params: [String: String] = [:]) -> GeneratedParameters {
		return generateParameters(url: url, httpMethod: httpMethod, params: params)
	}
}

final class OAuthTest: XCTestCase {
	let consumerKey = "consumerKey"
	let consumerSecret = "consumerSecret"
	let accessToken = "accessToken"
	let accessSecret = "accessSecret"

	func createOAuth(
		nonceFunc: (() -> String)? = nil,
		timestampFunc: (() -> String)? = nil
	) -> OAuthMock {
		return OAuthMock(
			consumerKey: consumerKey,
			consumerSecret: consumerSecret,
			accessToken: accessToken,
			accessSecret: accessSecret,
			nonceFunc: nonceFunc,
			timestampFunc: timestampFunc
		)
	}

	func testGeneratesSignatureCorrectlyWithoutParams() {
		let expectedSignature = "r37lNQcKnYVm4srhemRQ/vdg+NM="
		let url = URL(string: "http://127.0.0.1:8080")!

		let oath = createOAuth(
			nonceFunc: { "o3xU3JH9FOO5wST9Spn7ZuiXnUUveiPFSjwE+cZliUQ=" },
			timestampFunc: { "1681578509" }
		)

		let generatedParams = oath.generateParameters(url: url, httpMethod: "POST")

		XCTAssertEqual(expectedSignature, generatedParams.signature)
	}

	func testGeneratesSignatureCorrectlyWithParams() {
		let expectedSignature = "7wv/3OGuy8XRihO5Tsbyk3pOp9U="
		let url = URL(string: "http://127.0.0.1:8080")!

		let oath = createOAuth(
			nonceFunc: { "fgBRaNspsqFt+viWm4OpfkNRI9dhZTUnc7cfoN4JFGU=" },
			timestampFunc: { "1681578815" }
		)

		let generatedParams = oath.generateParameters(
			url: url,
			httpMethod: "POST",
			params: [
				"title": "hej hopp",
				"description": "Hejsan på dig",
			]
		)

		XCTAssertEqual(expectedSignature, generatedParams.signature)
	}
}
