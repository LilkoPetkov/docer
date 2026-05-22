package main

import (
	"fmt"
	"structs"
)

// Main entrypoint to the application
func main() {}

func (t teststruct) t1(x, y int) interface{} {
	return x + y
}

// Test function, not useful in any way
//
// Args:
//
//	x: the X value
//	y: the Y value
//
// Returns:
//
//	nill/Void
func testFunc(x, y int) {
}

// Test function returning int
func anotherFunc(x int, y int) int {
	return x + y
}

// Test function returining string
func test_func() string {
	return ""
}

// Test generic function
func genericFunc[T any](x, y T) T {
	return x
}

// Random comment should be skipped as well

// Test struct should be skipped
type testStruct struct{}

// Test function with object
func (P testStruct) withObject(x int) string {
	return ""
}

// Test function returning an error and boolean
func returnsError(y int) (interface{}, error) {
	return y, nil
}

// Test function with comment returning interface
func withComment(
	x int,
) interface{} {
	// This is a test comment, should not be captured
	return 10
}
