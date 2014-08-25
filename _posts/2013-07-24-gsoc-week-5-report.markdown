---
layout: post
title: "GSOC: Week 5 report"
date: 2013-07-24 12:36
comments: false
categories: gsoc gcc golang
---

# A clue!

**So last week we were left with the compiler test logs and the build results logs that we had to go through to checkout what was the root cause of all these failures in the gccgo test results, and more importantly in the libgo tests.** So I went through the gccgo logs in search for a clue about why this may have happened. Here is the list of all the failures I compiled from the logs:

~~~

spawn [open ...]^M
doubleselect.x: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_s      elf_ + 0), ktid); ok; })' failed.
FAIL: go.test/test/chan/doubleselect.go execution,  -O2 -g

==========================================================

spawn [open ...]^M
nonblock.x: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_       + 0), ktid); ok; })' failed.
FAIL: go.test/test/chan/nonblock.go execution,  -O2 -g

==========================================================

Executing on host: /root/gcc_new/gccbuild/gcc/testsuite/go/../../gccgo -B/root/gcc_new/gccbuild/gcc/testsuite/go/../../  -fno-diagnostics-show-caret -fdiagnostics-color=never  -I/root/gcc_new/gccbuild/i68      6-unknown-gnu0.3/./libgo  -fsplit-stack -c  -o split_stack376.o split_stack376.c    (timeout = 300)
spawn /root/gcc_new/gccbuild/gcc/testsuite/go/../../gccgo -B/root/gcc_new/gccbuild/gcc/testsuite/go/../../ -fno-diagnostics-show-caret -fdiagnostics-color=never -I/root/gcc_new/gccbuild/i686-unknown-gnu0.      3/./libgo -fsplit-stack -c -o split_stack376.o split_stack376.c^M
cc1: error: '-fsplit-stack' currently only supported on GNU/Linux^M
cc1: error: '-fsplit-stack' is not supported by this compiler configuration^M
compiler exited with status 1
output is:
 cc1: error: '-fsplit-stack' currently only supported on GNU/Linux^M
 cc1: error: '-fsplit-stack' is not supported by this compiler configuration^M 

UNTESTED: go.test/test/chan/select2.go

==========================================================

Setting LD_LIBRARY_PATH to .:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:.:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:/root      /gcc_new/gccbuild/./gmp/.libs:/root/gcc_new/gccbuild/./prev-gmp/.libs:/root/gcc_new/gccbuild/./mpfr/.libs:/root/gcc_new/gccbuild/./prev-mpfr/.libs:/root/gcc_new/gccbuild/./mpc/.libs:/root/gcc_new/gccbuild      /./prev-mpc/.libs
spawn [open ...]^M
select3.x: ./pthread/../sysdeps/generic/sem-timedwait.c:50: __sem_timedwait_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate       ((__mach_task_self_ + 0), ktid); ok; })' failed.
Aborted
 
FAIL: go.test/test/chan/select3.go execution,  -O2 -g

==========================================================

Executing on host: /root/gcc_new/gccbuild/gcc/testsuite/go/../../gccgo -B/root/gcc_new/gccbuild/gcc/testsuite/go/../../ /root/gcc_new/gcc/gcc/testsuite/go.test/test/chan/select5.go  -fno-diagnostics-show-      caret -fdiagnostics-color=never  -I/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo  -O  -w  -pedantic-errors  -L/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo -L/root/gcc_new/gccbuild/i686-unknown-      gnu0.3/./libgo/.libs  -lm   -o select5.exe    (timeout = 300)
spawn /root/gcc_new/gccbuild/gcc/testsuite/go/../../gccgo -B/root/gcc_new/gccbuild/gcc/testsuite/go/../../ /root/gcc_new/gcc/gcc/testsuite/go.test/test/chan/select5.go -fno-diagnostics-show-caret -fdiagno      stics-color=never -I/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo -O -w -pedantic-errors -L/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo -L/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.lib      s -lm -o select5.exe^M
PASS: go.test/test/chan/select5.go -O (test for excess errors)
FAIL: go.test/test/chan/select5.go execution

==========================================================

Setting LD_LIBRARY_PATH to .:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:.:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:/root      /gcc_new/gccbuild/./gmp/.libs:/root/gcc_new/gccbuild/./prev-gmp/.libs:/root/gcc_new/gccbuild/./mpfr/.libs:/root/gcc_new/gccbuild/./prev-mpfr/.libs:/root/gcc_new/gccbuild/./mpc/.libs:/root/gcc_new/gccbuild      /./prev-mpc/.libs
spawn [open ...]^M
bug147.x: ./pthread/../sysdeps/generic/sem-timedwait.c:50: __sem_timedwait_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate       ((__mach_task_self_ + 0), ktid); ok; })' failed.
Aborted
 
