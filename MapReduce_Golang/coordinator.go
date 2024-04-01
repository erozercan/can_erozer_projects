package mr

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"net/rpc"
	"os"
	"strconv"
	"sync"
	"time"
)

type Coordinator struct {
	// Your definitions here.
	NumReduce         int             // Number of reduce tasks
	Files             []string        // Files for map tasks, len(Files) is number of Map tasks
	IntermediateFiles []string        //File names of intermediate files. For Reduce Tasks.
	MapTasks          chan Task       // Channel for uncompleted map tasks
	ReduceTasks       chan Task       // MAY NOT BE NEEDED
	CompletedTasks    map[string]bool // Map to check if task is completed
	Lock              sync.Mutex      // Lock for contolling shared variables
	Stop              bool            // this is a signal for terminate field
	Terminate         bool            // if this turned to true the whole program terminates
}

// Your code here -- RPC handlers for the worker to call.

// an example RPC handler.
//
// the RPC argument and reply types are defined in rpc.go.
func (c *Coordinator) Example(args *ExampleArgs, reply *ExampleReply) error {
	reply.Y = args.X + 1
	return nil
}

func (c *Coordinator) StartReduce() {
	fmt.Println("Adding Reduce Tasks to channel")

	//first I will create a bucket for each reduce task
	//in total there are nReduce tasks
	//And then I will add these tasks to channel

	buckets := make(map[string][]string)
	interfilenames := []string{}

	for i := 1; i < 9; i++ {
		for j := 0; j < 10; j++ {
			interfilenames = append(interfilenames, "mr-"+strconv.Itoa(i)+"-"+strconv.Itoa(j))
		}
	}
	c.Lock.Lock()

	c.IntermediateFiles = interfilenames

	for _, files := range c.IntermediateFiles {
		key := files[len(files)-1:] //key is ranged from 0 to 9
		buckets[key] = append(buckets[key], files)
	}

	for bucketkey, files := range buckets {
		reduceTask := Task{
			Filenames:      files,
			NumReduce:      c.NumReduce,
			ReduceWorkerID: bucketkey,
			TaskType:       1,
		}
		fmt.Println("ReduceTask", reduceTask, "added to channel")

		c.ReduceTasks <- reduceTask
		c.CompletedTasks["reduce_"+reduceTask.ReduceWorkerID] = false
	}
	c.Lock.Unlock()

}

func (c *Coordinator) Start() {
	fmt.Println("Starting Coordinator, adding Map Tasks to channel")

	i := 1
	// Prepare initial MapTasks and add them to the queue
	for _, file := range c.Files {
		mapTask := Task{
			Filename:  file,
			NumReduce: c.NumReduce,
			TaskType:  0,
			MaptaskID: strconv.Itoa(i),
		}
		i++

		fmt.Println("MapTask", mapTask, "added to channel")

		c.MapTasks <- mapTask
		c.CompletedTasks["map_"+mapTask.Filename] = false
	}

	c.server()
}

// RPC that worker calls when idle (worker requests a map task)
func (c *Coordinator) RequestTask(args *EmptyArs, reply *Task) error {
	fmt.Println("Task requested")

	//task, _ := <-c.MapTasks // check if there are uncompleted map tasks. Keep in mind, if MapTasks is empty, this will halt

	select {
	case task := <-c.MapTasks:
		fmt.Println("Map task found,", task.Filename)
		*reply = task
		reply.TaskType = 0
		go c.WaitForWorker(task)
		return nil

	case task := <-c.ReduceTasks:
		fmt.Println("Reduce task found,", task.ReduceWorkerID)
		*reply = task
		reply.TaskType = 1
		go c.WaitForWorker(task)
		return nil

	default: //if both task channels are empty, cases will wait and default take place

		//If stop is changed as true, this means the program has already entered here
		//and there is no reduce tasks left in the channel.
		c.Lock.Lock()
		if c.Stop {
			c.Terminate = true
			c.Lock.Unlock()
			return fmt.Errorf("ALL TASKS ARE FINISHED OR program entered here twice")
		}
		c.Stop = true
		c.Lock.Unlock()

		//StartReduce() initializes reduce tasks. Similar to Start().
		c.StartReduce()

		task := <-c.ReduceTasks
		fmt.Println("Reduce task found, ID:", task.ReduceWorkerID)
		*reply = task
		reply.TaskType = 1
		go c.WaitForWorker(task)

		return nil
	}
}

// Goroutine will wait 10 seconds and check if map task is completed or not
func (c *Coordinator) WaitForWorker(task Task) {
	time.Sleep(time.Second * 10)
	c.Lock.Lock()
	if task.TaskType == 0 {
		if !c.CompletedTasks["map_"+task.Filename] {
			fmt.Println("Timer expired, task", task.Filename, "is not finished. Putting back in queue.")
			c.MapTasks <- task
		}
	} else {
		if !c.CompletedTasks["reduce_"+task.ReduceWorkerID] {
			fmt.Println("Timer expired, task", task.Filename, "is not finished. Putting back in queue.")
			c.ReduceTasks <- task
		}
	}
	c.Lock.Unlock()
}

// RPC for reporting a completion of a task
func (c *Coordinator) TaskCompleted(args *Task, reply *EmptyReply) error {
	c.Lock.Lock()

	if args.TaskType == 0 {

		c.CompletedTasks["map_"+args.Filename] = true

	} else {
		c.CompletedTasks["reduce_"+args.ReduceWorkerID] = true
	}
	c.Lock.Unlock()
	fmt.Println("Task", args, "completed")

	// If all of map tasks are completed, go to reduce phase
	// ...

	return nil
}

// start a thread that listens for RPCs from worker.go
func (c *Coordinator) server() {
	rpc.Register(c)
	rpc.HandleHTTP()
	//l, e := net.Listen("tcp", ":1234")
	sockname := coordinatorSock()
	os.Remove(sockname)
	l, e := net.Listen("unix", sockname)
	if e != nil {
		log.Fatal("listen error:", e)
	}
	go http.Serve(l, nil)
}

// main/mrcoordinator.go calls Done() periodically to find out
// if the entire job has finished.
func (c *Coordinator) Done() bool {
	ret := false

	// Your code here.
	c.Lock.Lock()

	if c.Terminate {
		ret = true
	}
	defer c.Lock.Unlock()

	return ret
}

// create a Coordinator.
// main/mrcoordinator.go calls this function.
// nReduce is the number of reduce tasks to use.
func MakeCoordinator(files []string, nReduce int) *Coordinator {
	c := Coordinator{
		NumReduce:      nReduce,
		Files:          files,
		MapTasks:       make(chan Task, 100),
		ReduceTasks:    make(chan Task, 100),
		CompletedTasks: make(map[string]bool),
		Stop:           false,
	}

	fmt.Println("Starting coordinator")

	c.Start()

	return &c
}
