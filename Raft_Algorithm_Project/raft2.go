package raft

//
// this is an outline of the API that raft must expose to
// the service (or tester). see comments below for
// each of these functions for more details.
//
// rf = Make(...)
//   create a new Raft server.
// rf.Start(command interface{}) (index, term, isleader)
//   start agreement on a new log entry
// rf.GetState() (term, isLeader)
//   ask a Raft for its current term, and whether it thinks it is leader
// ApplyMsg
//   each time a new entry is committed to the log, each Raft peer
//   should send an ApplyMsg to the service (or tester)
//   in the same server.
//

import (
	"bytes"
	"fmt"
	"math"
	"sync"
	"sync/atomic"
	"time"

	"cs350/labgob"
	"cs350/labrpc"
	"math/rand"
)

// import "bytes"
// import "cs350/labgob"

// as each Raft peer becomes aware that successive log entries are
// committed, the peer should send an ApplyMsg to the service (or
// tester) on the same server, via the applyCh passed to Make(). set
// CommandValid to true to indicate that the ApplyMsg contains a newly
// committed log entry.
//
// in part 2D you'll want to send other kinds of messages (e.g.,
// snapshots) on the applyCh, but set CommandValid to false for these
// other uses.
type ApplyMsg struct {
	CommandValid bool
	Command      interface{}
	CommandIndex int

	// For 2D:
	SnapshotValid bool
	Snapshot      []byte
	SnapshotTerm  int
	SnapshotIndex int
}

// struct for log entries
type log_entry struct {
	Term    int
	Command interface{}
}

// A Go object implementing a single Raft peer.
type Raft struct {
	mu        sync.Mutex          // Lock to protect shared access to this peer's state
	peers     []*labrpc.ClientEnd // RPC end points of all peers
	persister *Persister          // Object to hold this peer's persisted state
	me        int                 // this peer's index into peers[]
	dead      int32               // set by Kill()

	// Your data here (2A, 2B, 2C).
	// Look at the paper's Figure 2 for a description of what
	// state a Raft server must maintain.

	State string //MAY NOT BE NECESSERY. "leader", "candidate", "follower".
	//Heartbeat time.Time
	Heartbeat bool

	Votes int

	LastIndex int

	ApplyChannel chan ApplyMsg

	Length int

	numUnsuccess int

	commitIndexChannel chan int

	wasAlive bool

	Majority int

	isSleeping bool

	//isIdle bool

	//check if CAPITAL!!!
	//persistent state on all servers
	currentTerm int
	votedFor    int //candidateID that received vote in current term. 0 to len(rf.peers), null is -1
	log         []log_entry

	//volatile state on all servers
	commitIndex int
	lastApplied int

	//volatile state on leaders
	//reinitialized after election
	nextIndex  []int
	matchIndex []int
}

// return currentTerm and whether this server
// believes it is the leader.
func (rf *Raft) GetState() (int, bool) {

	var term int
	var isleader bool
	// Your code here (2A).

	rf.mu.Lock()

	term = rf.currentTerm
	isleader = (rf.State == "leader")

	rf.mu.Unlock()

	return term, isleader
}

// save Raft's persistent state to stable storage,
// where it can later be retrieved after a crash and restart.
// see paper's Figure 2 for a description of what should be persistent.
func (rf *Raft) persist() {
	// Your code here (2C).
	// Example:
	// w := new(bytes.Buffer)
	// e := labgob.NewEncoder(w)
	// e.Encode(rf.xxx)
	// e.Encode(rf.yyy)
	// data := w.Bytes()
	// rf.persister.SaveRaftState(data)

	rf.mu.Lock()

	w := new(bytes.Buffer)
	e := labgob.NewEncoder(w)
	e.Encode(rf.currentTerm)
	e.Encode(rf.votedFor)
	e.Encode(rf.log)

	//fmt.Println(rf.me, "Inside persist(). State", rf.State, "rf.currentTerm:", rf.currentTerm, "rf.votedFor", rf.votedFor, "rf.log", rf.log)

	data := w.Bytes()

	rf.persister.SaveRaftState(data)

	rf.mu.Unlock()

}

// restore previously persisted state.
func (rf *Raft) readPersist(data []byte) {
	if data == nil || len(data) < 1 { // bootstrap without any state?
		return
	}
	// Your code here (2C).
	// Example:
	// r := bytes.NewBuffer(data)
	// d := labgob.NewDecoder(r)
	// var xxx
	// var yyy
	// if d.Decode(&xxx) != nil ||
	//    d.Decode(&yyy) != nil {
	//   error...
	// } else {
	//   rf.xxx = xxx
	//   rf.yyy = yyy
	// }

	rf.mu.Lock()

	rf.wasAlive = true

	r := bytes.NewBuffer(data)
	d := labgob.NewDecoder(r)

	var current_term int
	var votedfor int
	var logs []log_entry

	if d.Decode(&current_term) != nil || d.Decode(&votedfor) != nil || d.Decode(&logs) != nil {
		err := fmt.Errorf("couldn't successfully decode")
		fmt.Println(err)
		rf.mu.Unlock()
		return
	} else {

		//fmt.Println(rf.me, ":Inside readPersist(). current_term:", current_term, ",votedfor:", votedfor, ",logs:", logs)

		rf.currentTerm = current_term
		rf.votedFor = votedfor
		rf.log = logs
	}

	rf.mu.Unlock()

}

// A service wants to switch to snapshot.  Only do so if Raft hasn't
// have more recent info since it communicate the snapshot on applyCh.
func (rf *Raft) CondInstallSnapshot(lastIncludedTerm int, lastIncludedIndex int, snapshot []byte) bool {

	// Your code here (2D).

	return true
}

