
import PNG

class FFSSteam: PNG.Bytestream.Destination {
	func write(_ buffer: [UInt8]) -> Void? {
		print("Write another \(buffer.count)")
	}
}

public func encode(png path:String, size:(x:Int, y:Int), pixels:[PNG.RGBA<UInt8>]) throws {
	let image: PNG.Data.Rectangular = .init(packing: pixels, size: size,
										   layout: .init(format: .rgba8(palette: [], fill: nil)))

	var stream = FFSSteam()
	try image.compress(path: "/tmp/hej.png", level: 0)
}

public func decode() throws {
	guard let image:PNG.Data.Rectangular = try .decompress(path: "/tmp/hej.png") else {
		fatalError("failed to open .png'")
	}

	let rgba:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)

	for pixel in rgba {
		print(pixel)
	}

}

public struct FFSwift {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}
