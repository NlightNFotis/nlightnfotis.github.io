---
layout: post
title: "GSOC: Week 6 report"
date: 2013-07-31 12:36
comments: false
tags: [gsoc, gcc, golang]
---

First of all, I would like to apologize for this report being late. But unfortunately this happened:
![I Accidentally 93 MB](http://i1.kym-cdn.com/photos/images/original/000/000/376/Accidentally93mb20110724-22047-ix1t06.png)

Only that, in my case, it was not exactly 93 MB, rather it was about 1.5GB. Yeah, *I accidentally obliterated my **GCC** repository on the Hurd*, so I had to reclone and rebuild everything, something that took considerable amounts of time. 
How this happened is a long story that involved me wanting to rebuild my gcc, and `cd`-ing 2 directories above the build folder, and ending up `rm -rf *` from my `gcc` folder (that included the source, and the build folder) rather than my `gcc_build` folder. 
Thank god, that was only a minor setback, and the (small scale) crisis was soon averted.


# Further research

This week was mostly spent reading source code, primarily looking for clues for the previous situation, and secondarily to get a better undestanding of the systems I am working on. This proved to be fertile, as I got a firmer grip of libpthread, and the GNU Mach system. However, while this week was mostly spent reading documentation, that doesn't mean that I didn't do anything practical. I also used my time to do some further research into what was it specifically that triggered the assertion failure. That required us to play a little bit with our newly built compiler on the Hurd and see what we can do with go on the Hurd.

## Testing gccgo under the Hurd


If you recall correctly, the last time I reported I had found out that an assertion on `libpthread`\`s code was failing, and that was the root cause that failed both the `gccgo` tests
and the `libgo` tests. That assertion was failing at two different places in the code, the first being `__pthread_create_internal` which is a `libpthread` function 
located in `libpthread/pthread/pt-create.c` and is invoked when an application wants to create a new POSIX thread. That function of course is not getting called directly, rather
it is invoked by `pthread_create` which is the function that user space application use to create the new thread. (For reference reasons you can find the code [here](https://github.com/NlightNFotis/libpthread/blob/master/pthread/pt-create.c#L67))

The second place where that assertion was failing was at `__sem_timedwait_internal` at the file [libpthread/sysdeps/generic/sem-timedwait.c](https://github.com/NlightNFotis/libpthread/blob/master/sysdeps/generic/sem-timedwait.c), where it gets inlined in the place of `self = _pthread_self ();`. (For more information, checkout last week's report).

So I was curious to test out the execution of some sample programs under the compiler we built on the Hurd. **Beginning with some very simple hello world like programs, we could see that
they were compiling successfully, and also ran successfully without any issues at all.** Seeing as the assertion failure is generated when we attempt to create a new thread, I figured I might want to start playing with go routines under the Hurd.

So we started playing with a simple hello world like goroutine example (the one available under the [tour of go on the golang.org website.](http://tour.golang.org/#62))


{% highlight C %}

package main

import (
    "fmt"
    "time"
)

func say(s string) {
    for i := 0; i < 5; i++ {
        time.Sleep(100 * time.Millisecond)
        fmt.Println(s)
    }
}

func main() {
    go say("world")
    say("hello")
}

{% endhighlight %}

This gets compiled without any issues at all, but when we try to run it...

{% highlight C %}
a.out: ./pthread/../sysdeps/generic/sem-timedwait.c:50: __sem_timedwait_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
Aborted


goroutine 1 [sleep]:
time.Sleep
	../../../gcc_source/libgo/runtime/time.goc:26

goroutine 3 [sleep]:
time.Sleep
	../../../gcc_source/libgo/runtime/time.goc:26
{% endhighlight %}

Bam! It exploded right infront of our face. Let's see if this might become friendlier if we alter it a little bit. To do this we removed the `go` from `say` to avoid running it as a goroutine, and we also removed `time.Sleep` (along with the `time` import), [whose job is to pause a go routine](https://github.com/NlightNFotis/gcc/blob/master/libgo/go/time/sleep.go#L8).

When you do this, the code seems to be a hello world like for loop sample, that prints:

~~~
root@debian:~/Software/Experiments/go# ./a.out
world
world
world
world
world
hello
hello
hello
hello
hello
~~~

Hmm. Let's play with it some more. Changing our code a little bit to make `say("world")` run as a goroutine gives us the following code:

{% highlight C %}
package main

import "fmt"

func say(s string) {
    for i := 0; i < 5; i++ {
        fmt.Println(s)
    }
}

func main() {
    go say("world")
    say("hello")
}
{% endhighlight %}

Which, when executed results in this:

~~~
root@debian:~/Software/Experiments/go# ./a.out
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid;
__mach_port_deallocate ((__mach_task_self + 0), ktid); ok; })' failed.
Aborted
~~~

So we can see that the simplest go programs that run with goroutines do not run. Let's still try some programs that invoke goroutines to see if our assumptions are correct.
Below is the code of a very simple web server in go ([found in the golang website](http://tour.golang.org/#56)).

{% highlight C %}

package main

import (
    "fmt"
    "net/http"
)

type Hello struct{}

func (h Hello) ServeHTTP(
    w http.ResponseWriter,
    r *http.Request) {
    fmt.Fprint(w, "Hello!")
}

func main() {
    var h Hello
    http.ListenAndServe("localhost:4000", h)
}
{% endhighlight %}

The (non surprising) result is the following:

~~~
a.out: ./pthread/../sysdeps/generic/sem-timedwait.c:50: __sem_timedwait_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
Aborted

goroutine 1 [syscall]:
no stack trace available
~~~

Hmm. This failure was last caused by `time.Sleep`. So let's take a closer look into the code of the `ListenAndServe` function. The code for this function in the go runtime is this:

{% highlight C %}

// ListenAndServe listens on the TCP network address srv.Addr and then
// calls Serve to handle requests on incoming connections.  If
// srv.Addr is blank, ":http" is used.
func (srv *Server) ListenAndServe() error {
	addr := srv.Addr
	if addr == "" {
		addr = ":http"
	}
	l, e := net.Listen("tcp", addr)
	if e != nil {
		return e
	}
	return srv.Serve(l)
}
{% endhighlight %}

This calls the function [`Serve`](https://github.com/NlightNFotis/gcc/blob/master/libgo/go/net/http/server.go#L1255). The interesting part in this one is line 1271:

~~~

 time.Sleep(tempDelay)

~~~

It calls `time.Sleep` on accept failure. Which is known to pause go routines, and as a result be the ultimate cause for the result we are seeing.

# Final thoughts - Work for next week

So pretty much everything that has anything to do with a goroutine is failing. Richard Braun on the #hurd suggested that since **creation and destruction** of threads is buggy in libpthread, maybe we should try a work around until a proper fix is in place. 
Apart from that my mentor Thomas Schwinge suggested to make thread destruction in go's runtime a no-op to see if that makes any difference. 
If it does that should mean that there is nothing wrong in the go runtime itself, rather, the offending code is in libpthread. This is also my very next course of action, which I shall report on very soon.