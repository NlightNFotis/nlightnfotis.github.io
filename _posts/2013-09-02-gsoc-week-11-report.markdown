---
layout: post
title: "GSOC Week 11 report"
date: 2013-09-02 09:25
comments: false
tags: [gcc, golang, gsoc]
---

Introduction
===========

This week was spent investigating the runtime and debugging executables with gdb.
It was interesting in the sense that it provided me with some interesting
pieces of information. Without any further ado, let's present our findings:

## My findings

Before starting out playing with libpthread, and glibc, I wanted to make sure
that the goruntime behaved the way I believed it behaved, and make some further
assurances about the goruntime. These assurances had to do with the total number
of goroutines and the total number of machine threads at various checkpoints
in the language runtime.  

- The first thread in the program is initialised during `runtime_schedinit`.
- The number of m's (kernel threads) is dependent on the number of goroutines.
The runtime basically attempts to create an equal amount of m's to run the goroutines.
We can observe everytime a new goroutine is created, there is a number of calls
to initiate a new kernel thread.
- There are at least two kernel threads. One that supports the runtime (mainly the 
garbage collector) and one that executes the code of the go program.

There is only one small piece of code in the goruntime that creates some sort of
confusion for me, and that is the code for a new m initialisation. Let me first
present the code that confuses me:

{% highlight C %}

M*
runtime_newm(void)
{

    ...
	mp = runtime_mal(sizeof *mp);

    ...
	mcommoninit(mp);
	mp->g0 = runtime_malg(-1, nil, nil);

    ...
	if(pthread_attr_init(&attr) != 0)
		runtime_throw("pthread_attr_init");
	if(pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED) != 0)
		runtime_throw("pthread_attr_setdetachstate");

    ...
}
{% endhighlight %}

I purposely compacted the function for brevity, as it only serves as a demonstration for a point.
Now, my confusion lies in the line `mp->g0 = runtime_malg(-1, nil, nil)`. It is a piece of code
that allocates memory for a new goroutine. Now I am ok with that, **but** what I do not understand
is that new kernel threads (m's) are supposed to be pick and run a goroutine from the global 
goroutine pool - that is run an existing one, and not create a new one. Now, the `runtime_malg`
is given parameters that don't initialise a new goroutine properly, but still, new memory
is allocated for a new goroutine, and is returned to `mp->g0` from runtime_malg.

Assuming I have not misunderstood something, and I am not mistaken (which is kind of likely), 
this is behavior that could lead to a number of questions and/or problems. For instance,
what happens to the goroutine created by `runtime_malg`? Is it killed after the m is assigned
a new goroutine to execute? Is it parked on the goroutine global list? Is it just ignored?
Does it affect the runtime scheduler's goroutine count? This is the last thing I feel I wanna
clear out regarding gccgo's runtime.

## gdb

For this week, I also run the executables created by gccgo through gdb. It was a fertile attempt
that, most of the time, confirmed my findings in the goruntime. It also provided us with some
other nice pieces of information regarding the crashing of goroutines, but also left me with a 
question.

The code in question that I run through gdb is this:

{% highlight C %}
package main

import "fmt"

func say(s string) {
    for i := 0; i < 5; i++ {
        fmt.Println(s)
    }
}

func main() {
    fmt.Println("[!!] right before a go statement")
    go say("world")
    say ("hello")
}
{% endhighlight %}

Your very typical hello world like goroutine program. Now, setting a break point in main 
(not the program's main, that's `main.main`. `main` as far as the runtime is concerned is
 the runtime entry point, in `go-main.c`) and running it through gdb yields the following
results:

{% highlight sh %}
Breakpoint 1, main () at ../../../gcc_source/libgo/runtime/go-main.c:52
52 runtime_check ();
2:  __pthread_total = 1
1: runtime_sched.mcount = 0
(gdb) next
53 runtime_args (argc, (byte **) argv);
2: __pthread_total = 1
1: runtime_sched.mcount = 0
54 runtime_osinit ();
2: __pthread_total = 1
1: runtime_sched.mcount = 0
63: runtime_schedinit ();
2: __pthread_total = 1
1: runtime_sched.mcount = 1
{% endhighlight %}

Up until now, nothing unexpected. The kernel thread is registered with the runtime scheduler
during its initialisation process in `runtime_schedinit` and that' why the `runtime_sched.mcount`
is reported to be zero many times before schedinit is run.

{% highlight sh %}
68 __go_go (mainstart, NULL);
2: __pthread_total = 1
1: runtime_sched.mcount = 1
(gdb) display runtime_sched.gcount
3: runtime_sched.gcount = 0
{% endhighlight %}

That too is ok, because a new goroutine is registered with the scheduler during the call to
`__go_go`. Now I am gonna fast forward a bit, to a more interesting point.

{% highlight sh %}
...
[DEBUG] (in runtime_gogo) new goroutine's status is 2
[DEBUG] (in runtime_gogo) number of goroutines now is 2
[New Thread 629.30]

Program received SIGTRAP, Trace/breakpoint trap.
0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
3: runtime_sched.gcount = 2
2: __pthread_total = 2
1: runtime_sched.mcount = 2
(gdb) info threads
 Id   Target  Id       Frame
 6    Thread  629.30   0x08048eb7 in main.main () at goroutine.go:12
 5    Thread  629.29   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
*4    Thread  629.28   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
```
This is getting weird. I mean, libpthread is reporting that 2 threads are active,
but gdb reports that 3 are active. Anyway, let's continue:

```
[DEBUG] (in runtime_stoptheworld) stopped the garbage collector
[DEBUG] (in runtime_starttheworld) starting the garbage collector
[DEBUG] (in runtime_starttheworld) number of m's now is: 2
[DEBUG] (in runtime_starttheworld) [note] there is already one gc thread
[!!] right before a go statement

Program received signal SIGTRAP, Trace/breakpoint trap.
0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
3: runtime_sched.gcount = 2
2: __pthread_total = 2
1: runtime_sched.mcount = 2
(gdb) continue
... (output omitted by me for brevity)

[DEBUG] (in runtime_newm) Right before the call to pthread_create.
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid;
__mach_port_deallocate ((__mach_task_self + 0), ktid); ok; })' failed.
[New Thread 629.31]

