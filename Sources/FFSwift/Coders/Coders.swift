import Foundation

import os

public struct FFSHeader {
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
	func raw() -> Data {
		var data = Data()

		data.append(contentsOf: FFSHeader.magic.utf8)

		data.append(majorVersion.data)
		data.append(minorVersion.data)

		data.append(dataCount.data)

		return data
	}

	// Create header from byte representation and advance data pointer
	init?(raw: Data) {
		let logger = Logger(subsystem: "se.glennolsson.ffswift", category: "ffs-coders")
		// Make sure that there is enough data to decode the header
		let rawCount = raw.count
		guard rawCount >= FFSHeader.count() else {
			logger.notice("Not enough data to decode header (\(rawCount) < \(FFSHeader.count()))")
			return nil
		}

		// Assert that the magic is correct
		guard let magic = String(data: raw[0..<3], encoding: .utf8) else {
			logger.notice("Could not decode magic")
			return nil
		}

		guard magic == FFSHeader.magic else {
			logger.notice("Magic is not correct (\(magic, privacy: .public) != \(FFSHeader.magic, privacy: .public))")
			return nil
		}

		self.majorVersion = raw[3]
		self.minorVersion = raw[4]

		let dataCount = UInt32(data: raw[5..<9])
		self.dataCount = dataCount
	}
}
