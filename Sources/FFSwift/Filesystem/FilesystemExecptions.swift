
public enum FilesystemException: Error, Equatable {
	case noFileWithInode(UInt64)
	case noFileWithName(String)
	case noDirectoryWithInode(UInt64)
	case isDirectory(UInt64)
}
