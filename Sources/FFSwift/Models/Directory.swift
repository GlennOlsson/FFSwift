import Foundation

public enum DirectoryError: Error {
	case nameTooLong
	case noEntryWithName
	case filenameExists
}

class Directory: BinaryStructure {
	// MARK: BinaryStructure attributes

	static var magic: String = "DIR"

	var version: UInt8

	var count: Int {
		// Min count, plus 1 byte for the length of the name of each entry, 8 bytes for the inode and then the
		// size of each name
		// 1 bytes per entry name gives the name up to 256 bytes
		return Self.minCount + entries.count * (1 + 8) + entries.reduce(0) { $0 + $1.key.count }
	}

	static var minCount: Int {
		// Only version and magic are required
		return Directory.magic.count + 1
	}

	// MARK: Directory attributes

	private var entries: [String: Inode]

	// Inode of the directory itself
	var selfInode: Inode

	private func assertFilenameLength(_ filename: String) throws {
		let nameData = filename.data(using: .utf8)!

		guard nameData.count <= UInt8.max else {
			throw DirectoryError.nameTooLong
		}
	}

	init(entries: [String: Inode] = [:], inode: Inode, version: UInt8 = 1) throws {
		self.entries = entries
		self.selfInode = inode
		self.version = version

		try entries.forEach { filename, _ in
			try self.assertFilenameLength(filename)
		}
	}

	required init(raw: Data) throws {
		try Directory.verifyCountAndMagic(raw: raw)

		var index = raw.startIndex + Directory.magic.count

		self.version = raw[index]
		index += 1

		self.selfInode = UInt64(data: raw[index ..< index + 8])
		index += 8

		var entries: [String: Inode] = [:]

		while index < raw.endIndex {
			let nameCount = Int(UInt8(data: raw[index ..< index + 1]))
			index += 1

			let name = String(data: raw[index ..< index + nameCount], encoding: .utf8)!
			index += nameCount

			let inode = UInt64(data: raw[index ..< index + 8])
			index += 8

			entries[name] = inode
		}

		self.entries = entries
	}

	var raw: Data {
		var data = Data()

		data.append(Directory.magic.data(using: .utf8)!)
		data.append(version.data)

		data.append(selfInode.data)

		for (name, inode) in entries {
			// Take the name as utf8 data and then count the bytes as
			// the number of characters can be different from the number of bytes
			let nameData = name.data(using: .utf8)!
			let nameCount = nameData.count

			data.append(UInt8(nameCount).data)
			data.append(nameData)
			data.append(inode.data)
		}

		return data
	}

	func add(filename: String, with inode: Inode) throws {
		guard entries[filename] == nil else {
			throw DirectoryError.filenameExists
		}

		try assertFilenameLength(filename)

		entries[filename] = inode
	}

	func inode(of filename: String) throws -> Inode {
		guard let entry = entries[filename] else {
			throw DirectoryError.noEntryWithName
		}
		return entry
	}

	static func == (a: Directory, b: Directory) -> Bool {
		a.version == b.version && a.entries == b.entries
	}
}
