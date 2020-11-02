/*
@Time : 2018/12/3 17:39
@Author : RonanLuo
*/

package main

import (
	"fmt"
)

type Event struct {
	id   int32
	data interface{}
}

var eventMap = map[int]interface{}{}

func main() {
	var e *Event
	e = nil
	eventMap[1] = e
	eventMap[2] = nil
	fmt.Println(e == nil, eventMap[1] == nil, eventMap[2] == nil)
}
