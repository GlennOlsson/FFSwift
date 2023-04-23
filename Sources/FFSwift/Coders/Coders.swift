struct FFSHeader {
	static let magic = "FFS"

	let majorVersion: UInt8
	let minorVersion: UInt8
	let dataCount: UInt32

	init(majorVersion: UInt8, minorVersion: UInt8, dataCount: UInt32) {
		self.majorVersion = majorVersion
		self.minorVersion = minorVersion
		self.dataCount = dataCount
	}

	// Convinience init for version 1.0
	init(dataCount: Int) {
		self.init(majorVersion: 1, minorVersion: 0, dataCount: UInt32(dataCount))
	}

	// Number of bytes required for the header
	static func count() -> Int {
		// Magic + major + minor + dataCount
		return FFSHeader.magic.count + 1 + 1 + 4
	}

	// Get byte representation of header
	func raw() -> [UInt8] {
		var bytes: [UInt8] = []

		for byte in FFSHeader.magic.utf8 {
			bytes.append(byte)
		}

		bytes.append(majorVersion)
		bytes.append(minorVersion)

		bytes.append(UInt8(truncatingIfNeeded: dataCount >> 24))
		bytes.append(UInt8(truncatingIfNeeded: dataCount >> 16))
		bytes.append(UInt8(truncatingIfNeeded: dataCount >> 8))

		bytes.append(UInt8(truncatingIfNeeded: dataCount))

		return bytes
	}

	// Create header from byte representation
	init?(raw: inout [UInt8]) {
		// Make sure that there is enough data to decode the header
		guard raw.count >= FFSHeader.count() else {
			return nil
		}

		// Assert that the magic is correct
		guard let magic = String(bytes: raw[0..<3], encoding: .utf8) else {
			return nil
		}

		guard magic == "FFS" else {
			return nil
		}

		self.majorVersion = raw[3]
		self.minorVersion = raw[4]

		self.dataCount = UInt32(raw[5]) << 24
			| UInt32(raw[6]) << 16
			| UInt32(raw[7]) << 8
			| UInt32(raw[8])
		
		raw.removeFirst(FFSHeader.count())

		// Make sure that remaining data is at least as long as the dataCount
		guard raw.count >= self.dataCount else {
			return nil
		}
	}
}
