import os

func getLogger(category: String = "unset-category") -> Logger {
	return Logger(subsystem: "se.glennolsson.ffswift", category: category)
}