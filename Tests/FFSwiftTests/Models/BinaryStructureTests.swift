@testable import FFSwift
import XCTest

/// Generic tester for BinaryStructures
protocol BinaryStructureTester: XCTestCase {
	associatedtype T: BinaryStructure

	func mockedStructure() -> T
}