package mr

//
// RPC definitions.
//
// remember to capitalize all names.
//

import (
	"os"
	"strconv"
)

//
// example to show how to declare the arguments
// and reply for an RPC.
//

type ExampleArgs struct {
	X int
}

type ExampleReply struct {
	Y int
}

// Add your RPC definitions here.

type EmptyArs struct {
}

type EmptyReply struct {
}

// Universal Task structure
type Task struct { //used to be named MapTask
	Filename       string   // Filename = key
	Filenames      []string //Filenames of buckets of reduce tasks
	NumReduce      int      // Number of reduce tasks, used to figure out number of buckets
	TaskType       int      // 0 -- map 1 --reduce
	ReduceWorkerID string
	MaptaskID      string // ID for each map task
}

type RpcIntermfiles struct {
	Fnames []string
}

// Cook up a unique-ish UNIX-domain socket name
// in /var/tmp, for the coordinator.
// Can't use the current directory since
// Athena AFS doesn't support UNIX-domain sockets.
func coordinatorSock() string {
	s := "/var/tmp/824-mr-"
	s += strconv.Itoa(os.Getuid())
	return s
}
