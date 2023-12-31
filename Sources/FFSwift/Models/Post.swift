import Foundation

// TODO: In the future, could include data range of post. I.e. starting and ending byte index of full file/directory data
/// Represents a post on an OWS
struct Post: BinaryStructure, Hashable {
	// MARK: BinaryStructure attributes

	static var magic: String = "P"

	var count: Int {
		// Same as min plus length of ID
		return Post.minCount + id.count
	}

	// magic, 1 byte for version, 2 bytes for owsID
	static var minCount: Int = Post.magic.count + 1 + 2

	var version: UInt8

	// MARK: Post attributes

	let ows: OnlineWebService
	// OWS ID of post, max allowed is 252 characters so Post is max 256 bytes
	let id: String

	init(ows: OnlineWebService, id: String, version: UInt8 = 1) {
		self.version = version
		self.ows = ows
		self.id = id
	}

	init(raw: Data) throws {
		try Post.verifyCountAndMagic(raw: raw)

		var index = raw.startIndex + Post.magic.count

		version = raw[index]
		index += 1

		let owsID = UInt16(data: raw[index ..< index + 2])
		self.ows = try OnlineWebService.from(owsID)
		index += 2

		id = String(data: raw[index ..< raw.endIndex], encoding: .utf8)!
	}

	var raw: Data {
		var data = Data()

		data.append(Post.magic.data(using: .utf8)!)
		data.append(version.data)
		data.append(ows.rawValue.data)
		data.append(id.data(using: .utf8)!)

		return data
	}

	public static func == (a: Post, b: Post) -> Bool {
		a.id == b.id && a.ows == b.ows
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(ows)
	}
}
