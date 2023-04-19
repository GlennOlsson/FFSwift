//
//  Encoder.swift
//  FFS-Mobile
//
//  Created by Glenn Olsson on 2023-04-12.
//

import Foundation
import PNG


// Convert list of 16 bit pixels to bytes
func pixelsToBytes(_ pixels: [PNG.RGBA<UInt16>]) -> [UInt8] {
	var bytes: [UInt8] = []

	var i = 0

	for pixel in pixels {
		for component in [pixel.r, pixel.g, pixel.b, pixel.a] {
			// If is first byte, store it and continue
			let firstByte = UInt8(component >> 8)
			let secondByte = UInt8(component & 0xFF)
			// print("Got \(firstByte) and \(secondByte)")
			if i == 0 {
				print("First pixel", pixel, firstByte, secondByte)
			}
			i = i + 1
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
		print("Output pixels", pixels)
		var bytes = pixelsToBytes(pixels)

		print("Number of bytes to decode: \(bytes[0])")

		// print("Got \(bytes.count) bytes")

		let relevantByteCount = Int(bytes[0])

		bytes.removeFirst()

		let relevantBytes = bytes[0..<relevantByteCount]

		print("Returning \(relevantBytes.count) bytes")

		print(relevantBytes)

		return Data(relevantBytes)
	}

}