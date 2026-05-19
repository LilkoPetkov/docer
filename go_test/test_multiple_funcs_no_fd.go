package main

func main() {}

func testFunc(x, y int) {}

func anotherFunc(x int, y int) int {
	return x + y
}

func test_func() string {
	return ""
}

func genericFunc[T any](x, y T) T {
	return x
}

type testStruct struct{}

func (P testStruct) withObject(x int) string {
	return ""
}

func returnsError(x int) (bool, error) {
	return false, nil
}

func withComment(x int) int {
	// This comment should not be captured
	return 0
}
