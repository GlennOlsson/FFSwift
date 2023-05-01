import Foundation

/// A protocol for structures that can be serialized and deserialized to and from binary data
protocol BinaryStructure: Equatable {
	/// Magic string in the beginning of the data
	static var magic: String { get }
	
	/// Version of the structure so backwards compatibility can be implemented
	var version: UInt8 { get }
	/// Number of bytes required for the initialized structure
	var count: Int { get }
	/// Minimum number of bytes required to decode the structure
	static var minCount: Int { get }

	init(raw: Data) throws
	var raw: Data { get }

	// Equals overloading
	static func == (lhs: Self, rhs: Self) -> Bool
}

extension BinaryStructure {
	static func verifyCountAndMagic(raw: Data) throws {
		// Make sure that there is enough data to decode the header
		let rawCount = raw.count
		
		guard rawCount >= Self.minCount else {
			throw FFSBinaryStructureError.badDataCount
		}
		
		// Assert that the magic can be decoded
		guard let magic = String(data: raw[0 ..< Self.magic.count], encoding: .utf8) else {
			throw FFSBinaryStructureError.badMagic
		}
		
		// Assert magic is correct
		guard magic == Self.magic else {
			throw FFSBinaryStructureError.badMagic
		}
	}
}