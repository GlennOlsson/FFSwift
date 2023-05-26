
public enum FilesystemError: Error, Equatable {
	case noFileWithInode(UInt64)
	case noFileWithName(String)
	case noDirectoryWithInode(UInt64)
	case isDirectory(UInt64)
	case isFile

	case fileNotOpen
}
