package main

import (
	"fmt"
	"runtime"
)

func main()  {
	fmt.Printf("OS:%s, Architecture:%s\n", runtime.GOOS, runtime.GOARCH)
}
