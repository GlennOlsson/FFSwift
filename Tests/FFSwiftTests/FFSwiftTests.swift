import XCTest
@testable import FFSwift

final class FFSwiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

//		try encode(png: "", size: (2, 2), pixels: [.init(10, 11, 12), .init(20, 21, 22), .init(31, 32, 33), .init(44, 45, 46)])
//		try decode()
		try upload()

        XCTAssertEqual(FFSwift().text, "Hello, World!")
    }
}
