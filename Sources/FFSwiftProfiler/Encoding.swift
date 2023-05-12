import Foundation
import FFSwift

func encodeData(size: Int) {
	let data: Data = Data(Data(repeating: 0, count: size).map { _ in UInt8.random(in: 0...255) })
	
	_ = try! FFSEncoder.encode(data, password: "password", limit: 1000)
}