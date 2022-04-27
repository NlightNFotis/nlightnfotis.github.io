---
layout: post
title: "How the compiler, the Library and the kernel work - Part 1"
date: 2013-12-12 16:13
comments: true
tags: [compiler, kernel, libc]
share: true
---

Before we get any further, it might be good if we provided some context.

# Hello world. Again.

{% highlight C %}
#include <stdio.h>

int
main (int argc, char **argv)
{
    printf ("Hello world!\n");

    return 0;
}
{% endhighlight %}

Every user space (read: application) programmer, has written a hello world program. 
Only god knows how many times this program has been written. Yet, 
most programmers' knowledge of the program is limited to something along the lines of:

 > - It sends the string passed as a parameter to the system to print.  
 > - It takes the printf function from stdio.h and prints the string

and various other things, which are anywhere between plain wrong, or partially correct. 

** So why not demistify the process? **

# Enter the C preprocessor.

You may have heard of the C Preprocessor. It's the first stage of a c or c++ file compilation,
and it's actually responsible for things such as:

 * **inclusion of header files** (it does so by replacing
`#include <header.h>` with the content of this file, and the file it includes recursively),
 * **macro expansion**, such as the famous comparison of two numbers (a greater than b). In essence, if you define
 the following macro `#define gt(a, b) ((a > b) ? 1 : 0)`, then in a statement such as this:

~~~
 if (gt (5, 3)) printf ("The first parameter is greater than the second.\n");
~~~
{:lang="c"}

`gt (5, 3)` gets expanded to the macro definition, so after the preprocessor has run you end up with something like this:

~~~
 if (((5 > 3) ? 1 : 0)) printf ("The first parameter is greater than the second.\n");
~~~
{:lang="c"}

 * **conditional compilation** (things such as: 

{% highlight C %}
#ifdef WIN32 
    printf ("We are on windows\n"); 
#endif
{% endhighlight %}

amongst others. You can see it for yourself. Write the hello world program, and pass it to cpp: `cpp hello_world.c`

So now that we know what it does it's time to demistify a common myth regarding it: *Some people believe
that the header files include the function to be called.*. **That's wrong.** What it does include is 
**function prototypes** (and some type definitions, etc) **only**. It doesn't include the body of the function
to be called.

Some people find that fact quite surprising, though, it isn't, if you get to understand what the compiler
does with it.

# Say hello to the compiler.

Here we are gonna unmask another pile of misconceptions. First of all, some people think that when they call 
`gcc` on the command line they are actually calling the compiler. **They are not.** *In fact they are calling
the software commonly called **the compilation driver**, whose job is to run all the software needed to fully
turn source to binary, including preprocessors, the actual compiler, an assembler and finally the linker*

Having said that, the actual compiler that's getting called when you call `gcc` is called `cc1`. You may have seen it some times when the driver reports errors. Wanna take a look at it, to make sure I'm not lying to you? 
(Hint: I'm not!) Fair enough. Why don't you type this in the command line: `gcc -print-prog-name=cc1`. It should tell you where the actual compiler is located in your system.

So now that we have this (misconception) out of our minds, we can continue with our analysis. Last time we talked
about it, we said that the header files include **prototypes** and not the whole function.

You may know that in C, you usually declare a function, before you use it. The primary reason for doing this
is to provide the compiler with the ability to perform **type checking**, that is to check that the arguments
passed are correct, both in number, and in type, and to verify that the returned value (assuming there is one)
is being used correctly. Below is a program that demonstrates the function prototype:

{% highlight C %}
#include <stdio.h>

int add_nums (int first, int second);

int
main (void)
{
    printf ("5 + 5 results in %d\n", add_nums (5, 5));

    return 0;
}

int
add_nums (int first, int second)
{
    return first + second;
}
{% endhighlight %}

In this particular example, the prototype gives the compiler a wide variety of information. It tells it
that function `add_nums` takes two int arguments and returns an integer to the calling function. Now the
compiler can verify that I am passing correct arguments to it when I call it inside printf. If I don't include
the function prototype, and do something slightly evil such as calling `add_nums` with `float` arguments then 
this might happen:

~~~
5 + 4 results in 2054324224
~~~

Now that you know that the compiler (the real one) only needs the prototype and not the actual function code,
you may be wondering how the compiler actually compiles it if it doesn't know it's code.

Now is the time to bring down another missconception. The word *compiler* is just a fancy name for software
otherwise known as *translators*. A *translator's* job is to get input and turn it from one language (source language) to a second language (target language), whatever that may be. Most of the times, when you compile software,
you compile it to run in your computer, which runs on a processor from the x86 architecture family of processors.
A processor is typically associated with an assembly language for that architecture (which is just human friendly
mnemonics for common processor tasks), so your *x86 computer runs x86 assembly* (ok that's not 100% true, but for
simplicity's sake at the moment, it should serve. We will see why it's not true later.) So the compiler 
(in a typical translation) translates (compiles) your C source code to x86 assembly. 
You can see this by compiling your hello world example and passing the compiler the `-S` (which asks it to stop,
after x86 assembly is produced) parameter, likewise `gcc -S hello.c`.

# Conclusion

At this part, we saw how the compiler and the preprocessor work with our code, in an attempt to demistify the 
so called library calls. In the next part, we are going to study the assembler and the linker, and for the final
part the loader and the kernel.