// the service says it has created a snapshot that has
// all info up to and including index. this means the
// service no longer needs the log through (and including)
// that index. Raft should now trim its log as much as possible.
func (rf *Raft) Snapshot(index int, snapshot []byte) {
	// Your code here (2D).

}

// example RequestVote RPC arguments structure.
// field names must start with capital letters!
type RequestVoteArgs struct {
	// Your data here (2A, 2B).
	Term         int
	CandidateID  int
	LastLogIndex int
	LastLogTerm  int
}

// example RequestVote RPC reply structure.
// field names must start with capital letters!
type RequestVoteReply struct {
	// Your data here (2A).
	Term          int
	VoteGranted   bool //not sure if this is bool!!!
	AlreadyLeader bool
}

// example AppendEntries RPC arguments structure.
type AppendEntriesArgs struct {
	Term         int
	LeaderID     int
	PrevLogIndex int
	PrevLogTerm  int
	Entries      []log_entry //empty if this is heartbeat
	LeaderCommit int
}

// example AppendEntries RPC reply structure.
type AppendEntriesReply struct {
	Term    int
	Success bool
}

// example RequestVote RPC handler.
func (rf *Raft) RequestVote(args *RequestVoteArgs, reply *RequestVoteReply) {
	// Your code here (2A, 2B).

	rf.mu.Lock()

	//fmt.Println(rf.me, "is giving vote to", args.CandidateID)

	// this will never take place! Because rpc cannot com. with dead leader
	//actually this can take place if a candidate tries to send RequestVote to a new leader

	/*if rf.State == "leader" {
		//leader's role is not to respond these rpcs so
		reply.VoteGranted = false
		reply.AlreadyLeader=true
		reply.Term = rf.currentTerm
	}*/

	//fmt.Println(rf.me, "info: args.Term", args.Term, "rf.currentTerm:", rf.currentTerm, "rf.state:", rf.State, "rf.votedFor:", rf.votedFor)

	if args.Term < rf.currentTerm {
		reply.VoteGranted = false
		//reply.Term = rf.currentTerm
		if rf.State == "leader" {
			reply.AlreadyLeader = true
			//this case can happen when server first timeouts and then recieves heartbeat
			rf.currentTerm = args.Term

			rf.mu.Unlock()
			rf.persist()
			rf.mu.Lock()

		} else {
			reply.AlreadyLeader = false
		}
		reply.Term = rf.currentTerm

	} else if rf.votedFor != -1 {
		if rf.State == "leader" {
			reply.AlreadyLeader = true
		} else {
			reply.AlreadyLeader = false
		}
		reply.VoteGranted = false
		reply.Term = rf.currentTerm
	} else {
		if rf.State == "leader" {
			reply.AlreadyLeader = true
			reply.VoteGranted = false
		} else {
			reply.AlreadyLeader = false

			//CHECK FOR UP-TO-DATE HERE
			//IF THE LEADER IS AT-LEAST UP-TO-DATE GRANT VOTE!
			//ELSE reply.VoteGranted = false

			//fmt.Println(rf.me, "checking UP-TO-DATE. rf.LastIndex:", rf.LastIndex, "log[rf.LastIndex].Term:", rf.log[rf.LastIndex].Term, "args.LastLogTerm", args.LastLogTerm)

			if rf.log[rf.LastIndex].Term > args.LastLogTerm {
				reply.VoteGranted = false
				//reply.Term = rf.currentTerm
			} else if rf.log[rf.LastIndex].Term == args.LastLogTerm {
				if rf.LastIndex > args.LastLogIndex {
					reply.VoteGranted = false
					//reply.Term = rf.currentTerm
				} else {
					rf.votedFor = args.CandidateID
					rf.currentTerm = args.Term
					reply.VoteGranted = true

					rf.mu.Unlock()
					rf.persist()
					rf.mu.Lock()
					//fmt.Println(rf.me, "voted to", rf.votedFor)
				}
			} else {
				rf.votedFor = args.CandidateID
				rf.currentTerm = args.Term
				reply.VoteGranted = true

				rf.mu.Unlock()
				rf.persist()
				rf.mu.Lock()
				//fmt.Println(rf.me, "voted to", rf.votedFor)
			}
		}

	}

	rf.mu.Unlock()
}

// example code to send a RequestVote RPC to a server.
// server is the index of the target server in rf.peers[].
// expects RPC arguments in args.
// fills in *reply with RPC reply, so caller should
// pass &reply.
// the types of the args and reply passed to Call() must be
// the same as the types of the arguments declared in the
// handler function (including whether they are pointers).
//
// The labrpc package simulates a lossy network, in which servers
// may be unreachable, and in which requests and replies may be lost.
// Call() sends a request and waits for a reply. If a reply arrives
// within a timeout interval, Call() returns true; otherwise
// Call() returns false. Thus Call() may not return for a while.
// A false return can be caused by a dead server, a live server that
// can't be reached, a lost request, or a lost reply.
//
// Call() is guaranteed to return (perhaps after a delay) *except* if the
// handler function on the server side does not return.  Thus there
// is no need to implement your own timeouts around Call().
//
// look at the comments in ../labrpc/labrpc.go for more details.
//
// if you're having trouble getting RPC to work, check that you've
// capitalized all field names in structs passed over RPC, and
// that the caller passes the address of the reply struct with &, not
// the struct itself.
func (rf *Raft) sendRequestVote(server int, args *RequestVoteArgs, reply *RequestVoteReply) bool {
	ok := rf.peers[server].Call("Raft.RequestVote", args, reply)
	return ok
}

