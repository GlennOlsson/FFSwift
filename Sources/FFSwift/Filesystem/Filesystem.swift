import Foundation

//MARK: All filesystem operation functions

func open(_ path: String, _ flags: Int32) -> Int32 {
    // Implementation
	return 0
}

func close(_ fd: Int32) -> Int32 {
    // Implementation
	return 0
}

func write(_ fd: Int32, _ buf: UnsafeRawPointer, _ count: Int) -> Int {
    // Implementation
	return 0
}

func read(_ fd: Int32, _ buf: UnsafeMutableRawPointer, _ count: Int) -> Int {
    // Implementation
	return 0
}

func creat(_ path: String, _ mode: mode_t) -> Int32 {
    // Implementation
	return 0
}