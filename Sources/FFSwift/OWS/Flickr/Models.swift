import Foundation

// Tries to get the photo ID from the XML response from Flickr
func parsePhotoId(from data: Data) -> String? {
	let string = String(data: data, encoding: .utf8)
	let regex = try? NSRegularExpression(pattern: "<photoid>([0-9]+)</photoid>", options: [])
	let matches = regex?.matches(in: string ?? "", options: [], range: NSRange(location: 0, length: string?.count ?? 0))
	let match = matches?.first
	let range = match?.range(at: 1)
	let photoId = (string as NSString?)?.substring(with: range ?? NSRange())
	return photoId
}



public class FlickrUploadResponse: Decodable {
	public let stat: String
	public let code: Int
	public let message: String
	public let photos: FlickrPhotos

	// create string representation
	public var description: String {
		return "stat: \(stat), code: \(code), message: \(message), photos: \(photos)"
	}
}

public class FlickrPhotos: Decodable {
	public let photo: [FlickrPhoto]
	// create string representation
	public var description: String {
		return "photo: \(photo)"
	}
}

public class FlickrPhoto: Decodable {
	public let id: String
	public let owner: String
	public let secret: String
	public let server: String
	public let farm: Int
	public let title: String
	public let ispublic: Int
	public let isfriend: Int
	public let isfamily: Int

	// create string representation of object
	public var description: String {
		return "id: \(id), owner: \(owner), secret: \(secret), server: \(server), farm: \(farm), title: \(title), ispublic: \(ispublic), isfriend: \(isfriend), isfamily: \(isfamily)"
	}
}