// example AppendEntries RPC handler.
func (rf *Raft) AppendEntries(args *AppendEntriesArgs, reply *AppendEntriesReply) {
	//update the term and Success. If Success is true then heartbeat is received

	//if it is empty then this is heartbeat
	if len(args.Entries) == 0 {

		rf.mu.Lock()

		if args.Term < rf.currentTerm {
			reply.Success = false
			//currentTerm, for leader to update itself ???
			reply.Term = rf.currentTerm //leader's term is updated

		} else {
			if rf.State == "candidate" {
				//"if leader’s term is at least as large as the candidate’s current term,
				//then the candidate recognizes the leader as legitimate"
				//fmt.Println(rf.me, "is converted to follower inside AppendEntries")
				//fmt.Println("Because rf.State == candidate")

				rf.State = "follower"
				rf.currentTerm = args.Term
			}

			reply.Success = true
			//rf.Heartbeat<-time.Now()
			rf.Heartbeat = true
			rf.currentTerm = args.Term

			rf.mu.Unlock()
			rf.persist()
			rf.mu.Lock()
			//fmt.Println("Heartbeat received successfully by", rf.me)
		}

		rf.mu.Unlock()
	} else {
		rf.mu.Lock()

		if args.Term < rf.currentTerm {
			reply.Success = false
			//currentTerm, for leader to update itself ???
			reply.Term = rf.currentTerm //leader's term is updated
			rf.mu.Unlock()
			return
		}

		//first condition is for safety
		//by Log Matching Property if the condition holds then the entries are the same
		//consistency check
		if len(rf.log) > args.PrevLogIndex {

			if rf.log[args.PrevLogIndex].Term == args.PrevLogTerm {

				rf.log = rf.log[:args.PrevLogIndex+1]

				rf.log = append(rf.log, args.Entries...)

				//fmt.Println("New log appended to", rf.me, "now log is", rf.log)

				//copy(rf.log[rf.LastIndex+1:],args.Entries[:])
				rf.LastIndex = len(rf.log) - 1
				reply.Success = true

				rf.Heartbeat = true //should I put this to other places as well???
			} else {
				//removing the mismatch element
				//temp := rf.log[args.PrevLogIndex+1:]
				//rf.log = append(rf.log[:args.PrevLogIndex], temp...)

				//fmt.Println("removing the mismatch element of", rf.me)
				rf.log = rf.log[:args.PrevLogIndex]

				rf.LastIndex = len(rf.log) - 1

				reply.Success = false
			}
			rf.mu.Unlock()
			rf.persist()
			rf.mu.Lock()

		} else {
			//this means the log entry is not that long enough

			reply.Success = false
		}
		rf.mu.Unlock()
	}

	rf.mu.Lock()

	//fmt.Println(rf.me, "args.LeaderCommit:", args.LeaderCommit, "rf.commitIndex:", rf.commitIndex)

	if args.LeaderCommit > rf.commitIndex {
		//fmt.Println(rf.me, "Inside AppendEntries handler commitIndex is changed!!")
		rf.commitIndex = int(math.Min(float64(args.LeaderCommit), float64(rf.LastIndex)))
		//fmt.Println("Will take the min of them: LeaderCommit:", args.LeaderCommit, "LastIndex:", rf.LastIndex)
		//fmt.Println("rf.commitIndex is changed to", rf.commitIndex)
		rf.commitIndexChannel <- rf.commitIndex
		rf.mu.Unlock()
		//go rf.commit_checker()

	} else {
		rf.mu.Unlock()
	}

	//fmt.Println(rf.me, "AppendEntries finished")

}

// example code to SEND an AppendEntries  RPC to a server.
func (rf *Raft) sendAppendEntries(server int, args *AppendEntriesArgs, reply *AppendEntriesReply) bool {
	ok := rf.peers[server].Call("Raft.AppendEntries", args, reply)
	return ok
}

/*func (rf *Raft) check_majority() {

	time.Sleep(5 * time.Millisecond)

	rf.mu.Lock()

	fmt.Println("checking MAJORITY")

	var majority int = int(math.Floor(float64(rf.Length) / 2))

	var N int = rf.commitIndex + 1

	rf.mu.Unlock()

	for rf.killed() == false {

		rf.mu.Lock()

		var count int = 0

		for i, v := range rf.matchIndex {
			if i == rf.me {
				continue
			}

			if v >= N {
				count++
			}

		}

		fmt.Println("IN majority checker, count is:", count)

		fmt.Println("N is:", N, "log[N] term is:", rf.log[N].Term, "AND currentTerm is:", rf.currentTerm)

		if count >= majority && rf.log[N].Term == rf.currentTerm {
			rf.commitIndex = N
			fmt.Println("Reached to majority, commitIndex is:", rf.commitIndex, "AND last applied is", rf.lastApplied)
			rf.mu.Unlock()

			//go rf.commit_checker()

			break
		}

		rf.mu.Unlock()

		time.Sleep(10 * time.Millisecond)

	}
}*/

