import Foundation

struct InodeTableEntryMetadata {
	var size: UInt64
	var isDirectory: Bool
	var timeCreated: UInt64
	var timeUpdated: UInt64
}

class InodeTableEntry: BinaryStructure {
	// MARK: BinaryStructure attributes

	var count: Int {
		// Min count plus count of all posts, plus count of all post IDs to account for 1 byte per post size (max 256 bytes)
		return InodeTableEntry.minCount + posts.reduce(0) { $0 + $1.count } + posts.count
	}

	// Magic + version + size + isDirectory + timeCreated + timeUpdated
	static var minCount = InodeTableEntry.magic.count + 1 + 8 + 1 + 8 + 8

	static var magic = "INDE"
	var version: UInt8

	// MARK: Entry attributes

	// File/directory size (combined size of post data)
	var metadata: InodeTableEntryMetadata

	var posts: [Post]

	init(size: UInt64, isDirectory: Bool, timeCreated: UInt64, timeUpdated: UInt64, posts: [Post], version: UInt8 = 1) {
		self.version = version

		metadata = InodeTableEntryMetadata(
			size: size,
			isDirectory: isDirectory,
			timeCreated: timeCreated,
			timeUpdated: timeUpdated
		)

		self.posts = posts
	}

	required init(raw: Data) throws {
		try InodeTableEntry.verifyCountAndMagic(raw: raw)

		var index = raw.startIndex + InodeTableEntry.magic.count

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

		metadata = InodeTableEntryMetadata(
			size: size,
			isDirectory: isDirectory,
			timeCreated: timeCreated,
			timeUpdated: timeUpdated
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

		// Sorted so consistent over multiple raw calls. Assumes all IDs are unique across all OWSs,
		// will not certainly be the same order otherwise. But this is disregarded for now.
		for post in posts.sorted(by: { $0.id < $1.id }) {
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

		// Sorted so consistent over multiple raw calls
		for (inode, entry) in entries.sorted(by: { $0.key < $1.key }) {
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

	func get(with inode: Inode) throws -> InodeTableEntry {
		guard let entry = entries[inode] else {
			throw FilesystemError.noFileWithInode(inode)
		}
		return entry
	}

	public static func == (a: InodeTable, b: InodeTable) -> Bool {
		a.version == b.version && a.entries == b.entries
	}
}
