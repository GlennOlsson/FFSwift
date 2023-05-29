import Foundation


class LocalOWSClient: OWSClient {
    var sizeLimit: Int = .max

	let basePath: URL

	let FILE_EXTENSION = "png"

	var ows: OnlineWebService = .local

	let logger = getLogger(category: "local-ows")
	// Post id is the file name, excluding .png extension

	init(directoryName: String = "ffswift-local-ows") {
		let tmpDir = FileManager.default.temporaryDirectory
		self.basePath = tmpDir.appendingPathComponent(directoryName)

		try? FileManager.default.createDirectory(at: basePath, withIntermediateDirectories: true, attributes: nil)

		logger.notice("Local OWS client initialized at \(self.basePath.absoluteString, privacy: .public)")
	}

	internal func fullFilename(for id: String) -> String {
		return "\(id).\(FILE_EXTENSION)"
	}

    func get(with postId: String) async throws -> Data {
		logger.notice("Getting file with id \(postId, privacy: .public)")
		let filename = fullFilename(for: postId)
		let url = basePath.appendingPathComponent(filename)

		// If file doesn't exist, return nil
		guard FileManager.default.fileExists(atPath: url.path) else {
			throw OWSError.noPostWithID(postId)
		}

		return try Data(contentsOf: url)
    }

    func upload(data: Data) async throws -> String {
		let id = UUID().uuidString
        let filename = fullFilename(for: id)

		logger.notice("Saving file with id \(id, privacy: .public) with \(data.count, privacy: .public) bytes)")

		let url = basePath.appendingPathComponent(filename)

		do {
			try data.write(to: url)
		} catch {
			throw OWSError.couldNotUpload
		}

		return id
    }

	internal func creationDate(for filename: String) -> Date? {
		let url = basePath.appendingPathComponent(filename)
		return try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date
	}

    func getRecent(n: Int) async throws -> [String] {
        // Most recent files saved in temporary directory
		let files = try FileManager.default.contentsOfDirectory(atPath: basePath.path)
		
		guard files.count >= n else {
			throw OWSError.couldNotGetRecent
		}

		let sortedFiles = files.sorted { file1, file2 in
			let file1Date = creationDate(for: file1)
			let file2Date = creationDate(for: file2)

			return file1Date ?? Date.distantPast > file2Date ?? Date.distantPast
		}

		let recentFiles = sortedFiles.prefix(n)

		let recentIDs = recentFiles.map { $0.replacingOccurrences(of: ".\(FILE_EXTENSION)", with: "") }

		logger.notice("Getting \(n, privacy: .public) most recent IDs: \(recentIDs, privacy: .public)")

		return recentIDs
    }

    func delete(id: String) async {
		let filename = fullFilename(for: id)
		let url = basePath.appendingPathComponent(filename)

		logger.notice("Deleting file with id \(id, privacy: .public)")

		try? FileManager.default.removeItem(at: url)
    }
}