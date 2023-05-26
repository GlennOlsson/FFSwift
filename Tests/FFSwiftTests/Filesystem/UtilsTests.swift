@testable import FFSwift
import Foundation
import XCTest

class FilesystemUtilsTests: XCTestCase {
	func testConcatInCorrectOrder() async {
		let semaphore = DispatchSemaphore(value: 0)

		//  async function where the first call returns after the second one has finished
		let f: (Int) -> Data = { i in
			if i == 0 {
				semaphore.wait()
				return UInt8(0).data
			} else {
				defer {
					semaphore.signal()
				}
				return UInt8(1).data
			}
		}

		let data = try! await loadAsyncList(items: [0, 1], using: f)

		XCTAssertEqual(data, [UInt8(0).data, UInt8(1).data])
	}

	func testThrowingFunctionThrows() async {
		let exception = FilesystemError.noFileWithInode(0)
		let f: (Int) throws -> Data = { _ throws in
			throw exception
		}

		let expectation = XCTestExpectation(description: "Task group throws")

		do {
			_ = try await loadAsyncList(items: [0, 1], using: f)
		} catch {
			XCTAssertEqual(error as! FilesystemError, exception)
			expectation.fulfill()
		}
	}

	func testConcatingMany() async {
		let items = Array(0 ..< 1000)

		let data = try! await loadAsyncList(items: items) { UInt16($0).data }

		let expected = items.map { UInt16($0).data }

		XCTAssertEqual(data, expected)
	}
}
