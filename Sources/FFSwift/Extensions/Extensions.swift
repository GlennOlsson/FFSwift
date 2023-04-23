import Foundation

public protocol DataInteger where Self: FixedWidthInteger {
	// Property to get the integer as data
	var data: Data { get }

	// Initializer to create an integer from data
	init(data: Data)
}

extension DataInteger {
	/// Convert integer to data
	public var data: Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: MemoryLayout<Self>.size)
	}

	// Convert data to integer
	public init(data: Data) {
		self = data.withUnsafeBytes { $0.load(as: Self.self) }.bigEndian
	}
}

extension UInt64: DataInteger {}

extension UInt32: DataInteger {}

extension UInt16: DataInteger {}

extension UInt8: DataInteger {}
