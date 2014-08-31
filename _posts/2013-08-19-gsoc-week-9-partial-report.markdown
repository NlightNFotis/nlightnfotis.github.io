---
layout: post
title: "GSOC Week 9 (Partial) report"
date: 2013-08-19 11:35
comments: false
tags: [gcc, golang, gsoc]
---

This week was revolving around the print debugging in the gccgo runtime in search
for clues regarding the creation of new threads under the goruntime, so as to see
if there is something wrong with the runtime itself, or the way the runtime 
interacts with the libpthread.

## (partial presentation of) findings

During print debugging the gccgo runtime, I didn't notice anything abnormal or 
unusual so far. For example, the code that does trigger the assertion failure
seems to work at least once, since `pthread_create()` returns `0` at least once.

This is expected behavior, since we already have stated that there is at least
one `M` (kernel thread) created at the initialisation of the program's runtime.

If however, we try to use a *go statement* in our program, to make usage of a 
goroutine, the runtime still fails at the usual assertion fail, however the 
output of the program is this:

~~~
root@debian:~/Software/Experiments/go# ./a.out
[DEBUG] pthread_create returned 0
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid;
__mach_port_deallocate ((__mach_task_self + 0), ktid); ok; })' failed.
Aborted
~~~
{:lang="shell"}

The above output can give us some pieces of information:

* `pthread_create()` is called at least once.
* it executes successfuly and without errors - libpthread code suggests that 0 is returned upon successful execution and creation of a thread
* However the assertion is still triggered, which we know it's getting triggered during thread creation.

The second bullet point is also being supported by the fact that even if you exe
cute something as simple as hello world in go, a new M is created, so you get
something along the lines of this as an output:

{% highlight sh  %}
root@debian:~/Software/Experiments/go# ./a.out
[DEBUG] pthread_create returned 0
Hello World!
root@debian:~/Software/Experiments/go#
{% endhighlight %}

There is however something that the above piece of code doesn't tell us, 
but it would be useful to know: *How many times did we create a new thread?*
So we modify our gcc's source code to see how many times the runtimes 
attempts to create a new kernel thread (M). This is what we get out of it:

~~~
root@debian:~/Software/Experiments/go# ./a.out
[DEBUG] Preparing to create a new thread.
[DEBUG] pthread_create returned 0
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid;
__mach_port_deallocate ((__mach_task_self + 0), ktid); ok; })' failed.
[DEBUG] Preparing to create a new thread.
aborted.
~~~
{:lang="shell"}

The code at this point in the runtime is this:

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

	// XXX: Added by fotis for print debugging.
	printf("[DEBUG] Preparing to create a new thread.\n")

	mp = runtime_mal(sizeof *mp);
	mcommoninit(mp);
	mp->g0 = runtime_malg(-1, nil, nil);

	if(pthread_attr_init(&attr) != 0)
		runtime_throw("pthread_attr_init");
	if(pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED) != 0)
		runtime_throw("pthread_attr_setdetachstate");

	// <http://www.gnu.org/software/hurd/open_issues/libpthread_set_stack_size.html>
#ifdef __GNU__
	stacksize = StackMin;
#else
	stacksize = PTHREAD_STACK_MIN;

	// With glibc before version 2.16 the static TLS size is taken
	// out of the stack size, and we get an error or a crash if
	// there is not enough stack space left.  Add it back in if we
	// can, in case the program uses a lot of TLS space.  FIXME:
	// This can be disabled in glibc 2.16 and later, if the bug is
	// indeed fixed then.
	stacksize += tlssize;
#endif

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

	/* XXX: added for debug printing */
	printf("[DEBUG] pthread_create() returned %d\n", ret);

	sigprocmask(SIG_SETMASK, &old, nil);

	if (ret != 0)
		runtime_throw("pthread_create");

	return mp;
}
{% endhighlight %}

We can deduce two things about our situation right now:

* There is **at least one** thread successfully created, and there is an attempt
to create another one.
* The second time, there is a failure before pthread_create is called.

## Continuation of work.

I have been following this course of path the last week. I presented
some of my findings, and hope to soon be able to write an exhaustive
report on what exactly it is that causes the bug.
