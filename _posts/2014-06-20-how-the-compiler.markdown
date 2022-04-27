---
layout: post
title: "How the Compiler, the Library and the Kernel work - Part 3"
date: 2014-06-20 20:49
comments: true
tags: [compiler, kernel, libc]
share: true
---

In the last part of this series, we talked about the compiler's composition, including the assembler
and the linker. We showed what happens when the compiler runs, and what's the output
of translation software such as `cc1` or `as` etc. In this final part of the series, we are going
to talk about the C library, how our programs interface with it, and how it interfaces with 
the kernel.

# The C Standard Library

The C Standard Library is pretty much a part of every UNIX like operating system. It's basically
a collection of code, including functions, macros, type definitions etc, in order to provide facilities
such as string handling (`string.h`), mathematical computations (`math.h`), input and output
(`stdio.h`), etc.

GNU/Linux operating systems are generally using the [GNU C Library implementation(GLIBC)](http://www.gnu.org/software/libc/libc.html),
but it's common to find other C libraries being used (especially in embedded systems) such as 
[uClibC](http://www.uclibc.org), [newlib](http://sources.redhat.com/newlib), or in the case
of Android/Linux systems [Bionic](https://android.googlesource.com/platform/bionic.git).
BSD style operating systems usually have their own implementation of a C library.

## So, how does one "use" the C Standard Library?

So, now that we are acquainted with the C Library, how do you make use of it, you ask? The answer is:
**automagically** :). Hold on right there; that's not exactly a hyperbole. You see, when you
write a basic C program, you usually `#include <some_header.h>` and then continue with
using the code declared in that header. We have explained in the previous part of this series
that when we use a function, say `printf()`, in reality it's the linker that does the hard work 
and allows us to use this function, by linking our program against the `libc`'s `so` (shared 
object). So in essence, when you need to use the C Standard Library, you just `#include`
headers that belong to it, and the linker will resolve the references to the code included.

Apart from the functions that are defined in the Standards however, a C Library might also
implement further functionality. For example, the Standards don't say anything about networking.
As a matter of fact, most libraries today may implement not only what's in the C Standards,
but may also choose to comply with the requirements of the POSIX C library, which is a superset
of the C Standard library.

## Ok, and how does the C Library manage to provide these services?

The answer to this question is simple: Some of the services that the library provides, it does so
without needing any sort of special privileges, being normal, userspace C code, while others
need to ask the Operating's system Kernel to provide these facilities for the library.

How does it do so? By calling some functions exported by the kernel to provide certain functionality
 named **system calls**. System calls are the fundamental interface between a userspace
application and the Operating System Kernel. For example consider this:

You might have a program that has code like this at one point: `fd = open("log.txt", "w+");`. That
`open` function is provided by the C Library, but the C Library itself can not execute all of the
functionality that's required to open a file, so it may call a `sys_open()` system call that will
ask the kernel to do what's required to load the file. In this case we say that the library's `open`
call acts as a wrapper function of the system call.

# Epilogue

In this final part of our series, we saw how our applications interface with the C Standard Library
available in our system, and how the Library itself interfaces with the Operating system kernel
to provide the required services needed by the userspace applications.

## Further Reading:

If you want to take a look at the System Call interface in the Linux Operating System, you could
always see the [man page for the Linux system calls](http://man7.org/linux/man-pages/man2/syscalls.2.html)
