@testable import FFSwift
import Foundation
import XCTest

public class StreamTests: XCTestCase {
	func testCanRead() {
		let stream = FFSBinaryStream([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		let read = stream.read(count: 5)

		XCTAssertEqual(read, [0, 1, 2, 3, 4])
	}

	func testCanReadMultiple() {
		let stream = FFSBinaryStream([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

		var read = stream.read(count: 5)
		XCTAssertEqual(read, [0, 1, 2, 3, 4])

		read = stream.read(count: 5)
		XCTAssertEqual(read, [5, 6, 7, 8, 9])
	}

	func testWrittenCanBeRead() {
		let stream = FFSBinaryStream()

		let data: [UInt8] = [0, 1, 2, 3, 4]
		stream.write(data)

		let read = stream.read(count: 5)

		XCTAssertEqual(read, data)
	}

	func testReadReturnsNilWhenNoData() {
		let stream = FFSBinaryStream()

		let result: [UInt8]? = stream.read(count: 1)

		XCTAssertNil(result)
	}

	func testReadReturnsNilWhenExhausted() {
		let stream = FFSBinaryStream([0, 1, 2, 3, 4])

		var read = stream.read(count: 5)
		XCTAssertEqual(read, [0, 1, 2, 3, 4])

		read = stream.read(count: 1)
		XCTAssertNil(read)
	}

	func testReadReturnsEmptyWhenCountIs0() {
		let stream = FFSBinaryStream([0, 1, 2, 3, 4])

		// Test when nothing has been read yet
		var read = stream.read(count: 0)
		XCTAssertEqual(read, [])

		_ = stream.read(count: 5)

		// Test when exhausted
		read = stream.read(count: 0)
		XCTAssertEqual(read, [])
	}

	func testWritingAndReading() {
		let stream = FFSBinaryStream()

		stream.write([0, 1, 2, 3, 4])

		var read = stream.read(count: 3)
		XCTAssertEqual(read, [0, 1, 2])

		stream.write([5, 6, 7, 8, 9])

		read = stream.read(count: 3)
		XCTAssertEqual(read, [3, 4, 5])

		read = stream.read(count: 4)
		XCTAssertEqual(read, [6, 7, 8, 9])
	}

	func testWriteAndReadBig() {
		let count = 10000

		let data = Array(0..<count).map { UInt8($0 % 256) }

		let stream = FFSBinaryStream()

		stream.write(data)

		let read = stream.read(count: count)

		XCTAssertEqual(read, data)
	}
}
