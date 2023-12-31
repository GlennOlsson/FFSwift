import Foundation

// Takes a list of Input type and a function that for an Input returns an Output, and returns a list of Output in the 
// same order as the input. The function is called asynchronously for each item in the input list.
func loadAsyncList<Input, Output>(items: [Input], using function: @escaping (Input) async throws -> Output) async throws -> [Output] {
	let taskGroupResult = try await withThrowingTaskGroup(of: (Int, Output).self, returning: [Output].self) { group in
		for (index, item) in items.enumerated() {
			group.addTask {
				let value = try await function(item)
				return (index, value)
			}
		}

		// Make sure the data is concatinated in the correct order
		// group.next returns the next result in the order they were completed, not the order they were added
		var dataList: [Output?] = .init(repeating: nil, count: items.count)
		while let (index, data) = try await group.next() {
			dataList[index] = data
		}

		// Can force cast because we know that all the values are non-nil
		return dataList as! [Output]
	}

	return taskGroupResult
}

/// Get the OWS client for the provided OWS
func getOWSClient(of ows: OnlineWebService, with mapping: [OnlineWebService: OWSClient]) throws -> OWSClient {
	guard let client = mapping[ows] else {
		throw OWSError.unsupportedOWS
	}
	return client
}