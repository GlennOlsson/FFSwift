import Foundation

public class FFSDecodingException: Error {
	public let message: String
	
	public init(message: String) {
		self.message = message
	}
}