// it does consistency check
// it does inconsistency handling
func (rf *Raft) sendAppendEntries_(index int, args AppendEntriesArgs, reply AppendEntriesReply) {

	ok := rf.sendAppendEntries(index, &args, &reply)

	//if reply is false make adjustments in args.
	//like prevlogindex, PrevLogTerm and entries
	//args.Entries=append(args.Entries, rf.log[args.PrevLogIndex])
	//and then send the appendEntries until ok is true
	//don't forget to sleep 10 milliseconds

	rf.mu.Lock()

	//fmt.Println("OK IS", ok)

	if ok == true {

		//fmt.Println("Inside sendAppendEntries_. OK==TRUE")

		if reply.Success == false && reply.Term > rf.currentTerm {
			//fmt.Println(rf.me, "is converted to follower inside sendAppendEntries_")
			//fmt.Println("reply.Success == false && reply.Term > rf.currentTerm. reply.Term is:", reply.Term, "rf.currentTerm is:", rf.currentTerm)
			rf.State = "follower"
			rf.mu.Unlock()
			return
		}

		rf.mu.Unlock()

		for ok == true && reply.Success == false {

			rf.mu.Lock()

			if rf.State != "leader" {
				//fmt.Println(rf.me, "Converted to follower while RETRYİNG RPCs ")
				rf.mu.Unlock()
				return
			}

			//YOU MAY NOT NEED TO DECREMENT BY ONE
			//YOU CAN JUST REPLICATE ALL THE LOGS?

			//fmt.Println("Inside sendAppendEntries_, resending RPC...")

			//args.Entries = rf.log[args.PrevLogIndex:]
			args.Entries = rf.log[rf.matchIndex[index]+1:]
			//args.PrevLogIndex--
			args.PrevLogIndex = rf.matchIndex[index]
			//args.PrevLogTerm = rf.log[args.PrevLogIndex].Term
			args.PrevLogTerm = rf.log[args.PrevLogIndex].Term

			rf.mu.Unlock()

			ok = rf.sendAppendEntries(index, &args, &reply)

		}
		rf.mu.Lock()

	} else {
		//if ok is false then there is a problem with the follower
		//paper mentions that if this is the case, try RPC indefinetely (5.4)

		//fmt.Println("AppendEntries RPC couldn't be sent to:", index, "It will hang here until connection!")
		rf.mu.Unlock()

		for ok == false {
			time.Sleep(10 * time.Millisecond)

			rf.mu.Lock()

			if rf.State != "leader" {
				//fmt.Println(rf.me, "Converted to follower while RETRYİNG RPCs ")
				rf.mu.Unlock()
				return
			}
			rf.mu.Unlock()

			ok = rf.sendAppendEntries(index, &args, &reply)

		}

		rf.mu.Lock()

		//fmt.Println(rf.me, "is now received AppendEntry RPC reply after RETRY")

		if reply.Success == false && reply.Term > rf.currentTerm {
			//fmt.Println(rf.me, "is converted to follower inside sendAppendEntries_")
			//fmt.Println("reply.Success == false && reply.Term > rf.currentTerm. reply.Term is:", reply.Term, "rf.currentTerm is:", rf.currentTerm)
			rf.State = "follower"
			rf.mu.Unlock()
			return
		}

		rf.mu.Unlock()

		for ok == true && reply.Success == false {

			rf.mu.Lock()

			if rf.State != "leader" {
				//fmt.Println(rf.me, "Converted to follower while RETRYİNG RPCs ")
				rf.mu.Unlock()
				return
			}

			//YOU MAY NOT NEED TO DECREMENT BY ONE
			//YOU CAN JUST REPLICATE ALL THE LOGS?

			//fmt.Println("Inside sendAppendEntries_, resending RPC to", index)

			if args.PrevLogIndex-1 > -1 {

				//time.Sleep(5 * time.Millisecond)

				//args.Entries = rf.log[args.PrevLogIndex:]
				args.Entries = rf.log[rf.matchIndex[index]+1:]
				//args.PrevLogIndex--
				args.PrevLogIndex = rf.matchIndex[index]
				//args.PrevLogTerm = rf.log[args.PrevLogIndex].Term
				args.PrevLogTerm = rf.log[args.PrevLogIndex].Term

			} else {
				//this else condition is not necessery. just written for debugging.
				//fmt.Println("YAPMAAAAA!!!! log:", rf.log, "rf.currentTerm:", rf.currentTerm)

			}

			rf.mu.Unlock()

			ok = rf.sendAppendEntries(index, &args, &reply)

		}

		rf.mu.Lock()

	}

	//fmt.Println("THE PLACE WHERE LEADER STUCKS. reply.Success is:", reply.Success)

	//actually this if statement is unnecessary but still...
	if reply.Success == true {

		//fmt.Println("Successfully replicated to:", index)

		rf.matchIndex[index] = rf.nextIndex[index]
		rf.nextIndex[index]++

		//fmt.Println("matchIndex is:", rf.matchIndex, "AND nextIndex is", rf.nextIndex)
	}

	rf.mu.Unlock()

}

// this function is used as goroutine
// it gets the command as the input and does the appending entry to the servers
func (rf *Raft) Append_Entry(command interface{}) {

	//send AppendEntries RPC here
	//do a consistency check
	//do inconsistency handling

	rf.mu.Lock()

	args := AppendEntriesArgs{}

	args.Term = rf.currentTerm
	args.LeaderID = rf.me
	args.PrevLogIndex = rf.LastIndex - 1
	args.PrevLogTerm = rf.log[rf.LastIndex-1].Term
	args.LeaderCommit = rf.commitIndex
	args.Entries = rf.log[rf.LastIndex:]

	//reply := make([]AppendEntriesReply, len(rf.log))

	rf.mu.Unlock()

	for index, _ := range rf.peers {

		rf.mu.Lock()

		if index == rf.me {
			rf.mu.Unlock()
			continue
		}

		reply := AppendEntriesReply{}
		rf.mu.Unlock()

		go rf.sendAppendEntries_(index, args, reply)

		//time.Sleep(100 * time.Millisecond)

	}

	//check if the majority of the servers replicated the log

	//COUNT THIS IN A GO ROUTINE...
	//SO THAT THIS WOULD NOT MISS ANY SERVER THAT TRIES TO STILL CATCH UP
	//go rf.check_majority()

	//time.Sleep(50 * time.Millisecond)

	var counter int = 1

	for rf.killed() == false {

		time.Sleep(10 * time.Millisecond)

		//fmt.Println("checking MAJORITY")

		rf.mu.Lock()

		var majority int = int(math.Floor(float64(rf.Length) / 2))

		var N int = rf.commitIndex + counter

		var count int = 0

		for i, v := range rf.matchIndex {
			if i == rf.me {
				continue
			}

			if v >= N {
				count++
			}

		}

		//fmt.Println("IN majority checker, count is:", count)

		if N < len(rf.log) {

			//fmt.Println("N is:", N, "log[N] term is:", rf.log[N].Term, "AND currentTerm is:", rf.currentTerm)

			if count >= majority && rf.log[N].Term == rf.currentTerm {
				rf.commitIndex = N
				//fmt.Println("FOR N Reached to majority, commitIndex is:", rf.commitIndex, "AND last applied is", rf.lastApplied)
				rf.commitIndexChannel <- rf.commitIndex
				counter = 1
			} else {
				if rf.log[N].Term != rf.currentTerm {
					//fmt.Println("WAITING ENTRY IN ", N, "REPLICATED TO MAJORITY!")
					counter++
				}

			}

		} else {
			rf.mu.Unlock()
			return
		}

		rf.mu.Unlock()

	}

}

