import Foundation

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