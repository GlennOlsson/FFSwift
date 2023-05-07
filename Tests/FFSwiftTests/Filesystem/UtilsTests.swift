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

		let data = try! await concatAsyncData(items: [0, 1], using: f)

		XCTAssertEqual(data, UInt8(0).data + UInt8(1).data)
	}

	func testThrowingFunctionThrows() async {
		let exception = FilesystemException.noFileWithInode(0)
		let f: (Int) throws -> Data = { _ throws in
			throw exception
		}

		let expectation = XCTestExpectation(description: "Task group throws")

		do {
			_ = try await concatAsyncData(items: [0, 1], using: f)
		} catch {
			XCTAssertEqual(error as! FilesystemException, exception)
			expectation.fulfill()
		}
	}

	func testConcatingMany() async {
		let items = Array(0..<1000)
		
		let data = try! await concatAsyncData(items: items) { UInt16($0).data }

		XCTAssertEqual(data, items.reduce(Data()) { $0 + UInt16($1).data })
	}
}
