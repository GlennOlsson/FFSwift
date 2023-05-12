import Foundation

protocol OWSClient {

	var sizeLimit: Int { get }

	/**
	 * Get the data of a post from the server
	 * - Parameter id: The id of the post
	 * - Returns: The post data
	 */
	func get(with postId: String) async throws -> Data

	/**
	 * Upload data to the server
	 * - Parameter data: The data to upload
	 * - Returns: The id of the file
	 */
	func upload(data: Data) async throws -> String

	/**
	 * Get the most recent posts
	 * - Parameter n: The number of posts to get
	 * - Returns: The ids of the posts
	 */
	func getRecent(n: Int) async throws -> [String]

	/**
	 * Delete a post from the server
	 * - Parameter id: The id of the post
	 */
	func delete(id: String) async
}
