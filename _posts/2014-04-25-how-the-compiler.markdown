---
layout: post
title: "How the compiler, the Library and the Kernel work - Part 2 "
date: 2014-04-25 18:27
comments: true
tags: [compiler, kernel, libc]
share: true
---

In the previous part of this little series, we talked about the compiler, and what it does 
with the header files, in our attempt to demistify their usage. In this part, I want to show you
what's the compiler's output, and how we create our file.

# The compiler's composition

Generally speaking, a *compiler* belongs to a family of software called **translators**. 
A translator's job is to read some source code in a source language, and generate (translate it to) 
some source code in a target language.

Now, you might think that most compilers you know don't do that. You input a (source code) file, 
and you get a binary file, ready to run when you want it to. Yes that's what it does, but it's not
the compiler that does all this. If you remember from the last installment of this series,
when you call the compiler like `gcc some_file.c` or `clang some_file.c`, in essence you are
calling the compilation driver, with the file as a parameter. The compilation driver then calls
1) the preprocessor, 2) the (actual) compiler, 3) the assembler and last but not least the linker.
At least when it comes to gcc, these pieces of software are called `cpp`, `cc1`, 
`gas` (executable name is `as`)  and `collect2` (executable name is `ld`) respectively.

From that little software collection up top, that we call the compiler, we can easily take notice
of at least 3 (yeah, that's right) translators, that act as we mentioned earlier, 
that is take some input in a source language, and produce some output to a target language.

The first is the preprocessor. The preprocessor accepts source code in C as a source language,
and produces source code again in C (as a target language), but with the output having various
elements of the source code resolved, such as header file inclusion, macro expansion, etc.

The second is the compiler. The compiler accepts (in our case) C source code, as a source language,
and translates it to some architecture's assembly language. In my case, when I talk about the 
compiler, I'm gonna assume that it produces x86 assembly.

The last one, is the assembler, which accepts as input some machine's architecture assembly
language, and produces what's called binary, or object representation of it, that is it translates
the assembly mnemonics directly to the bytes they correspond to, in the target architecture.

At this point, one could also argue that the linker is also a translator, accepting binary, and 
translating it to an executable file, that is, resolving references, and fitting the binary code
on the segments of the file that is to be produced. For example, on a typical GNU/Linux system,
this phase produces the executable ELF file.

# The (actual) compiler's output: x86 assembly.

Before we go any further, I would like to show you what the compiler really creates:

For the typical hello world program we demonstrated in our first installment, the compiler
will output the following assembly code:

{% highlight gas %}
	.file	"hello.c"
	.section	.rodata
.LC0:
	.string	"Hello world!"
	.text
	.globl	main
	.type	main, @function
main:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	movl	%edi, -4(%rbp)
	movq	%rsi, -16(%rbp)
	movl	$.LC0, %edi
	call	puts
	movl	$0, %eax
	leave
	ret
	.size	main, .-main
	.ident	"GCC: (GNU) 4.8.2 20131212 (Red Hat 4.8.2-7)"
	.section	.note.GNU-stack,"",@progbits
{% endhighlight %}

To produce the above file, we had to use the following gcc invocation command:
`gcc -S -fno-asynchronous-unwind-tables -o hello.S hello.c`. 
We used `-fno-asynchronous-unwind-tables` to remove `.cfi` directives, which tell `gas` 
(the gnu assembler) to emit Dwarf Call Frame Information tags, which are used to reconstruct
a stack backtrace when a frame pointer is missing.

For more usefull compilation flags, to control the intermediary compilation flow, try these:

 * `-E`: stop after preprocessing, and produce a *.i file
 * `-S`: we used this, stop after the compiler, and produce a *.s file
 * `-c`: stop after the assembler, and produce a *.o file.

The default behaviour is to use none, and stop after the linker has run. If you want to run a 
full compilation and keep all the intermediate files, use the `-save-temps` flag.

# From source to binary: the assembler.

The next part of the compilation process, is the assembler. We have already discussed what
the assembler does, so here we are going to see it in practice. If you have followed so far,
you should have two files, a `hello.c`, which is the hello world's C source code file,
and a `hello.S` which is what we created earlier, the compiler's (x86) assembly output.

The assembler operates on that last file as you can imagine, and to see it running, and emit
binary, we need to invoke it like this: `as -o hello.bin hello.S`, and produces this:

~~~
ELF\00\00\00\00\00\00\00\00\00\00>\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F0\00\00\00\00\00\00\00\00\00\00\00@\00\00\00\00\00@\00\00\00UH\89\E5H\83\EC\89}\FCH\89u\F0\BF\00\00\00\00\E8\00\00\00\00\B8\00\00\00\00\C9\C3Hello world!\00\00GCC: (GNU) 4.8.2 20131212 (Red Hat 4.8.2-7)\00\00.symtab\00.strtab\00.shstrtab\00.rela.text\00.data\00.bss\00.rodata\00.comment\00.note.GNU-stack\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00 \00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00@\00\00\00\00\00\00\00 \00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\B8\00\00\00\00\00\000\00\00\00\00\00\00\00	\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00&\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00`\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00,\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00`\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\001\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00`\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\009\00\00\00\00\00\000\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00m\00\00\00\00\00\00\00-\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00B\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\9A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\9A\00\00\00\00\00\00\00R\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\B0\00\00\00\00\00\00\F0\00\00\00\00\00\00\00
\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00	\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\A0\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F1\FF\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00	\00\00\00\00\00\00\00\00\00\00\00\00\00 \00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00hello.c\00main\00puts\00\00\00\00\00\00\00\00\00\00\00\00\00
\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00	\00\00\00\FC\FF\FF\FF\FF\FF\FF\FF
~~~

# Last but not least: the linker

We saw what the assembler emits, which is to say, binary code. However, that binary code
still needs further processing. To explain that, we need to go back a little.

In our first installment of the series, we said that when you call a function like `printf()`,
the compiler only needs its prototype to do type checking and ensure that you use it legally.
For that you include the header file `stdio.h`. But since that contains the function prototype only,
where is the source code for that function? Surely, it must be somewhere, since it executes 
successfully to begin with, but we haven't met the source code for printf so far, so where is it?

The function's source code is located in the `.so` (shared object) of the standard C library,
which in my system (Fedora 19, x64) is `libc-2.17.so`. I don't want to expand on that further,
as I plan to do so on the next series installment, however, what we have said so far is enough
for you to understand the linker's usage:

The linker resolves the undefined (thus far) reference to printf, by finding the reference to
the printf symbol and (in layman's talk) 
making a pointer to point to it so that execution can jump to printf's code
when we have to do that during our program's execution.

To invoke the linker on our file, [at least according to it's documentation](https://sourceware.org/binutils/docs-2.20/ld/Options.html#Options), 
we should do the following: `ld -o hello.out /lib/crt0.o hello.bin -lc`. Then we should
be able to run the file like this: `./hello.out`.

# Epilogue

That's this end of this part 2 of my series that explains how your code turns into binary, and how
your computer (at least when it comes to the software side) runs it. In part 3, I am going to discuss
in greater length, the C library, and the kernel.

## References

 * [StackOverflow: What is .cfi and .LFE in assembly code produced by GCC from c++ program?](http://stackoverflow.com/questions/3564752/what-is-cfi-and-lfe-in-assembly-code-produced-by-gcc-from-c-program)
 * [GCC front-end (1): driver vs. compiler](http://blog.lxgcc.net/?p=181)
 * [GAS](http://wiki.osdev.org/GAS)
 * [ ld: Binutils documentation](https://sourceware.org/binutils/docs-2.20/ld/)
