package mr

import (
	"encoding/json"
	"fmt"
	"hash/fnv"
	"io/ioutil"
	"log"
	"net/rpc"
	"os"
	"sort"
	"strconv"
)

// Map functions return a slice of KeyValue.
type KeyValue struct {
	Key   string
	Value string
}

type WorkerSt struct {
	mapf    func(string, string) []KeyValue
	reducef func(string, []string) string
}

type ByKey []KeyValue

// for sorting by key.
func (a ByKey) Len() int           { return len(a) }
func (a ByKey) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a ByKey) Less(i, j int) bool { return a[i].Key < a[j].Key }

// use ihash(key) % NReduce to choose the reduce
// task number for each KeyValue emitted by Map.
func ihash(key string) int {
	h := fnv.New32a()
	h.Write([]byte(key))
	return int(h.Sum32() & 0x7fffffff)
}

// main/mrworker.go calls this function.
func Worker(mapf func(string, string) []KeyValue,
	reducef func(string, []string) string) {

	// Your worker implementation here.

	// uncomment to send the Example RPC to the coordinator.
	// CallExample()
	//copied from lab
	w := WorkerSt{
		mapf:    mapf,
		reducef: reducef,
	}

	w.RequestTask()

	//No need to create explicit function for reduce tasks

}

func (w *WorkerSt) RequestTask() {
	//both reduce and map tasks are performed in this method.
	for {
		args := EmptyArs{}
		reply := Task{}
		cont := call("Coordinator.RequestTask", &args, &reply)

		if !cont {
			break
		}

		if reply.TaskType == 0 { //task type is map
			file, err := os.Open(reply.Filename)
			if err != nil {
				log.Fatalf("cannotopen %v", reply.Filename)
			}
			content, err := ioutil.ReadAll(file)
			if err != nil {
				log.Fatalf("cannot read %v", reply.Filename)
			}
			file.Close()

			kva := w.mapf(reply.Filename, string(content))

			// store kva in multiple files according to rules described in the README
			// ...

			IntermFiles(kva, reply.NumReduce, reply.Filename, reply.MaptaskID)

			fmt.Println("Map task for", reply.Filename, "completed")
			fmt.Println(kva)

			emptyReply := EmptyReply{}
			call("Coordinator.TaskCompleted", &reply, &emptyReply)

		} else { //prepare file contents to be ready for reduce function

			reduceTaskSlice := []KeyValue{}
			intermfilenames := reply.Filenames
			//path := "/Users/canerozer/Desktop/CS350_Assignment1/code/mr/"
			path := "./"

			for _, file := range intermfilenames {

				var rTask []KeyValue

				fileContents, err := ioutil.ReadFile(path + file + ".json")
				if err != nil {
					log.Fatalf("cannot read %v", file)
				}

				err = json.Unmarshal(fileContents, &rTask)
				if err != nil {
					log.Fatalf("cannot unmarshal %v", reply.Filename)
				}

				reduceTaskSlice = append(reduceTaskSlice, rTask...)
			}

			//sorting them to gather same keys

			sort.Sort(ByKey(reduceTaskSlice))

			filename := "mr-out-" + reply.ReduceWorkerID
			//path1 := "/Users/canerozer/Desktop/CS350_Assignment1/code/main/"
			// "../main/mr-tmp/"

			path1 := "./"

			fileR, err := os.Create(path1 + filename)
			if err != nil {
				log.Fatalf("cannot create %v", filename)
			}

			i := 0
			for i < len(reduceTaskSlice) {
				j := i + 1
				for j < len(reduceTaskSlice) && reduceTaskSlice[j].Key == reduceTaskSlice[i].Key {
					j++
				}
				values := []string{}
				for k := i; k < j; k++ {
					values = append(values, reduceTaskSlice[k].Value)
				}
				output := w.reducef(reduceTaskSlice[i].Key, values)

				fmt.Fprintf(fileR, "%v %v\n", reduceTaskSlice[i].Key, output)

				// this is the correct format for each line of Reduce output.
				//fmt.Fprintf(ofile, "%v %v\n", intermediate[i].Key, output)
				i = j
			}
			fileR.Close()

			fmt.Println("Reduce task for", reply.ReduceWorkerID, "completed")

			emptyReply := EmptyReply{}
			call("Coordinator.TaskCompleted", &reply, &emptyReply)

		}
	}
}

// A function that creates files for keys and then encode these files
// naming convention is as in README: "mr-X-Y"
// What is its return type???
func IntermFiles(kva []KeyValue, NumReduce int, Filename string, maptaskid string) {

	X := maptaskid //for naming X
	filename := "mr-" + X + "-"

	fmt.Println("Storing Intermediate file, task no:", X)

	filenames := []string{}

	var hashvalues string

	//YOU CAN DELETE THIS PART IF PROGRAM RUNS SLOW. AND DO FOR FOR
	for _, kv := range kva {

		hashvalues = filename + strconv.Itoa(ihash(kv.Key)%NumReduce)
		filenames = append(filenames, hashvalues)
	}

	filenames = removeDuplicates(filenames)

	//Create json files according to filenames

	//And then encode them with key/value pairs

	//Creating 10 json files for each task:

	path := "./" //may not needed code/mr

	files := make(map[string]*os.File)

	for _, fname := range filenames {
		file, err := os.Create(path + fname + ".json")
		if err != nil {
			log.Fatalf("cannot create %v", fname+".json")
		}
		files[fname] = file
		defer file.Close()
	}

	//first gather keys in different slices

	filecontents := make(map[string][]KeyValue)

	for _, kv := range kva {
		keyname := filename + strconv.Itoa(ihash(kv.Key)%NumReduce)
		filecontents[keyname] = append(filecontents[keyname], kv)
	}

	// now encoding slices to the corresponding json files

	for key, value := range filecontents {
		enc := json.NewEncoder(files[key])
		err := enc.Encode(value)
		if err != nil {
			log.Fatalf("cannot encode %v", key)
		}
	}

}

// my helper function
func contains(s []string, e string) bool {
	for _, a := range s {
		if a == e {
			return true
		}
	}
	return false
}

// my helper function to remove duplicates in a slice
func removeDuplicates(strList []string) []string {
	list := []string{}
	for _, item := range strList {
		if !contains(list, item) {
			list = append(list, item)
		}
	}
	return list
}

// example function to show how to make an RPC call to the coordinator.
//
// the RPC argument and reply types are defined in rpc.go.
func CallExample() {

	// declare an argument structure.
	args := ExampleArgs{}

	// fill in the argument(s).
	args.X = 99

	// declare a reply structure.
	reply := ExampleReply{}

	// send the RPC request, wait for the reply.
	call("Coordinator.Example", &args, &reply)

	// reply.Y should be 100.
	fmt.Printf("reply.Y %v\n", reply.Y)
}

// send an RPC request to the coordinator, wait for the response. c.server() waits this
// usually returns true.
// returns false if something goes wrong.
func call(rpcname string, args interface{}, reply interface{}) bool {
	// c, err := rpc.DialHTTP("tcp", "127.0.0.1"+":1234")
	sockname := coordinatorSock()
	c, err := rpc.DialHTTP("unix", sockname)
	if err != nil {
		log.Fatal("dialing:", err)
	}
	defer c.Close()

	err = c.Call(rpcname, args, reply)
	if err == nil {
		return true
	}

	fmt.Println(err)
	return false
}
