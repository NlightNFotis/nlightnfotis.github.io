---
layout: post
title: "GSOC (Partial) Week 7 report"
date: 2013-08-05 01:36
comments: false
categories: gsoc golang gcc
---


# An exciting week.

This week was exciting. Spending it on learning about the go runtime was the reason for this. As insightfull as it was however,
it also confused me a little bit. Before this goes any further, I should state that this is a partial report on my research
and my findings. My aims for this week were the following: **To investigate the behavior of go programs under the Hurd, to
study the go runtime, and possibly modify it to see if the goroutine issues are libpthread's issue or the go's runtime issue**. 

# Presenting my findings.

Most of my time was spent studying the gcc go frontend, libgo and the go runtime. Fortunatelly, I can say (gladly) that it was
time well spent. What I got from it were some nice pieces of insight, but also some slight confusion and doubts.

The first interesting thing in my findings was this:

``` go runtime.h

struct	G
{
	Defer*	defer;
	Panic*	panic;
	void*	exception;	// current exception being thrown
	bool	is_foreign;	// whether current exception from other language
	void	*gcstack;	// if status==Gsyscall, gcstack = stackbase to use during gc
	uintptr	gcstack_size;
	void*	gcnext_segment;
	void*	gcnext_sp;
	void*	gcinitial_sp;
	ucontext_t gcregs;
	byte*	entry;		// initial function
	G*	alllink;	// on allg
	void*	param;		// passed parameter on wakeup
	bool	fromgogo;	// reached from gogo
	int16	status;
	int64	goid;
	uint32	selgen;		// valid sudog pointer
	const char*	waitreason;	// if status==Gwaiting
	G*	schedlink;
	bool	readyonstop;
	bool	ispanic;
	bool	issystem;
	int8	raceignore; // ignore race detection events
	M*	m;		// for debuggers, but offset not hard-coded
	M*	lockedm;
	M*	idlem;
	int32	sig;
	int32	writenbuf;
	byte*	writebuf;
	// DeferChunk	*dchunk;
	// DeferChunk	*dchunknext;
	uintptr	sigcode0;
	uintptr	sigcode1;
	// uintptr	sigpc;
	uintptr	gopc;	// pc of go statement that created this goroutine

	int32	ncgo;
	CgoMal*	cgomal;

	Traceback* traceback;

	ucontext_t	context;
	void*		stack_context[10];
};
```

Yep. This is the code that resembles a (yeah, you guessed it, a **goroutine**). I was pretty surprised at first to see that a thread is resembled as a struct. But then again,
taking a closer look at it, it makes perfect sense. The next one though was a *lot trickier*:

```go runtime.h

struct	M
{
	G*	g0;		// goroutine with scheduling stack
	G*	gsignal;	// signal-handling G
	G*	curg;		// current running goroutine
	int32	id;
	int32	mallocing;
	int32	throwing;
	int32	gcing;
	int32	locks;
	int32	nomemprof;
	int32	waitnextg;
	int32	dying;
	int32	profilehz;
	int32	helpgc;
	uint32	fastrand;
	uint64	ncgocall;	// number of cgo calls in total
	Note	havenextg;
	G*	nextg;
	M*	alllink;	// on allm
	M*	schedlink;
	MCache	*mcache;
	G*	lockedg;
	G*	idleg;
	Location createstack[32];	// Stack that created this thread.
	M*	nextwaitm;	// next M waiting for lock
	uintptr	waitsema;	// semaphore for parking on locks
	uint32	waitsemacount;
	uint32	waitsemalock;
	GCStats	gcstats;
	bool	racecall;
	void*	racepc;

	uintptr	settype_buf[1024];
	uintptr	settype_bufsize;

	uintptr	end[];
};
```

This was a source of endless confusion at the beginning. It does have some hints reassuring the fact that G's are indeed goroutines, but nothing that really helps to describe what an M is.
It's structure is identical to that of the G however, which means that it might have something to do with a thread. And indeed it is. Further study of the source code
made me speculate that **M's must be the real operating system scheduled (kernel) threads, while G's (goroutines) must be the lightweight threads managed by the go runtime.**

I was more than happy to find comments that reassured that position of mine.

```
// The go scheduler's job is to match ready-to-run goroutines (`g's)
// with waiting-for-work schedulers (`m's)
```

Another cool finding was the go (runtime) scheduler - from which the above comment originates:

```go proc.c

struct Sched {
	Lock;

	G *gfree;	// available g's (status == Gdead)
	int64 goidgen;

	G *ghead;	// g's waiting to run
	G *gtail;
	int32 gwait;	// number of g's waiting to run
	int32 gcount;	// number of g's that are alive
	int32 grunning;	// number of g's running on cpu or in syscall

	M *mhead;	// m's waiting for work
	int32 mwait;	// number of m's waiting for work
	int32 mcount;	// number of m's that have been created

	volatile uint32 atomic;	// atomic scheduling word (see below)

	int32 profilehz;	// cpu profiling rate

	bool init;  // running initialization
	bool lockmain;  // init called runtime.LockOSThread

	Note	stopped;	// one g can set waitstop and wait here for m's to stop
};
```

From that particular piece of code, without a doubt the most interesting line is: `G *gfree`. That is a pool of the go routines that are available to be used.
There are also helper schedulling functions, from which, the most interesting (for my purposes), was the `static void gfput(G*);` which realeases a go routine (puts it to the gfree list)

```go proc.c

// Put on gfree list.  Sched must be locked.
static void
gfput(G *gp)
{
	gp->schedlink = runtime_sched.gfree;
	runtime_sched.gfree = gp;
}
```
There are loads of other extremely interesting functions there, but for the sake of space I will not expand here more. However I will expand on what it is that is confusing me:

## The source of confusion

My tests in this point are to include testing if removing thread destruction from the go runtime would result in difference in behavior.
There are however (as far as go is concerned), two kinds of threads in the go runtime. **Goroutines** (G's) and the **kernel schedulable threads** (M's).

Neither of which, seem to really be destroyed. From my understanding so far, G's are never totally destroyed (I may be wrong here, I am still researching this bit). Whenever
they are about to "destroyed", they are added to the scheduler's list of freeG's to allow for reuse, as evidenced by the `gfput` and `gfget` functions. 
M's on the other hand (the kernel threads), also seem to not be destroyed. A comment in go's scheduler seems to support this (`// For now, m's never go away.`) and as a 
matter of fact I could not find any code that destroyed M's (I am still researching this bit).

**Since none of the two actually get destroyed, and seeing as thread creation alone should not be buggy, how come we are facing the specific bugs we are facing?**
I will try to provide with an interpretation: Either I am fairly wrong and M's (or G's or both) actually do get destroyed somewhere (possible and very much probable)
or I looking for clues regarding the issue in the wrong place (might be possible but I don't see it being very probable).