

// Exception class for failed flickr upload
public class FlickrUploadException: Error {
	public let message: String

	public init(message: String) {
		self.message = message
	}
}