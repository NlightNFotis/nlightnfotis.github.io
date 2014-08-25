---
layout: post
title: "Introduction to xv6: Adding a new system call."
date: 2014-04-28 18:24
comments: true
tags: [kernel, ensidia, xv6]
share: true
---

# xv6: An introduction

If you are like me, a low level pc programmer, it's hard not to have heard
of **xv6**. [xv6](http://pdos.csail.mit.edu/6.828/2012/xv6.html), for those
who haven't really heard of it, is a *UNIX version 6* clone, designed
at MIT to help teach operating systems. 

The reasoning behind doing this was fairly simple: [Up until that point, MIT
had used John Lions' famous commentary on the Sixth Edition of UNIX](http://www.lemis.com/grog/Documentation/Lions/). But V6 was challenging due to a 
number of reasons. To begin with, it was written in a near ancient version
of C (pre K&R), and apart from that, it contained PDP-11 assembly
(a legendary machine for us UNIX lovers, but ancient nonetheless), which
didn't really help the students that had to study both PDP-11 and the
(more common) x86 architecture to develop another (exokernel) operating
system on. 

So, to make things much more simpler, professors there decided to 
roll with a clone of UNIX version 6, that was x86 specific, 
written in ANSI C and supported multiprocessor machines.

For a student (or a programmer interested in operating systems), xv6 is 
a unique opportunity to introduce himself to kernel hacking and to the
architecture of UNIX like systems. At about 15k lines of code (iirc), 
including the (primitive) libraries, the userland and the kernel,
it's very easy (or well, at least easier than production scale UNIX like
systems) to grok, and it's also very easy to expand on. It also helps
tremendously that xv6 as a whole has magnificent documentation, not only
from MIT, but from other universities that have adopted xv6 for use in their
operating systems syllabus.

## An introduction to Ensidia: my very personal xv6 fork

When I first discovered xv6 I was ecstatic. For the reasons mentioned above
I couldn't lose on the opportunity to fork xv6 and use it as a personal
testbed for anything I could feel like exploring or testing out.

As a matter of fact, when I first discovered xv6, [I had just finished 
implementing (the base of) my own UNIX like operating system, named fotix](https://github.com/NlightNFotis/Fotix), 
and the timing of my discovery was great. xv6 had done what I had done,
and also implemented most of what I was planning to work on fotix
(for example, elf file loading), and it was a solid base for further 
development. It also had a userland, which fotix at the time didn't have.

After I forked xv6, I spent some time familiriazing myself with the code.
I also cleaned up the source code quite a bit, structuring the code in a 
BSD like folder structure, instead of having all of the code in the same 
folder and made various small scale changes. 

After that for quite some time, I had left ensidia alone and didn't touch
it much. However, I always felt like I wanted to develop it a bit more
and get to play with its code in interesting ways. I was trying to think of
a great way to get started with kernel hacking on it, in a simple way, to 
get more acquainted with the kernel, and found an interesting pdf with 
interesting project ideas for it. One of them was to add a system call.
I figured out that would be an interesting and quick hack, so hey, why not?

# Getting started with kernel hacking on xv6: Adding the system call.

The system call I decided to introduce was the suggested one. It was
fairly simple sounding too. You have to **introduce a new system call
that returns the number of total system calls that have taken place
so far**. So let's see how I went about implementing it:

## An introduction to system calls in xv6

First of all, we should provide some context about what system calls are,
how they are used, and how they are implemented in xv6.

A system call is a function that a userspace application will use, so as
to ask for a specific service to be provided by the operating system. For
instance with an `sbrk(n)` system call, a process can ask the kernel to
grow its heap space by n bytes. Another example is the well known `fork()`
system call in the UNIX world, that's used to create a new process by 
cloning the caller process.

The way applications signal the kernel that they need that service is
by issueing a software *interrupt*. An *interrupt* is a signal generated
that notifies the processor that it needs to stop what its currently doing,
and handle the interrupt. This mechanism is also used to notify the processor
that information it was seeking from the disks is in some buffer, ready to
be extracted and processed, or, that a key was pressed in the keyboard. This
is called a hardware interrupt.

Before the processor stops to handle the interrupt generated, it needs to 
save the current state, so that it can resume the execution in this context
after the interrupt has been handled. 

The code that calls a system call in xv6 looks like this:

{% highlight gas  %}
# exec(init, argv)
 .globl start
 start:
   pushl $argv
   pushl $init
   pushl $0  // where caller pc would be
   movl $SYS_exec, %eax
   int $T_SYSCALL
{% endhighlight %}

In essence, it pushes the argument of the call to the stack, and puts
the system call number (in the above code, that's `$SYS_exec`) into `%eax`.
The number is used to match the entry in an array that holds pointers to
all the system calls. After that, it generates a software interrupt, with
a code (in this case `$T_SYSCALL`) that's used to index the interrupt
descriptor tables and find the appropriate interrupt handler. 

The code that is specific to find the appropriate interrupt handler is
called `trap()` and is available in the file `trap.c`. If `trap()` check's
out the trapnumber in the generated trapframe (a structure that represents
the processor's state at the time that the trap happened) to be equal to
`T_SYSCALL`, it calls `syscall()` (the software interrupt handler)
 that's available in `syscall.c`

{% highlight C %}
// This is the part of trap that
// calls syscall()
void
trap(struct trapframe *tf)
{
  if(tf->trapno == T_SYSCALL){
    if(proc->killed)
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
  }
{% endhighlight %}

`syscall()` is finally the function that checks out `%eax` to get the 
number of the system call (to index the array with the system 
call pointers), and execute the code corresponding to that system call.

The implementation of system calls in xv6 is under two files. The first one
is `sysproc.c`, and is the one containing the implementation of system calls
correspondent to processes, and `sysfile.c` that contains the implementation
of system calls regarding the file system.

## The specific implementation of the `numcalls()` system call

To implement the system call itself is simple. I did so with a global variable
in `syscall.c` called `syscallnum`, that's incremented everytime 
`syscall()`, calls a system call function, that is, the system call
is valid.

Next we just need a function, the system call implementation that returns
that number to the userspace program that asks for it. Below is the 
function itself, and `syscall()` after our change.

{% highlight C %}
// return the number of system calls that have taken place in
// the system
int
sys_numcalls(void)
{
    return syscallnum;
}
{% endhighlight %}

{% highlight C %}
// The syscall() implementation after
// our change
void
syscall(void)
{
  int num;

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    syscallnum++; // increment the syscall counter
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
  }
}
{% endhighlight %}

After that was done, the next few things that were needed to be done
were fairly straight forward. We had to add an index number for the new
system call in `syscall.h`, expose it to user proccesses via `user.h`,
and add a new macro to `usys.S` that defines an asm routine that calls
that specific system call, and change the makefile to facilitate our change
. After doing so we had to write a userspace testing program to test our changes.

The result after doing all this is below :)

{% highlight sh %}
cpu1: starting
cpu0: starting
init: starting sh
$ ls
.              1 1 512
..             1 1 512
README         2 2 2209
cat            2 3 9725
echo           2 4 9254
forktest       2 5 5986
grep           2 6 10873
init           2 7 9579
kill           2 8 9246
ln             2 9 9240
ls             2 10 10832
mkdir          2 11 9315
rm             2 12 9308
sh             2 13 16600
stressfs       2 14 9790
usertests      2 15 37633
wc             2 16 10207
zombie         2 17 9028
syscallnum     2 18 9144
console        3 19 0
$ syscallnum
The total number of syscalls so far is 643
$ syscallnum
The total number of syscalls so far is 705
$ syscallnum
The total number of syscalls so far is 767
$ syscallnum
The total number of syscalls so far is 829
{% endhighlight %}


# Epilogue

I usually end my blog posts with an epilogue. Although this is a post
that doesn't necesarilly need one, **I wanted to write one just to say to you
that you should try kernel hacking**, *that is programming jargon for
programming an operating system kernel*, because it's an experience that
undoubtedly will teach you a great deal of things about how your computer
actually works.

Last but not least, take a look at the ongoing work on [Ensidia, my fork
of xv6](https://github.com/NlightNFotis/Ensidia). To see this particular
work, take a look at the `syscall` branch.

## References
 * [CS422/522: Operating systems, Yale](http://zoo.cs.yale.edu/classes/cs422/2010/reference)
 * [Chapter 8, File System calls, xv6 reference, Yale](http://zoo.cs.yale.edu/classes/cs422/2010/xv6-book/fscall.pdf)
 * [Chapter 3, System calls, exceptions and interrupts, Yale](http://zoo.cs.yale.edu/classes/cs422/2010/xv6-book/trap.pdf)
 * [xv6 Documentation, MIT csail](http://pdos.csail.mit.edu/6.828/2012/xv6/book-rev7.pdf)
