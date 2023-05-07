import Foundation

/// For each item in the input list, f is called asynchronously and the results are concatenated in-order
func concatAsyncData<T>(items: [T], using function: @escaping (T) async throws -> Data) async throws -> Data {
	let taskGroupResult = try await withThrowingTaskGroup(of: (Int, Data).self, returning: Data.self) { group in
		for (index, item) in items.enumerated() {
			group.addTask {
				let value = try await function(item)
				return (index, value)
			}
		}

		// Make sure the data is concatinated in the correct order
		// group.next returns the next result in the order they were completed, not the order they were added
		var dataList = [Data](repeating: Data(), count: items.count)
		while let (index, data) = try await group.next() {
			dataList[index] = data
		}

		return dataList.reduce(Data()) { $0 + $1 }
	}

	return taskGroupResult
}
