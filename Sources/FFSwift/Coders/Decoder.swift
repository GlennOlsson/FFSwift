//
//  Decoder.swift
//  FFS-Mobile
//
//  Created by Glenn Olsson on 2023-04-12.
//

import Foundation
import PNG

// Convert list of 16 bit pixels to bytes
func pixelsToBytes(_ pixels: [PNG.RGBA<UInt16>]) -> [UInt8] {

	var bytes: [UInt8] = []

	for pixel in pixels {
		for component in [pixel.r, pixel.g, pixel.b, pixel.a] {
			let firstByte = UInt8(component >> 8)
			let secondByte = UInt8(component & 0xFF)

			bytes.append(firstByte)
			bytes.append(secondByte)
		}
	}

	return bytes
}

class FFSOutStream: PNG.Bytestream.Source{
	let data: [UInt8]

	var index = 0

	init(data: [UInt8]) {
		self.data = data
	}

	func read(count: Int) -> [UInt8]? {
		let endIndex = index + count
		let bytes = data[index..<endIndex]
		index = endIndex
		return Array(bytes)
	}

}
public class FFSDecoder {

	public static func decode(_ data: Data, password: String) throws -> Data {
		// Decode png data and decrypt with password
		var stream = FFSOutStream(data: [UInt8](data))

		let png = try! PNG.Data.Rectangular.decompress(stream: &stream)

		let pixels = png.unpack(as: PNG.RGBA<UInt16>.self)

		var bytes = pixelsToBytes(pixels)

		guard let header = FFSHeader(raw: &bytes) else {
			throw FFSDecodeError.notFFSData
		}

		let relevantByteCount = Int(header.dataCount)

		let relevantBytes = bytes[0..<relevantByteCount]

		return Data(relevantBytes)
	}

}