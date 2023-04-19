//
//  Encoder.swift
//  FFS-Mobile
//
//  Created by Glenn Olsson on 2023-04-12.
//

import Foundation
import PNG

class FFSSteam: PNG.Bytestream.Destination {
	var data: [UInt8] = []

	func write(_ buffer: [UInt8]) -> Void? {
		return data.append(contentsOf: buffer)
	}

	func getData() -> Data {
		return Data(data)
	}
}

// Convert list of bytes to list of 16 bit pixels
func bytesToPixels(_ bytes: [UInt8]) -> [PNG.RGBA<UInt16>] {

	var doubleBytes: [UInt16] = []
	// For each pair of bytes in the data, combine them into a 16 bit value
	for i in stride(from: 0, to: bytes.count, by: 2) {
		let firstByte = UInt16(bytes[i])
		let secondByte = UInt16(bytes[i + 1])
		let doubleByte = (firstByte << 8) | secondByte
		doubleBytes.append(doubleByte)
	}
	if bytes.count % 8 != 0 {
		fatalError("Odd number of bytes")
	}

	// For each 4 double bytes, create a pixel
	let pixels = stride(from: 0, to: doubleBytes.count, by: 4).map { i -> PNG.RGBA<UInt16> in
		var pixel = PNG.RGBA<UInt16>(0)
		pixel.r = doubleBytes[i]
		pixel.g = doubleBytes[i + 1]
		pixel.b = doubleBytes[i + 2]
		pixel.a = doubleBytes[i + 3]
		return pixel
	}

	return pixels
}

public enum FFSEncoder {
	public static func encode(_ data: Data, password _: String) -> Data {
		// Encrypt data using password, and encode as png

		// Assume 16bit depth for each component
		// 2 bytes per component, 3 components per pixel, 2*3

		// + 1 for the size
		let requiredBytes = data.count + 1

		print("Input data: \(Array(data))")

		let requiredPixels = ceil(Double(requiredBytes) / 8.0)

		// Let width be the square root of the number of pixels, rounded up
		let width = sqrt(Double(requiredPixels)).rounded(.up)
		let height = ceil(Double(requiredPixels) / width).rounded(.up)

		let totalPixels = Int(width * height)
		let totalBytes = totalPixels * 8

		print("Encoding \(data.count) bytes to \(width)x\(height) image")

		// Add random data to fill the number of pixels
		var allData: [UInt8] = [UInt8(data.count)] + data
		while allData.count < totalBytes {
			allData.append(UInt8.random(in: 0...255))
		}

		let pixels = bytesToPixels(allData)

		print("Pixels: \(pixels)")

		let image = PNG.Data.Rectangular(
			packing: pixels, 
			size: (x: Int(width), y: Int(height)), 
			layout: .init(format: .rgba16(palette: [], fill: nil))
		)


		var stream = FFSSteam()
		try? image.compress(stream: &stream, level: 0)

		print("Encoded \(stream.getData().count) bytes")

		return stream.getData()
	}
}
