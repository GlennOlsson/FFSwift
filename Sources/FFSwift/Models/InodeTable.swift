import Foundation

struct InodeTableEntryMetadata {
	let size: UInt64
	let isDirectory: Bool
	let timeCreated: UInt64
	let timeUpdated: UInt64
	let timeAccessed: UInt64
}

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
	let metadata: InodeTableEntryMetadata

	let posts: [Post]

	init(size: UInt64, isDirectory: Bool, timeCreated: UInt64, timeUpdated: UInt64, timeAccessed: UInt64, posts: [Post], version: UInt8 = 1) {
		self.version = version

		metadata = InodeTableEntryMetadata(
			size: size,
			isDirectory: isDirectory,
			timeCreated: timeCreated,
			timeUpdated: timeUpdated,
			timeAccessed: timeAccessed
		)

		self.posts = posts
	}

	required init(raw: Data) throws {
		try InodeTableEntry.verifyCountAndMagic(raw: raw)

		var index = raw.startIndex + InodeTableEntry.magic.count

		getLogger().notice("index is \(index) and raw.count is \(raw.count), end index is \(raw.endIndex)")

		version = raw[index]
		index += 1

		let size = UInt64(data: raw[index ..< index + 8])
		index += 8

		let isDirectory = raw[index] == 1
		index += 1

		let timeCreated = UInt64(data: raw[index ..< index + 8])
		index += 8
		let timeUpdated = UInt64(data: raw[index ..< index + 8])
		index += 8
		let timeAccessed = UInt64(data: raw[index ..< index + 8])
		index += 8

		metadata = InodeTableEntryMetadata(
			size: size,
			isDirectory: isDirectory,
			timeCreated: timeCreated,
			timeUpdated: timeUpdated,
			timeAccessed: timeAccessed
		)

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
		data.append(metadata.size.data)
		data.append(metadata.isDirectory ? 1 : 0)
		data.append(metadata.timeCreated.data)
		data.append(metadata.timeUpdated.data)
		data.append(metadata.timeAccessed.data)

		for post in posts {
			let rawPost = post.raw
			data.append(UInt8(rawPost.count))
			data.append(rawPost)
		}

		return data
	}

	public static func == (a: InodeTableEntry, b: InodeTableEntry) -> Bool {
		a.version == b.version &&
			a.metadata.size == b.metadata.size &&
			a.metadata.isDirectory == b.metadata.isDirectory &&
			a.metadata.timeCreated == b.metadata.timeCreated &&
			a.metadata.timeUpdated == b.metadata.timeUpdated &&
			a.metadata.timeAccessed == b.metadata.timeAccessed &&
			a.posts == b.posts
	}
}

typealias Inode = UInt64

public class InodeTable: BinaryStructure {
	// MARK: BinaryStructure attributes

	internal static var magic = "INOD"

	var count: Int {
		// Min count plus count of all entries, plus count of all entries times 2 and 8 to account
		// for 2 byte for size of entry and 8 bytes for inode
		return InodeTable.minCount + entries.values.reduce(0) { $0 + $1.count } + entries.count * (2 + 8)
	}

	// Magic + version
	internal static var minCount = InodeTable.magic.count + 1

	internal var version: UInt8

	// MARK: InodeTable attributes

	internal var entries: [Inode: InodeTableEntry]

	init(entries: [Inode: InodeTableEntry], version: UInt8 = 1) {
		self.version = version
		self.entries = entries
	}

	required init(raw: Data) throws {
		try InodeTable.verifyCountAndMagic(raw: raw)

		var index = raw.startIndex + InodeTable.magic.count

		version = raw[index]
		index += 1

		var entries: [Inode: InodeTableEntry] = [:]
		while index < raw.endIndex {
			let inode = UInt64(data: raw[index ..< index + 8])
			index += 8

			let entrySize = Int(UInt16(data: raw[index ..< index + 2]))
			index += 2

			let entry = try InodeTableEntry(raw: raw[index ..< index + entrySize])
			entries[inode] = entry

			index += entry.count
		}
		self.entries = entries
	}

	var raw: Data {
		var data = Data()

		data.append(InodeTable.magic.data(using: .utf8)!)
		data.append(version.data)

		for (inode, entry) in entries {
			data.append(inode.data)

			let rawEntry = entry.raw

			data.append(UInt16(rawEntry.count).data)
			data.append(rawEntry)
		}

		return data
	}

	internal func getNextInode() -> Inode {
		// Append one to the max inode. Even if we would create a new inode every microsecond, the
		// inode will not overflow until after 584,942,417 years
		let maxInode = entries.keys.max()
		// First inode should be 0
		return maxInode?.advanced(by: 1) ?? 0
	}

	func add(entry: InodeTableEntry) -> Inode {
		let inode = getNextInode()

		entries[inode] = entry

		return inode
	}

	func get(with inode: Inode) -> InodeTableEntry? {
		entries[inode]
	}

	public static func == (a: InodeTable, b: InodeTable) -> Bool {
		a.version == b.version && a.entries == b.entries
	}
}
