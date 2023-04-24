import Foundation

import os

public protocol DataInteger where Self: FixedWidthInteger {
	// Property to get the integer as data
	var data: Data { get }

	// Initializer to create an integer from data
	init(data: Data)
}

public extension DataInteger {
	/// Convert integer to data
	var data: Data {
		var value = bigEndian
		return Data(bytes: &value, count: MemoryLayout<Self>.size)
	}

	// Convert data to integer
	init(data: Data) {
		// Copy
		let partData = Data(data)
		self = partData.withUnsafeBytes { $0.load(as: Self.self) }.bigEndian
	}
}

extension UInt64: DataInteger {}

extension UInt32: DataInteger {}

extension UInt16: DataInteger {}

extension UInt8: DataInteger {}

public extension Data {
	init?(hexString: String) {
		let len = hexString.count / 2
		var data = Data(capacity: len)
		var i = hexString.startIndex
		for _ in 0 ..< len {
			let j = hexString.index(i, offsetBy: 2)
			let bytes = hexString[i ..< j]
			if var num = UInt8(bytes, radix: 16) {
				data.append(&num, count: 1)
			} else {
				return nil
			}
			i = j
		}
		self = data
	}

	/// Hexadecimal string representation of `Data` object.
	var hexadecimal: String {
		return map { String(format: "%02x", $0) }
			.joined()
	}
}
