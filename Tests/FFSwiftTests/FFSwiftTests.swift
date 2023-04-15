import FFSwift
import XCTest

final class FFSwiftTests: XCTestCase {
    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        //		try encode(png: "", size: (2, 2), pixels: [.init(10, 11, 12), .init(20, 21, 22), .init(31, 32, 33), .init(44, 45, 46)])
        //		try decode()

        let client = FlickrClient(
            
        )

        // get data from file
        let data = try Data(contentsOf: URL(fileURLWithPath: "/tmp/hej.png"))

        print("UPLOADING")
        await client.uploadFile(
            data: data
        )
        print("DONE UPLOADING")
        // client.testAuth()
        // .response { response in
        //     switch response.result {
        //     case let .success(data):
        //         print("SUCCESS", String(data: data!, encoding: .utf8)!)
        //     case let .failure(err):
        //         print("FAILURE", err)
        //     }
        // }

        // Thread.sleep(forTimeInterval: 5)

        XCTAssertEqual(FFSwift().text, "Hello, World!")
    }
}
