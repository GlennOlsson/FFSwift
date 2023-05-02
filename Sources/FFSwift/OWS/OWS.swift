import Foundation

protocol OWS {
	var id: OnlineWebService { get}
	/**
	 * Get a file from the server
	 * - Parameter id: The id of the file
	 * - Returns: The file data
	 */
	func getFile(id: String) async -> Data?

	/**
	 * Upload a file to the server
	 * - Parameter data: The file data
	 * - Returns: The id of the file
	 */
	func uploadFile(data: Data) async -> String?

	/**
	 * Get the most recent files
	 * - Parameter n: The number of files to get
	 * - Returns: The ids of the files
	 */
	func getRecentFiles(n: Int) async -> [String]?

	/**
	 * Delete a file from the server
	 * - Parameter id: The id of the file
	 */
	func deleteFile(id: String) async
}