// the service using Raft (e.g. a k/v server) wants to start
// agreement on the next command to be appended to Raft's log. if this
// server isn't the leader, returns false. otherwise start the
// agreement and return immediately. there is no guarantee that this
// command will ever be committed to the Raft log, since the leader
// may fail or lose an election. even if the Raft instance has been killed,
// this function should return gracefully.
//
// the first return value is the index that the command will appear at
// if it's ever committed. the second return value is the current
// term. the third return value is true if this server believes it is
// the leader.
func (rf *Raft) Start(command interface{}) (int, int, bool) {

	//fmt.Println("Inside Start")
	index := -1
	term := -1
	isLeader := true

	// Your code here (2B).
	var currentterm int

	if currentterm, isLeader = rf.GetState(); isLeader {

		//adding the command to the log

		rf.mu.Lock()

		//fmt.Println("inside start", rf.me, "is Leader")

		logentry := log_entry{}
		logentry.Command = command
		logentry.Term = currentterm

		rf.log = append(rf.log, logentry)

		rf.mu.Unlock()
		rf.persist() //GO ROUTİNE???
		rf.mu.Lock()

		//fmt.Println("Leader appended to its log:", rf.log)

		rf.LastIndex++
		index = rf.LastIndex

		rf.mu.Unlock()

		go rf.Append_Entry(command)

		//index should be the index of the given command in the committed log

		//fmt.Println("start returns...")

		return index, currentterm, isLeader
	} else {

		return index, term, isLeader
	}

}

// the tester doesn't halt goroutines created by Raft after each test,
// but it does call the Kill() method. your code can use killed() to
// check whether Kill() has been called. the use of atomic avoids the
// need for a lock.
//
// the issue is that long-running goroutines use memory and may chew
// up CPU time, perhaps causing later tests to fail and generating
// confusing debug output. any goroutine with a long-running loop
// should call killed() to check whether it should stop.
func (rf *Raft) Kill() {
	atomic.StoreInt32(&rf.dead, 1)
	// Your code here, if desired.
}

func (rf *Raft) killed() bool {
	z := atomic.LoadInt32(&rf.dead)
	return z == 1
}

func (rf *Raft) sendAppendEntries_immediately(index int) {

	rf.mu.Lock()

	rf.State = "leader"
	//fmt.Println(rf.me, "is noww", rf.State, "with vote:", rf.Votes, "and Term:", rf.currentTerm, "(INSIDE", index, ")")

	//immediately sending heartbeats after election
	//but it will send two times, so you can send it rigth just after rf.me is elected leader

	//Initializing some fields for partB

	for i, _ := range rf.nextIndex {
		if i != rf.me {
			rf.nextIndex[i] = rf.LastIndex + 1
			rf.matchIndex[i] = 0
		}
	}

	args := AppendEntriesArgs{}
	args.LeaderID = rf.me
	args.Term = rf.currentTerm
	args.Entries = make([]log_entry, 0)
	args.LeaderCommit = rf.commitIndex

	rf.mu.Unlock()

	for index, _ := range rf.peers {

		rf.mu.Lock()

		if index == rf.me {
			rf.mu.Unlock()
			continue
		}

		reply := AppendEntriesReply{}
		//cont := rf.sendAppendEntries(index, &args, &reply)

		//fmt.Println("sending heartbeats to:", index)

		rf.mu.Unlock()

		go rf.sendAppendEntries_heartbeat(index, args, reply)

		//time.Sleep(5 * time.Millisecond)

	}

}