FAIL: go.test/test/fixedbugs/bug147.go execution,  -O2 -g

=========================================================

Setting LD_LIBRARY_PATH to .:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:.:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:/root      /gcc_new/gccbuild/./gmp/.libs:/root/gcc_new/gccbuild/./prev-gmp/.libs:/root/gcc_new/gccbuild/./mpfr/.libs:/root/gcc_new/gccbuild/./prev-mpfr/.libs:/root/gcc_new/gccbuild/./mpc/.libs:/root/gcc_new/gccbuild      /./prev-mpc/.libs
spawn [open ...]^M
BUG: bug347: cannot find caller
Aborted
 
 
FAIL: go.test/test/fixedbugs/bug347.go execution,  -O0 -g

========================================================

Setting LD_LIBRARY_PATH to .:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:.:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:/root      /gcc_new/gccbuild/./gmp/.libs:/root/gcc_new/gccbuild/./prev-gmp/.libs:/root/gcc_new/gccbuild/./mpfr/.libs:/root/gcc_new/gccbuild/./prev-mpfr/.libs:/root/gcc_new/gccbuild/./mpc/.libs:/root/gcc_new/gccbuild      /./prev-mpc/.libs
spawn [open ...]^M
BUG: bug348: cannot find caller
panic: runtime error: invalid memory address or nil pointer dereference
[signal 0xb code=0x2 addr=0x0]
 
goroutine 1 [running]:
FAIL: go.test/test/fixedbugs/bug348.go execution,  -O0 -g

========================================================

Setting LD_LIBRARY_PATH to .:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:.:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:/root      /gcc_new/gccbuild/./gmp/.libs:/root/gcc_new/gccbuild/./prev-gmp/.libs:/root/gcc_new/gccbuild/./mpfr/.libs:/root/gcc_new/gccbuild/./prev-mpfr/.libs:/root/gcc_new/gccbuild/./mpc/.libs:/root/gcc_new/gccbuild      /./prev-mpc/.libs
spawn [open ...]^M
mallocfin.x: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self      _ + 0), ktid); ok; })' failed.
FAIL: go.test/test/mallocfin.go execution,  -O2 -g

=======================================================

Setting LD_LIBRARY_PATH to .:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:.:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:/root      /gcc_new/gccbuild/./gmp/.libs:/root/gcc_new/gccbuild/./prev-gmp/.libs:/root/gcc_new/gccbuild/./mpfr/.libs:/root/gcc_new/gccbuild/./prev-mpfr/.libs:/root/gcc_new/gccbuild/./mpc/.libs:/root/gcc_new/gccbuild      /./prev-mpc/.libs
spawn [open ...]^M
Aborted
 
 
FAIL: go.test/test/nil.go execution,  -O2 -g

======================================================

Setting LD_LIBRARY_PATH to .:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:.:/root/gcc_new/gccbuild/i686-unknown-gnu0.3/./libgo/.libs:/root/gcc_new/gccbuild/gcc:/root      /gcc_new/gccbuild/./gmp/.libs:/root/gcc_new/gccbuild/./prev-gmp/.libs:/root/gcc_new/gccbuild/./mpfr/.libs:/root/gcc_new/gccbuild/./prev-mpfr/.libs:/root/gcc_new/gccbuild/./mpc/.libs:/root/gcc_new/gccbuild      /./prev-mpc/.libs
spawn [open ...]^M
Aborted
 
 
FAIL: go.test/test/recover3.go execution,  -O2 -g

~~~
{:lang="shell"}

*See a pattern there?* Well certainly I do. In several occasions, the root cause for the fail is this:


~~~
Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate       ((__mach_task_self_ + 0), ktid); ok; })' failed.
~~~
{:lang="shell"}

Hmm... That's interesting. Let us go through the libgo results too.

~~~

Test Run By root on Fri Jul 12 17:56:44 UTC 2013
Native configuration is i686-unknown-gnu0.3

		=== libgo tests ===

a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 10005 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: bufio
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (10005) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 10637 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: bytes
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (10637) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 10757 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: errors
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (10757) - No such process
a.out: ./pthread/../sysdeps/generic/sem-timedwait.c:50: __sem_timedwait_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
Aborted


