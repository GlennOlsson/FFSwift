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
func bytesToPixels(_ bytes: Data) -> [PNG.RGBA<UInt16>] {
	var pixels: [PNG.RGBA<UInt16>] = []
	var currentPixel: PNG.RGBA<UInt16> = PNG.RGBA(0)
	var currentComponent = 0

	var i = 0

	var byteIndex = 0
	var doubleByte: UInt16 = 0
	for byte in bytes {
		// If is first byte, store it and continue
		if byteIndex % 2 == 0 {
			doubleByte = UInt16(byte) << 8
			byteIndex += 1
			continue
		} else {
			// If is second byte, combine with first byte
			doubleByte |= UInt16(byte)
			byteIndex = 0
		}

		if i == 0 {
			print("ENCODER First pixel", doubleByte)
		}
		i = i + 1

		switch currentComponent {
		case 0:
			currentPixel.r = doubleByte
		case 1:
			currentPixel.g = doubleByte
		case 2:
			currentPixel.b = doubleByte
		case 3:
			currentPixel.a = doubleByte
		default:
			fatalError("Invalid component")
		}

		currentComponent += 1
		if currentComponent == 4 {
			pixels.append(currentPixel)
			currentComponent = 0
		}
	}

	if currentComponent != 4 {
		pixels.append(currentPixel)
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

		let requiredPixels = ceil(Double(requiredBytes) / 6.0)

		// Let width be the square root of the number of pixels, rounded up
		let width = sqrt(Double(requiredPixels)).rounded(.up)
		let height = ceil(Double(requiredPixels) / width).rounded(.up)

		print("Encoding \(data.count) bytes to \(width)x\(height) image")

		var pixels = bytesToPixels([UInt8(data.count)] + data)

		while pixels.count < Int(width * height) {
			pixels.append(PNG.RGBA(0))
		}

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
