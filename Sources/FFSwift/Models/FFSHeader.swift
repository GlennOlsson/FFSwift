import Foundation

public struct FFSHeader: BinaryStructure {
	static var magic = "FFS"
	/// Minimum number of bytes required for the header, hard coded as `count` is not
	/// reachable in init
	internal static var minCount = 8

	/// Number of bytes required for the header
	var count: Int {
		FFSHeader.magic.count + 1 + 4
	}

	var version: UInt8
	let dataCount: UInt32

	init(version: UInt8, dataCount: UInt32) {
		self.version = version
		self.dataCount = dataCount
	}

	// Convenience init for version 1.0
	init(dataCount: Int) {
		self.init(version: 0, dataCount: UInt32(dataCount))
	}

	/// Create header from byte representation and advance data pointer
	init(raw: Data) throws {
		try FFSHeader.verifyCountAndMagic(raw: raw)

		version = raw[3]

		let dataCount = UInt32(data: raw[4 ..< 8])
		self.dataCount = dataCount
	}

	/// Get byte representation of header
	var raw: Data {
		var data = Data()

		data.append(contentsOf: FFSHeader.magic.utf8)

		data.append(version.data)

		data.append(dataCount.data)

		return data
	}

	var dataRange: Range<Int> {
		return count ..< count + Int(dataCount)
	}
}