func (rf *Raft) sendRequestVote_goroutine(index int, count int, args RequestVoteArgs, reply RequestVoteReply) {

	/*rf.mu.Lock()
	if rf.State == "leader" {
		rf.mu.Unlock()
		return
	}
	rf.mu.Unlock()*/

	isAvailable := rf.sendRequestVote(index, &args, &reply) //what happens this returns false
	//this is what happens when we get false. we may need to decrement some values (like count!)

	rf.mu.Lock()

	if isAvailable {

		if reply.Term > rf.currentTerm {
			/*if reply.Term == -1 {
				fmt.Println("reply after requestvote rpc hasn't changed")
				//this means reply.Term hasn't changed.
				rf.mu.Unlock()
				return
			}*/
			//fmt.Println(rf.me, "is converted to follower inside sendRequestVote_goroutine from", index)
			//fmt.Println("Because reply.Term > rf.currentTerm. reply.Term is:", reply.Term, "rf.currentTerm is:", rf.currentTerm)

			rf.currentTerm = reply.Term
			rf.State = "follower"

			rf.mu.Unlock()
			rf.persist()
			rf.mu.Lock()
		}

		if reply.AlreadyLeader {
			//fmt.Println(rf.me, "is converted to follower inside sendRequestVote_goroutine from", index)
			//fmt.Println("Because reply.AlreadyLeader")
			rf.State = "follower"
			/*if reply.Term != -1 {
				rf.currentTerm = reply.Term
			}*/
			rf.mu.Unlock()
			return
		}

		if rf.State == "follower" {
			//rf.Votes = 0
			/*if reply.Term != -1 {
				rf.currentTerm = reply.Term
			}*/
			rf.mu.Unlock()
			return
		}

		if reply.VoteGranted {
			rf.Votes++

		}

		//var major int = int(math.Floor(float64(rf.Length)/2)) + 1

		//works if majority of servers are alive

		if rf.Votes >= rf.Majority {

			if rf.State == "candidate" {

				rf.mu.Unlock()

				go rf.sendAppendEntries_immediately(index)

				rf.mu.Lock()
			}

		} else if count == rf.Length-1 && rf.Votes < rf.Majority {
			//fmt.Println("ID:", rf.me, "couldn't win the election")
			rf.votedFor = -1 //may not be necessery
			//fmt.Println(rf.me, "is converted to follower inside sendRequestVote_goroutine from", index)
			//fmt.Println("Because count == rf.Length-1 && rf.Votes < majority")
			rf.State = "follower"
			rf.mu.Unlock()
			rf.persist()
			rf.mu.Lock()
		}

	} else {

		//rf.Majority[0]--
		//rf.Majority[1] = int(math.Floor(float64(rf.Majority[0])/2)) + 1

		//var major int = int(math.Floor(float64(rf.Length)/2)) + 1

		if count == rf.Length-1 && rf.Votes < rf.Majority {
			//fmt.Println("ID:", rf.me, "couldn't win the election")
			rf.votedFor = -1
			//fmt.Println(rf.me, "is converted to follower inside sendRequestVote_goroutine from", index)
			//fmt.Println("Because count == rf.Length-1 && rf.Votes < majority")
			rf.State = "follower"
			rf.mu.Unlock()
			rf.persist()
			rf.mu.Lock()
		}

	}

	rf.mu.Unlock()

}

// starts election by a candidate
func (rf *Raft) startElection() {

	//fmt.Println("Election Started for", rf.me, "!")

	rf.mu.Lock()

	args := RequestVoteArgs{}
	args.Term = rf.currentTerm
	args.CandidateID = rf.me
	args.LastLogIndex = rf.LastIndex
	args.LastLogTerm = rf.log[rf.LastIndex].Term

	rf.votedFor = rf.me //voted for itself.

	rf.mu.Unlock()
	rf.persist()
	rf.mu.Lock()

	rf.Votes = 1

	//var majority int = int(math.Floor(float64(rf.Length)/2)) + 1

	//rf.Majority[0] = rf.Length
	rf.Majority = int(math.Floor(float64(rf.Length)/2)) + 1

	//fmt.Println("LENGTH OF PEERS İS:", len(rf.peers))

	var count int = 1
	//count1 := make(chan int)

	rf.mu.Unlock()

	for index, _ := range rf.peers {
		//pass if this server is already a leader

		rf.mu.Lock()

		if rf.State == "follower" {
			rf.mu.Unlock()
			return
		}

		if rf.State == "leader" {
			rf.mu.Unlock()
			return
		}

		if index == rf.me {
			rf.mu.Unlock()
			continue
		}

		//fmt.Println("sending requestvote to", index)

		reply := RequestVoteReply{}

		//reply.Term = -1

		rf.mu.Unlock()

		rf.sendRequestVote_goroutine(index, count, args, reply)
		count++
	}
}

func (rf *Raft) sendAppendEntries_heartbeat(index int, args AppendEntriesArgs, reply AppendEntriesReply) {

	ok := rf.sendAppendEntries(index, &args, &reply) //why go??

	/*if cont == false {
		//failed to send heartbeat, start election timeout
		//candidate is peers[index]
		break
	}*/

	rf.mu.Lock()

	if ok == true && reply.Success == false && reply.Term > rf.currentTerm {
		//there is probably a problem with term.
		//election timeout will start
		rf.currentTerm = reply.Term
		//fmt.Println(rf.me, "is converted to follower inside sendAppendEntries_heartbeat")
		//fmt.Println("Because ok == true && reply.Success == false. From", index)
		rf.State = "follower"

		rf.mu.Unlock()
		rf.persist()
		rf.mu.Lock()
	}

	if ok == false {
		//fmt.Println("ok is false")
		rf.numUnsuccess++
	}

	if rf.numUnsuccess == rf.Length-1 {
		rf.numUnsuccess = 0
		//fmt.Println(rf.me, "is converted to follower inside sendRequestVote_goroutine")
		//fmt.Println("rf.numUnsuccess == rf.Length-1")
		rf.State = "follower"
	}

	rf.mu.Unlock()

}

func isSlicesEqual(a, b []log_entry) bool {
	if len(a) != len(b) {
		return false
	}
	for i, v := range a {
		if v != b[i] {
			return false
		}
	}
	return true
}

