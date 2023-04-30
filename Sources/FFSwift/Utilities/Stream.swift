import Foundation
import PNG

/// Binary stream with asynchronous write and synchronous read. Thread safe.
class FFSBinaryStream: PNG.Bytestream.Source, PNG.Bytestream.Destination {
    // At 1 Mb, copy the data to a new array and reset the read position
    private let MAX_READ_POSITION = 1_000_000

    var data: [UInt8]

    var readPosition = 0
    var writePosition: Int

    var readableData: Int {
        return writePosition - readPosition
    }

    let dispatchQueue = DispatchQueue(label: "FFSBinaryStream", qos: .userInitiated, attributes: .concurrent)

    init(_ initialData: [UInt8] = []) {
        data = initialData
        writePosition = initialData.count
    }

    func read(count: Int) -> [UInt8]? {
        let data: [UInt8]? = dispatchQueue.sync(flags: .barrier) {
            if count > self.readableData {
                return nil
            }

            defer {
                readPosition += count
                if readPosition > MAX_READ_POSITION {
                    self.data = Array(self.data[self.readPosition ..< self.writePosition])
                    readPosition = 0
                }
            }
            return [UInt8](self.data[readPosition ..< (readPosition + count)])
        }

        return data
    }

    func write(_ incoming: [UInt8]) -> Void? {
        let currentWritePosition = writePosition
        writePosition += incoming.count

        dispatchQueue.async(flags: .barrier) {
            self.data.insert(contentsOf: incoming, at: currentWritePosition)
        }
        return ()
    }

    func readAll() -> Data {
        return Data(read(count: readableData) ?? [])
    }
}
