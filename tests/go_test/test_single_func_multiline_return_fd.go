package main

import (
	"fmt"
	"structs"
)

// This is a multiline comment
// and the function will have args on
// multiple lines
func testFunc(
	x,
	y int,
) (string, error) {
	// Comment, should not be captured
	return "", nil
}