// The ticker go routine starts a new election if this peer hasn't received
// heartsbeats recently.
func (rf *Raft) ticker() {
	for rf.killed() == false {

		rf.mu.Lock()

		//fmt.Println("inside ticker, ID:", rf.me, "and state:", rf.State, "currentTerm:", rf.currentTerm, "votes:", rf.Votes, "votedfor:", rf.votedFor, "log:", rf.log)

		//rf.isIdle=false

		rf.numUnsuccess = 0

		rf.mu.Unlock()

		// Your code here to check if a leader election should
		// be started and to randomize sleeping time using
		// time.Sleep().

		//rf.mu.Lock()
		//defer rf.mu.Unlock() // you may delete this
		//rf.votedFor = -1 // DONT DO THİS . AND do this when TRANSITION TO FOLLOWER
		//rf.mu.Unlock()

		//rf.votedFor = -1
		//rf.Votes = 0

		if _, isLeader := rf.GetState(); isLeader {

			//send heartbeats to all other servers/ followers
			//Do I have to create new instance of AppendEntries for each
			//server/follower? Or one instance of it is enough?
			//I think one is enough!!! NOPE

			rf.mu.Lock()

			if rf.killed() == true {
				rf.mu.Unlock()
				return
			}

			//fmt.Println("Leader (ID:", rf.me, ")! Term:", term)

			args := AppendEntriesArgs{}
			args.LeaderID = rf.me
			args.Term = rf.currentTerm
			args.Entries = make([]log_entry, 0) //empty? because this is heartbeat
			if rf.LastIndex != 0 {
				args.LeaderCommit = rf.commitIndex
				args.PrevLogIndex = rf.LastIndex - 1
				args.PrevLogTerm = rf.log[rf.LastIndex-1].Term
			}

			//for each server, index of the next log entry to send to that server
			//rf.nextIndex = make([]int, rf.Length)

			//for each server, index of highest log entry known to be replicated on server
			//rf.matchIndex = make([]int, rf.Length)

			/*finds the index of log's last entry's index
			I didn't use rf.commitIndex because of unexpected failures may happened
			var lastindex int = -1
			for i, v := range rf.log {
				if v.Command == nil {
					break
				}
				lastindex = i
			}*/

			//rf.numUnsuccess = 0

			rf.mu.Unlock()

			//sending heartbeats to the all followers
			for index, _ := range rf.peers {
				//pass if this server is already a leader

				rf.mu.Lock()

				if index == rf.me {
					rf.mu.Unlock()
					continue
				}

				if rf.State == "follower" {
					rf.mu.Unlock()
					break
				}

				//fmt.Println("sending heartbeat to ", index)

				reply := AppendEntriesReply{}
				//cont := rf.sendAppendEntries(index, &args, &reply)

				rf.mu.Unlock()

				go rf.sendAppendEntries_heartbeat(index, args, reply)

				//args.Term=reply.Term //WHY?? IS THIS NECESSERY?? NOPE

			}
			//you can lower this to 150 ms
			time.Sleep(time.Millisecond * 150) //waits 200ms to send heartbeats each round.

		} else {
			rf.mu.Lock()
			rf.isSleeping = true
			LOG := rf.log
			rf.mu.Unlock()

			rand.Seed(time.Now().UnixNano())
			waitforHeartbeat := rand.Intn(800) + 800 //range is [500,1000] milliseconds
			time.Sleep(time.Millisecond * time.Duration(waitforHeartbeat))

			//fmt.Println("follower", rf.me, "waited heartbeat")

			rf.mu.Lock()

			rf.isSleeping = false

			if rf.State == "leader" {
				//fmt.Println(rf.me, "is converted to follower inside ticker")
				//fmt.Println("rf.State == leader")
				rf.State = "follower"
			}

			//check if it received heartbeat

			//start := time.Now()
			//end := <- rf.Heartbeat //what happens if it never receives heartbeat as in very beginning
			//dif := end.Sub(start).Milliseconds()
			//if int(dif) > electionTimeout

			var is bool = true
			var is1 bool = true

			//fmt.Println("Inside ticker (just to check). Its log before checking heartbeat is:", rf.log)

			if rf.Heartbeat == false {
				//start election timeout
				//fmt.Println(rf.me, "is now candidate")
				rf.State = "candidate"

				rf.mu.Unlock()

				check := true

				for check {
					//if it comes here again, this means that election timeout elapsed.
					//starting new election

					rf.mu.Lock()

					rf.State = "candidate"

					if is1 == true && rf.votedFor == -1 {
						//this means this server not gave vote to a candidate
						//and not updated its currentTerm
						//rf.votedFor must be -1 after re-election!!!

						rf.currentTerm = rf.currentTerm + 1
						rf.mu.Unlock()
						rf.persist()
						rf.mu.Lock()
					}

					//fmt.Println("candidate", rf.me, "starting election")

					rf.mu.Unlock()

					go rf.startElection()
					//wait here for election timeout (again randomized? or same)
					rand.Seed(time.Now().UnixNano())
					electionTimeout := rand.Intn(800) + 800 //range is [500,1000] milliseconds
					time.Sleep(time.Millisecond * time.Duration(electionTimeout))

					rf.mu.Lock()

					//fmt.Println("ID:", rf.me, "finished waiting election results", "state is:", rf.State)

					if rf.State != "candidate" {
						check = false
						//rf.votedFor = -1
						//rf.Votes = 0
					}
					if rf.State == "candidate" {
						//fmt.Println(rf.me, "still candidate")
						rf.State = "follower"
						rf.votedFor = -1
						rf.Votes = 0
						is1 = false

						rf.mu.Unlock()
						rf.persist()
						rf.mu.Lock()

						rand.Seed(time.Now().UnixNano())
						electionTimeout := rand.Intn(200) + 200 //range is [200,400] milliseconds
						time.Sleep(time.Millisecond * time.Duration(electionTimeout))
					}

					rf.mu.Unlock()

				}
				rf.mu.Lock()
				is = false
			}

			//fmt.Println("Inside ticker (just to check).", rf.me, "'s log after checking heartbeat is:", rf.log)

			// after election leader immediately sends heartbeats to servers
			//if this is the case, it skips this part
			//the second case is for to omit the cases when the logs are updated
			//because if the log has updated, it means that it received AppendEntries from leader
			if is == true && isSlicesEqual(LOG, rf.log) == true {
				//fmt.Println("heartbeat changed to false!!!")
				rf.Heartbeat = false //check if you put this into correct place
			}

			/*if rf.State == "follower" {
				rf.votedFor = -1 //this is extra. but wouldn't hurt
				rf.Votes = 0
			}*/

			rf.votedFor = -1 //this is extra. but wouldn't hurt
			rf.Votes = 0
			rf.mu.Unlock()
			rf.persist()
		}
	}
}