goroutine 1 [syscall]:
no stack trace available
FAIL: expvar
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (10886) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 11058 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: flag
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (11058) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 11475 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: fmt
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (11475) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 11584 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: html
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (11584) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 11747 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: image
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (11747) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 11999 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: io
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (11999) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 12116 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: log
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (12116) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 13107 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: math
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (13107) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 13271 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: mime
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (13271) - No such process
a.out: ./pthread/../sysdeps/generic/sem-timedwait.c:50: __sem_timedwait_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
Aborted


goroutine 1 [chan receive]:
a.out: ./pthread/../sysdeps/generic/sem-timedwait.c:50: __sem_timedwait_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
panic during panic
testing.RunTestsFAIL: net
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (14234) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 14699 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: os
timed out in gotest
../../../gcc/libgo/testsuite/gotest: line 484: kill: (14699) - No such process
a.out: ./pthread/pt-create.c:167: __pthread_create_internal: Assertion `({ mach_port_t ktid = __mach_thread_self (); int ok = thread->kernel_thread == ktid; __mach_port_deallocate ((__mach_task_self_ + 0), ktid); ok; })' failed.
../../../gcc/libgo/testsuite/gotest: line 486: 14860 Aborted                 ./a.out -test.short -test.timeout=${timeout}s "$@"
FAIL: path
timed out in gotest

...


runtest completed at Fri Jul 12 18:09:07 UTC 2013
~~~
{:lang="shell"}

That's certainly even more interesting. In case you haven't noticed, it's the same assertion that caused the failures in gccgo test suite. Let us find the offending code, shall we?


{% highlight C %}
/* Set the new thread's signal mask and set the pending signals to
     empty.  POSIX says: "The signal mask shall be inherited from the
     creating thread.  The set of signals pending for the new thread
     shall be empty."  If the currnet thread is not a pthread then we
     just inherit the process' sigmask.  */
  if (__pthread_num_threads == 1)
    err = sigprocmask (0, 0, &sigset);
  else
    err = __pthread_sigstate (_pthread_self (), 0, 0, &sigset, 0);
  assert_perror (err);
{% endhighlight %}


This seems to be the code that the logs point to. But no sign of the assertion. After discussing this issue with my peers in #hurd, I was told that the code I was looking for (the failing assertion), is getting inlined via ``` _pthread_self () ``` and is actually located in ``` libpthread/sysdeps/mach/hurd/pt-sysdep.h ```. 


{% highlight C %}
extern __thread struct __pthread *___pthread_self;
#define _pthread_self()                                            \
	({                                                         \
	  struct __pthread *thread;                                \
	                                                           \
	  assert (__pthread_threads);                              \
	  thread = ___pthread_self;                                \
	                                                           \
	  assert (thread);                                         \
	  assert (({ mach_port_t ktid = __mach_thread_self ();     \
                     int ok = thread->kernel_thread == ktid;       \
                     __mach_port_deallocate (__mach_task_self (), ktid);\
                     ok; }));                                      \
          thread;                                                  \
         })
{% endhighlight %}


So this is what I was looking for. Further discussing it in the weekly IRC meeting, braunr provided me with some more clues:

> 08:38:15 braunr> nlightnfotis: did i answer that ?  
> 08:38:24 nlightnfotis> braunr: which one?  
> 08:38:30 nlightnfotis> hello btw :)  
> 08:38:33 braunr> the problems you're seeing are the pthread resources leaks i've been trying to fix lately  
> 08:38:58 braunr> they're not only leaks  
> 08:39:08 braunr> creation and destruction are buggy   
> 08:39:37 nlightnfotis> I have read so in http://www.gnu.org/software/hurd/libpthread.html. I believe it's under Thread's Death right?  
> 08:40:15 braunr> nlightnfotis: yes but it's buggy  
> 08:40:22 braunr> and the description doesn't describe the bugs  
> 08:41:02 nlightnfotis> so we will either have to find a temporary workaround, or better yet work on a fix, right?  
> 08:41:12 braunr> nlightnfotis: i also told you the work around  
> 08:41:16 braunr> nlightnfotis: create a thread pool  

# Work for next week

This leaves us with next week's work, which is to hack in libpthread's code to attempt to create a thread pool, so that we avoid some of the issues that are present now with the current implementation of the Hurd libpthread code. 

It was also suggested by Samuel Thibault (youpi) that I should run the libgo tests by hand and see if I get some more clues, like stack traces. It sounds like a good idea to me, so that's something that I will look into too.
