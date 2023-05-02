import Foundation

class InodeTableEntry: BinaryStructure {
	// MARK: BinaryStructure attributes

	var count: Int {
		// Min count plus count of all posts, plus count of all post IDs to account for 1 byte per post size (max 256 bytes)
		return InodeTableEntry.minCount + posts.reduce(0) { $0 + $1.count } + posts.count
	}

	// Magic + version + size + isDirectory + timeCreated + timeUpdated + timeAccessed
	static var minCount = InodeTableEntry.magic.count + 1 + 8 + 1 + 8 + 8 + 8

	static var magic = "INOD"
	var version: UInt8

	// MARK: Entry attributes

	// File/directory size (combined size of post data)
	let size: UInt64
	let isDirectory: Bool

	let timeCreated: UInt64
	let timeUpdated: UInt64
	let timeAccessed: UInt64

	let posts: [Post]

	init(size: UInt64, isDirectory: Bool, timeCreated: UInt64, timeUpdated: UInt64, timeAccessed: UInt64, posts: [Post], version: UInt8 = 1) {
		self.version = version

		self.size = size
		self.isDirectory = isDirectory
		self.timeCreated = timeCreated
		self.timeUpdated = timeUpdated
		self.timeAccessed = timeAccessed
		self.posts = posts
	}

	required init(raw: Data) throws {
		try InodeTableEntry.verifyCountAndMagic(raw: raw)

		var index = raw.startIndex + InodeTableEntry.magic.count

		getLogger().notice("index is \(index) and raw.count is \(raw.count), end index is \(raw.endIndex)")

		version = raw[index]
		index += 1

		size = UInt64(data: raw[index ..< index + 8])
		index += 8

		isDirectory = raw[index] == 1
		index += 1

		timeCreated = UInt64(data: raw[index ..< index + 8])
		index += 8
		timeUpdated = UInt64(data: raw[index ..< index + 8])
		index += 8
		timeAccessed = UInt64(data: raw[index ..< index + 8])
		index += 8

		var posts: [Post] = []
		while index < raw.endIndex {
			let postSize = Int(raw[index])
			index += 1

			let postData: Data = raw[index ..< index + postSize]
			let post = try Post(raw: postData)
			posts.append(post)
			index += post.count
		}
		self.posts = posts
	}

	var raw: Data {
		var data = Data()

		data.append(InodeTableEntry.magic.data(using: .utf8)!)
		data.append(version.data)
		data.append(size.data)
		data.append(isDirectory ? 1 : 0)
		data.append(timeCreated.data)
		data.append(timeUpdated.data)
		data.append(timeAccessed.data)

		for post in posts {
			let rawPost = post.raw
			data.append(UInt8(rawPost.count))
			data.append(rawPost)
		}

		return data
	}

	public static func == (a: InodeTableEntry, b: InodeTableEntry) -> Bool {
		a.version == b.version && a.size == b.size && a.isDirectory == b.isDirectory && a.timeCreated == b.timeCreated && a.timeUpdated == b.timeUpdated && a.timeAccessed == b.timeAccessed && a.posts == b.posts
	}
}

public class InodeTable: BinaryStructure {
	// MARK: BinaryStructure attributes

	static var magic = "INOD"

	var count: Int {
		// Min count plus count of all entries, plus count of all entries times two to account for 2 byte per entry
		return InodeTable.minCount + entries.reduce(0) { $0 + $1.count } + entries.count * 2
	}

	// Magic + version
	static var minCount = InodeTable.magic.count + 1

	var version: UInt8

	// MARK: InodeTable attributes

	let entries: [InodeTableEntry]

	init(entries: [InodeTableEntry], version: UInt8 = 1) {
		self.version = version
		self.entries = entries
	}

	required init(raw: Data) throws {
		try InodeTable.verifyCountAndMagic(raw: raw)

		var index = raw.startIndex + InodeTable.magic.count

		version = raw[index]
		index += 1

		var entries: [InodeTableEntry] = []
		while index < raw.endIndex {
			let entrySize = Int(UInt16(data: raw[index ..< index + 2]))
			index += 2

			let entry = try InodeTableEntry(raw: raw[index ..< index + entrySize])
			entries.append(entry)

			index += entry.count
		}
		self.entries = entries
	}

	var raw: Data {
		var data = Data()

		data.append(InodeTable.magic.data(using: .utf8)!)
		data.append(version.data)

		for entry in entries {
			let rawEntry = entry.raw

			data.append(UInt16(rawEntry.count).data)
			data.append(rawEntry)
		}

		return data
	}

	public static func == (a: InodeTable, b: InodeTable) -> Bool {
		a.version == b.version && a.entries == b.entries
	}
}
