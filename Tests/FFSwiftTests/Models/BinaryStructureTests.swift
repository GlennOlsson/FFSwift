@testable import FFSwift
import XCTest

/// Generic tester for BinaryStructures
protocol BinaryStructureTester: XCTestCase {
	associatedtype T: BinaryStructure

	static func mockedStructure() -> T
}