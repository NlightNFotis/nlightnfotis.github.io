---
layout: post
title: "A Couple of Mental Models to Help Us Tackle Software Complexity"
date: 2022-06-12
tags: mental-models software-design
---

Have you ever started designing your software while doing your best to keep the design
clean and simple, and still came up with a tangled mess? Read on for a small number of
mental models that might help you avoid this next time.

---

## Everything's in your head: A small introduction to Mental Models

Excited yet? Me too.

But before we go on further with our discussion, let me introduce an appropriate definition
for *Mental Models*, just to make sure that we are all in the same page.

*Mental models*, as their name suggests, are abstract mental representations of a wide variety of
topics. On a daily basis, we use mental models for everything: how we understand certain
events that happen around us, how we expect a certain object or the environment to respond
in our interactions with it, and a lot of other things.

For more reading on Mental Models, I refer you to the excellent guide by [Farnam Street](https://fs.blog/mental-models/#what_are_mental_models),
which played a large part in popularising the idea of mental models.

### Mental models and programming

In programming (and computer science, more generally) mental models are everywhere.
Sometimes they are explicit (for instance, [*Models of Computation*](https://en.wikipedia.org/wiki/Model_of_computation)
are abstract representations of how humans or machines can perform a computation).
Other times, less so.

As an example, your knowledge of your favourite programming language is really a
just a model of it. Think of Python - you don't really *know* Python.

Now, I can already picture you recoiling in disbelief. "How is that possible?",
you ask. There's something in your head that allows you to write programs
in Python, so my claim looks ridiculous upon surface examination.

Not so fast - I didn't finish 😁 .

You don't *know* Python - but what you do have in your head are two (partially?)
complete mental models of Python: a mental model for its syntax, and a mental
model for its semantics. You may also have mental models of the behaviour of
certain Python tools. You might also be very familiar with a number of different
libraries (e.g. `requests`), at which point you may have a very robust mental
model of its behaviour or the internal mechanisms that drive that behaviour.
You get the point.

## Our first model: The Function as an (Invisible) Machine

In the two most well established models of computation the smallest unit of code
organisation is the **function**.

We software engineers deal with the abstract - we design software (write functions),
but for the most part, we see the end result of the computation they perform and
not much more. You can think of a function as an ethereal object (I stole this analogy
from [*Structure and Interpretation of Computer Programs*](https://mitpress.mit.edu/sites/default/files/sicp/full-text/book/book-Z-H-9.html),
where the authors compare it to an "abstract being that inhabit computers").

If we take the previous analogy, and ground it a bit into the more concrete idea
space, we can think of the function as the ethereal equivalent of *a machine*. It's
really the digital equivalent of the machines other engineers are dealing with:
our machines have some *inputs* and are comprised of a different number of *components*,
the interplay of which produces *outputs*.

(This view aligns very well with ideas from the field of *Software Engineering* as well.)

If we admit that the analogy holds, then we are met with some pretty interesting implications.
For example, our ethereal machines share the following properties with concrete machines:

* Complexity,
* Failure modes,
* Interfaces,
* Etc.

### Simple machines - Complex Machines

I'm going to stray away from computers for a moment so that I can make a point.

Think of a simple machine, say a *Bicycle*. A bicycle has some components (say,
it has a frame, tires, pedals, a handlebar, etc.) and performs a function,
namely, getting you from point A to point B.

There are other machines that are functionally equivalent from a high-level
standpoint, for example a *motocross bike*. These machines however are lot more
complex: they possess a greater number of components and features a greater number
of interactions between these components.

(Now, of course, the *motocross bike* offers functionality not present on the
*bicycle*, but that is beside the point I'm trying to make here.)

It should not be that much of a logical leap that the more complex machine
(with many more components and interactions) has more failure points than
the simpler machine. Not only that, but in the case of the simpler machine,
it takes less knowledge and effort to fix any failures.

Let's hold that thought for a bit while we have a look at the second mental
model I wanted to talk about and go on to see how these two interplay with
each other.

## Bounded Rationality

Enough talk about the machines - let's now have a look at the human side of all this:
we are all affected by a cognitive bias known as *Bounded Rationality*.

*Bounded rationality* is effectively a £10 word for describing the phenomenon of
some cognitive limitations, such as:

* the lack of perfect information,
* the limited capacity of our [short term memory](https://www.simplypsychology.org/short-term-memory.html),
* the collapse of long-winded reasoning processes under a time limit or an informational
  overload,
* the interplay between other cognitive biases, etc,

negatively affecting our decision making process. The way the do that is by shifting
our decision making priority to be that of *satisficing* instead of *optimising*.

This means that instead of going for the best solution in the current context,
we just go with the first one that seemingly satisfies the constraints that are
obvious to us at the moment.

You will see bounded rationality being discussed in different contexts. It is, however,
especially prevalent in behavioural economics (the field of study combining economics
and psychology), and cognitive science. The concept is more general, though, and is
relevant in any context that entails decision making.

When it comes to us, for the purposes of this article, we care about how bounded
rationality affects us when we design software, and this is what we're going to
be focusing on from now on onwards.

### Bounded Rationality and Software Design

At this point, an astute reader should be able to see where I am going with this:

> A function should be as simple as possible so that we can avoid the pitfalls
> associated with cognitive limitations on our end.

You may have seen software design guidelines before that look like this:

* "Limit the number of parameters a function accepts to less than 5"
* "Do not use global variables"
* "Use preconditions and postconditions"
* "Obey the [Law of Demeter](https://en.wikipedia.org/wiki/Law_of_Demeter)"
* ...

All of these, from a high level standpoint, aim to narrow down the *size of
the set* of components and interactions of our function - our (invisible) machine.

Indeed, programming languages today include a number of features (static manifest typing,
lexical scope, etc) that limit the input, range of states and behaviour that our code
can find itself in.

This has a number of benefits relating to software correctness (as the compiler
enforces these constraints) but the biggest one is probably that it frees up
our mental capacity by making the function simpler. A smaller design space for
that function means less things that can cause us to throw our hands up and start
*satisficing*, and also less things that can go wrong or need fixing when we inevitably
make a mistake.

## Conclusion

I hope that my small essay convinced you about the need to make functions as small
as possible (but not smaller 😁 ).

If you want a TL/DR of the whole article, it boils down to this:

> The simpler your software design, the less likely your cognitive limitations are
> going to negatively affect it.
