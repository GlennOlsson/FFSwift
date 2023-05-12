//
//  Decoder.swift
//  FFS-Mobile
//
//  Created by Glenn Olsson on 2023-04-12.
//

import Foundation
import PNG

// Convert list of 16 bit pixels to bytes
func pixelsToBytes(_ pixels: [PNG.RGBA<UInt16>]) -> Data {
	var bytes = Data()

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

public enum FFSDecoder {
	internal static func decodeImage(with data: Data) throws -> Data {
		// Decode png data and decrypt with password
		var stream = FFSBinaryStream([UInt8](data))

		let png = try! PNG.Data.Rectangular.decompress(stream: &stream)

		let pixels = png.unpack(as: PNG.RGBA<UInt16>.self)

		let bytes = pixelsToBytes(pixels)

		// Take first 8 bytes of data
		var index = bytes.startIndex
		let countData = bytes[index ..< index + 8]
		index += 8

		let relevantDataCount = UInt64(data: countData)

		return bytes[index ..< index + Int(relevantDataCount)]
	}

	/// Decode data from FFS images
	public static func decode(_ imageData: [Data], password: String) throws -> Data {
		var encryptedFFSData = Data()
		for img in imageData {
			let decodedImageData = try decodeImage(with: img)
			encryptedFFSData.append(decodedImageData)
		}

		let (decodedData, header) = try FFSImage.decodeFFSData(ffsData: encryptedFFSData, password: password)

		let relevantData = decodedData[header.dataRange]

		return relevantData
	}
}
