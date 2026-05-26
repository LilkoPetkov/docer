package main

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