Program received signal SIGABRT, Aborted.
0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
3: runtime_sched.gcount = 3
2: __pthread_total = 2
1: runtime_sched.mcount = 3
{% endhighlight %}

Oh my goodness. From a first glance, this seems to be a very serious inconsistency between libpthread and the goruntime.
At this point, the go scheduler reports 3 threads (3 registered threads, that means 
that flow of execution has passed `mcommoninit`, the kernel thread initialisation function
which also registers the kernel thread with the runtime_scheduler) whereas libpthread reports 2 threads.

**But WAIT! Where are you going? Things are about to get even more interesting!**

{% highlight sh %}
(gdb) info threads
 Id   Target  Id       Frame
 7    Thread  629.31   0x01f4da00 in entry_point () from /lib/i386-gnu/libpthread.so.0.3
 6    Thread  629.30   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
 5    Thread  629.29   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
*4    Thread  629.28   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
{% endhighlight %}

GDB reports 4 threads. Yes, 4 threads ladies and gentlemen. Now take a look closely.
3 threads are in the same frame, with the one with id 4 being the one currently executed.
And there is also a pattern. `0x01da48ec` is the value of the `eip` register for all 3 of them.

That's one thing that is for certain. Now I already have an idea. Why not change
the current thread to the one with id 7? I'm sold to the idea, let's do this:

{% highlight sh %}
(gdb) thread 7
[Switching to thread 7 (Thread 629.31)]
#0  0x01f4da00 in entry_point () from /lib/i386-gnu/libpthread.so.0.3
(gdb) continue
Continuing.

Program received signal SIGABRT, Aborted.
[Switching to Thread 629.28]
0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
3: runtime_sched.gcount = 3
2: __pthread_total = 2
1: runtime_sched.mcount = 3
(gdb) info threads
 Id   Target  Id       Frame
 7    Thread  629.31   0x01dc08b0 in ?? () from /lib/i386-gnu/libc.so.0.3
 6    Thread  629.30   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
 5    Thread  629.29   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
*4    Thread  629.28   0x01da48ec in ?? () from /lib/i386-gnu/libc.so.0.3
{% endhighlight %}

Damn. But I am curious. What's the next value to be executed?

{% highlight sh %}
(gdb) x/i $eip
=> 0x1da48ec: ret
{% endhighlight%}

And what is the next value to be executed for the thread with id 7?

{% highlight sh %}
(gdb) x/i $eip
=> 0x1dc08b0: call *%edx
{% endhighlight %}

# Conclusion

Apparently, there is still much debugging left to checkout what is really happening.
But we have got some leads in the right direction, that hopefully will lead us to 
finally finding out where the problem lies, and correct it.

Most importantly, in my immediate plans, before iI start playing around with libpthread
is to attempt the same debugging run on the same code, under linux (x86). Seeing as
go is clean on linux, it would provide some clues as to what the expected results 
should be, and where the execution differentiates substantially, a clue
that might be vital to finding the problem.
