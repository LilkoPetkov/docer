package main

import "structs"

// Main entrypoint to the application
func main() {}

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
func returnsError(y struct {
	x, y int
},
) (bool, error) {
	return false, nil
}

// Test function with comment
func withComment(
	x int,
) struct {
	x int
	y int
} {
	// This is a test comment, should not be captured
	return struct {
		x int
		y int
	}{
		5,
		5,
	}
}

// Function with comment, inner function and heavy arguments for both
// Object, func arguments and tuple for returning
func (T testStruct) withInnerFunction(
	x int,
	y struct {
		x int
		y int
	},
) (struct {
	x int
	y int
}, struct {
	x int
	y int
},
) {
	func(x int) int {
		return x
	}(x)

	// This comment should not be evaluated
	return struct {
			x int
			y int
		}{5, 5}, struct {
			x int
			y int
		}{10, 15}
}