func (rf *Raft) commit_checker() {
	//repeadetly checks if commitIndex > lastApplied then apply
	//do it like for rf.killed() == false...

	//you have to apply it in order so take use of sikko variables
	//and tell all the followers that this entry has committed. so that they can commit as well.

	for rf.killed() == false {

		rf.mu.Lock()

		select {
		case index := <-rf.commitIndexChannel:

			for index > rf.lastApplied {
				//fmt.Println(rf.me, "inside commit_checker, rf.commitIndex > rf.lastApplied")

				rf.lastApplied++

				apply := ApplyMsg{}

				apply.Command = rf.log[rf.lastApplied].Command
				apply.CommandIndex = rf.lastApplied
				apply.CommandValid = true

				//fmt.Println(rf.me, "IS APPLYING TO CHANNEL", apply)

				rf.ApplyChannel <- apply
			}

		default:

			if rf.isSleeping == true {

				//you may need to do this in a goroutine to not block commit_checker()!!!

				if rf.votedFor != -1 && rf.Heartbeat == false {
					rf.mu.Unlock()
					time.Sleep(100 * time.Millisecond) // waiting time could be different
					rf.mu.Lock()
					if rf.Heartbeat == false && rf.isSleeping == true && rf.State == "follower" {
						//this means the candidate still couldn't win
						rf.votedFor = -1
					}

				}
			}

			rf.mu.Unlock()
			continue
		}

		rf.mu.Unlock()
	}
}

// Each server uses this function only once at Make()
// it appends the dummy entry to the log. For testig convention
// and it applies the dummy entry
func (rf *Raft) AppendDummyEntry(applyCh chan ApplyMsg) {

	if rf.wasAlive == false {
		rf.mu.Lock()

		dummy_logentry := log_entry{}
		dummy_logentry.Term = 0
		dummy_logentry.Command = nil

		rf.log = append(rf.log, dummy_logentry)

		rf.mu.Unlock()
		rf.persist()
		rf.mu.Lock()

		//fmt.Println("Dummy appended to", rf.me, "'s log:", rf.log)

		rf.commitIndex++
		rf.LastIndex = 0

		apply_dummy := ApplyMsg{}

		apply_dummy.Command = nil
		apply_dummy.CommandIndex = 0
		apply_dummy.CommandValid = true

		//apply it
		applyCh <- apply_dummy

		rf.lastApplied++

		rf.mu.Unlock()
	} else {

		//fmt.Println(rf.me, "WAS ALIVE")
		rf.LastIndex = len(rf.log) - 1
		rf.commitIndex = rf.LastIndex
		//rf.lastApplied = rf.LastIndex
		rf.lastApplied = -1
	}

}

// the service or tester wants to create a Raft server. the ports
// of all the Raft servers (including this one) are in peers[]. this
// server's port is peers[me]. all the servers' peers[] arrays
// have the same order. persister is a place for this server to
// save its persistent state, and also initially holds the most
// recent saved state, if any. applyCh is a channel on which the
// tester or service expects Raft to send ApplyMsg messages.
// Make() must return quickly, so it should start goroutines
// for any long-running work.
func Make(peers []*labrpc.ClientEnd, me int,
	persister *Persister, applyCh chan ApplyMsg) *Raft {
	rf := &Raft{}
	rf.peers = peers
	rf.persister = persister
	rf.me = me

	rf.Length = len(peers)

	// Your initialization code here (2A, 2B, 2C).

	rf.mu.Lock()

	rf.wasAlive = false //for 2C

	//for 2A
	rf.State = "follower"
	rf.currentTerm = 0
	rf.Heartbeat = false
	rf.votedFor = -1

	rf.numUnsuccess = 0

	//for 2B
	//empty log entries' terms are initialized to 0. This is dangerous
	//ignore!: my term convention is: -2 means it is not created, -1 is for dummy, othw real terms

	rf.log = make([]log_entry, 0)

	//you may do this inside a goroutine??
	/*for i, _ := range rf.log {
		rf.log[i].Term = -2
	}*/

	rf.commitIndex = -1 //index of highest log entry known to be committed
	rf.lastApplied = -1 //index of highest log entry applied to state machine

	rf.nextIndex = make([]int, rf.Length)
	rf.matchIndex = make([]int, rf.Length)

	rf.ApplyChannel = applyCh

	//rf.mu.Unlock()
	//rf.AppendDummyEntry(applyCh)

	rf.commitIndexChannel = make(chan int, 30)

	//go rf.commit_checker()

	//rf.mu.Lock()

	//fmt.Println("ID:", rf.me, "Inside Make(). Before persist. currentTerm:", rf.currentTerm, "votedFor", rf.votedFor, "log:", rf.log)

	rf.mu.Unlock()

	// initialize from state persisted before a crash
	rf.readPersist(persister.ReadRaftState())

	rf.AppendDummyEntry(applyCh)

	go rf.commit_checker()

	// start ticker goroutine to start elections
	go rf.ticker()

	return rf
}
