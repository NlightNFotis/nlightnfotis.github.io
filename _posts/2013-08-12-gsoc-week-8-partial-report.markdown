---
layout: post
title: "GSOC Week 8 (Partial) report"
date: 2013-08-12 10:27
comments: false
tags: [gsoc, golang, gcc]
---


This week was spent studying the go language's runtime and studying the behaviour of various go programs when executed under the Hurd. I learnt a variety of new things, and got some 
new clues about the problem.

## The new libgo clues

I already know that *M's are the "real" kernel schedulable threads* and *G's are the go runtime managed ones (goroutines)*. Last time I had gone through the go runtime's code I had noticed that neither of them get created, so there must be an issue with thread creation. **But since there is at least one of each created during the program's initialization, how come
most programs are able to run, and issues present themselves when we manually attempt to run a goroutine?**

I will admit that the situation looks strange. So I decided to look more into it. Before we go any further, I have to embed the issues I had when I run goroutine powered programs under the Hurd.

~~~
root@debian:~/Software/Experiments/go# ./a.out
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid;
__mach_port_deallocate ((__mach_task_self + 0), ktid); ok; })' failed.
Aborted
~~~
{:lang="shell"}

`__pthread_create_internal` is a libpthread function that gets called when a new posix thread is instanciated. So we know that when we call a goroutine, apart from the goroutine,
there is at least one kernel thread created, otherwise, if a new goroutine was created, and not a new kernel thread (M) why wasn't it matched with an existing kernel thread
(remember there is at least one).

That made me look into the go runtime some more. I found a lot of things, that I can not enumerate here, but amongst the most interesting ones, was the following piece of code:

{% highlight C %}

// Create a new m.  It will start off with a call to runtime_mstart.
M*
runtime_newm(void)
{
	M *mp;
	pthread_attr_t attr;
	pthread_t tid;
	size_t stacksize;
	sigset_t clear;
	sigset_t old;
	int ret;

#if 0
	static const Type *mtype;  // The Go type M
	if(mtype == nil) {
		Eface e;
		runtime_gc_m_ptr(&e);
		mtype = ((const PtrType*)e.__type_descriptor)->__element_type;
	}
#endif

	mp = runtime_mal(sizeof *mp);
	mcommoninit(mp);
	mp->g0 = runtime_malg(-1, nil, nil);

	if(pthread_attr_init(&attr) != 0)
		runtime_throw("pthread_attr_init");
	if(pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED) != 0)
		runtime_throw("pthread_attr_setdetachstate");

	stacksize = PTHREAD_STACK_MIN;

	// With glibc before version 2.16 the static TLS size is taken
	// out of the stack size, and we get an error or a crash if
	// there is not enough stack space left.  Add it back in if we
	// can, in case the program uses a lot of TLS space.  FIXME:
	// This can be disabled in glibc 2.16 and later, if the bug is
	// indeed fixed then.
	stacksize += tlssize;

	if(pthread_attr_setstacksize(&attr, stacksize) != 0)
		runtime_throw("pthread_attr_setstacksize");

	// Block signals during pthread_create so that the new thread
	// starts with signals disabled.  It will enable them in minit.
	sigfillset(&clear);

#ifdef SIGTRAP
	// Blocking SIGTRAP reportedly breaks gdb on Alpha GNU/Linux.
	sigdelset(&clear, SIGTRAP);
#endif

	sigemptyset(&old);
	sigprocmask(SIG_BLOCK, &clear, &old);
	ret = pthread_create(&tid, &attr, runtime_mstart, mp);
	sigprocmask(SIG_SETMASK, &old, nil);

	if (ret != 0)
		runtime_throw("pthread_create");

	return mp;
}
{% endhighlight %}

This is the code that creates a new kernel thread. Notice the line `ret = pthread_create(&tid, &attr, runtime_mstart, mp);`. It's obvious that it creates a new kernel thread,
so that explains why we get the specific error. But what is not explained is that since we do have at least one in program startup, why is this specific error only triggered when
we manually create a go routine?

## Go programs under the Hurd

Apart from studying Go's runtime source code, I also run some experiments under the Hurd. I got some very weird results that I am investigating, but I would like to share nonetheless.
Consider the following piece of code:

{% highlight go %}
package main

import "fmt"

func say(s string) {
    for i := 0; i < 5; i++ {
        fmt.Println(s)
    }
}

func main() {
    say("world")
    say("hello")
}
{% endhighlight %}

A very basic example that can demonstrate goroutines. Now, if we change **one** of the say functions inside main to a goroutine, this happens:

~~~
root@debian:~/Software/Experiments/go# ./a.out
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid;
__mach_port_deallocate ((__mach_task_self + 0), ktid); ok; })' failed.
Aborted
~~~
{:lang="shell"}

**BUT** if we change **BOTH** of these functions to goroutines (`go say("world")`, `go say("hello")`), this happens:

{% highlight sh %}
root@debian:~/Software/Experiments/go# ./a.out
root@debian:~/Software/Experiments/go# 
{% endhighlight %}

Wait a minute. It can't be! Did it execute correctly? Where is the output? 

{% highlight sh %}
root@debian:~/Software/Experiments/go# echo $?
0
root@debian:~/Software/Experiments/go#
{% endhighlight %}

It reports that it has executed correctly. But there is no output.

## What I am doing next

I will continue reading through the go runtime for some clues. On the more active size, I am writing a custom test case for goroutine testing under the Hurd, while also doing some analysis
on the programs that run there (currently studying the assembly generated for these programs) to see how they differ and why we get this particular behavior.
