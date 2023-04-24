import FFSwift
import Foundation
import XCTest
import os

public class ExtensionTests: XCTestCase {
	func testUInt64FromData() {
		let data = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x01])
		let value: UInt64 = UInt64(data: data)
		XCTAssertEqual(value, 1)
	}

	func testUInt64ToData() {
		let value: UInt64 = 1
		let data = value.data
		XCTAssertEqual(data, Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x01]))
	}

	func testUInt64ToAndFrom() {
		let values = [
			0,
			1,
			3,
			69,
			420,
			1337,
			123456789,
			123456789123456789,
		]

		values.forEach { value in
			let uint64 = UInt64(value)
			let data = uint64.data
			let newValue: UInt64 = UInt64(data: data)

			XCTAssertEqual(newValue, uint64)
		}
	}

	func testUInt32FromDataWithPartOfArray() {
		let data = Data([0x00, 0x0, 0x00, 0x00, 0x01, 0x00])
		let partData = data[1...4]
		let okData = Data(partData)
		let value: UInt32 = UInt32(data: okData)
		XCTAssertEqual(value, 1)
	}

	func testUInt32FromBiggerData() {
		// 5 byte data array
		let data = Data([0x00, 0x00, 0x00, 0x01, 0x00])
		let value: UInt32 = UInt32(data: data)
		XCTAssertEqual(value, 1)
	}

	func testHexEncodedString() {
		let data = Data([0x00, 0x01, 0x02, 0x03])
		let string = data.hexadecimal
		XCTAssertEqual(string, "00010203")
	}
}