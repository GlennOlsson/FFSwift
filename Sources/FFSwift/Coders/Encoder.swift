//
//  Encoder.swift
//  FFS-Mobile
//
//  Created by Glenn Olsson on 2023-04-12.
//

import Foundation
import PNG

// Convert list of bytes to list of 16 bit pixels
func bytesToPixels(_ bytes: Data) throws -> [PNG.RGBA<UInt16>] {
	// Must be divisible by 8
	if bytes.count % 8 != 0 {
		throw FFSEncodeError.badDataCount
	}

	var doubleBytes: [UInt16] = []
	// For each pair of bytes in the data, combine them into a 16 bit value
	for i in stride(from: bytes.startIndex, to: bytes.endIndex, by: 2) {
		let firstByte = UInt16(bytes[i])
		let secondByte = UInt16(bytes[i + 1])
		let doubleByte = (firstByte << 8) | secondByte
		doubleBytes.append(doubleByte)
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
	internal static func createImageData(from data: Data)
		-> (data: Data, width: Int, height: Int)
	{
		// Data plus 8 bytes for size of relevant data
		let requiredBytes = data.count + 8

		// Let pixels be the number of bytes divided by 8, rounded up
		// 8 because 2 bytes per component, and 4 components (with alpha)
		let requiredPixels = ceil(Double(requiredBytes) / 8.0)

		// Let height be the square root of the number of pixels, rounded up
		let height: Int = Int(sqrt(Double(requiredPixels)).rounded(.up))
		let width = Int((requiredPixels / Double(height)).rounded(.up))

		// Total pixels with fillers
		let totalPixels = width * height
		let totalBytes = totalPixels * 8

		// Add random data to fill the number of bytes
		var allData = UInt64(data.count).data + data
		while allData.count < totalBytes {
			allData.append(UInt8.random(in: 0 ... 255))
		}

		return (data: allData, width: width, height: height)
	}

	internal static func encodeImage(with data: Data) throws -> Data {
		let (imageData, width, height) = createImageData(from: data)

		let pixels = try bytesToPixels(imageData)

		let image = PNG.Data.Rectangular(
			packing: pixels,
			size: (x: width, y: height),
			layout: .init(format: .rgba16(palette: [], fill: nil))
		)

		var stream = FFSBinaryStream()
		try? image.compress(stream: &stream, level: 0)

		return stream.readAll()
	}

	/// Encode data into FFS images. Limit says how much FFS data can be in each image
	public static func encode(_ data: Data, password: String, limit: Int) throws -> [Data] {
		let ffsData = try FFSImage.createFFSData(data: data, password: password)

		// Create an image for each `limit` bytes
		var lowIndex = 0
		var highIndex = limit

		var images: [Data] = []
		while highIndex < ffsData.count {
			let ffsDataForImage = ffsData[lowIndex ..< highIndex]
			let imageData = try encodeImage(with: ffsDataForImage)

			images.append(imageData)

			lowIndex += limit
			highIndex += limit
		}

		// Add the last image
		let imageData = ffsData[lowIndex ..< ffsData.count]
		let image = try encodeImage(with: imageData)

		images.append(image)

		return images
	}
}
