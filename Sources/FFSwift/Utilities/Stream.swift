import Foundation
import PNG

class FFSBinaryStream: PNG.Bytestream.Source, PNG.Bytestream.Destination {
    // At 1 Mb, copy the data to a new array and reset the read position
    private let MAX_READ_POSITION = 1_000_000

    var data: [UInt8]

    var readPosition = 0

    init(_ initialData: [UInt8] = []) {
        data = initialData
    }

    func read(count: Int) -> [UInt8]? {
        if readPosition + count > data.count {
            return nil
        }

        defer {
            readPosition += count
            if readPosition > MAX_READ_POSITION {
                data = Array(data[readPosition ..< data.count])
                readPosition = 0
            }
        }

        let data = self.data[readPosition ..< (readPosition + count)]

        return [UInt8](data)
    }

    func write(_ incoming: [UInt8]) -> Void? {
        data.append(contentsOf: incoming)
    }
}
