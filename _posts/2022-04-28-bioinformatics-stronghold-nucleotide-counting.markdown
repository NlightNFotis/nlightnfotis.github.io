---
layout: post
title: "Nucleotide Counting the TDD Way - A Bioinformatics Stronghold Story"
date: 2022-03-28 18:04
comments: false
tags: [ruby, bioinformatics, tdd]
---

A few days ago, I was going through my code archives and came across my old solutions
of the [Bioinformatics Stronghold](https://rosalind.info/problems/list-view/) by
[Project Rosalind](https://rosalind.info/problems/locations/). For those of you who
don't know, *Project Rosalind* is one of those problem-based skill development exercises,
akin to [Project Euler](https://projecteuler.net) but aimed at nascent bioinformaticians.

Coincidentally, I finished a [book on Test-Driven Development (TDD) in Ruby](https://www.goodreads.com/book/show/33527186-test-driven-development-in-ruby)
around the same time. I particularly enjoyed TDD the way it was presented in
the book, and I was looking for some problems to apply it to and the Stronghold
Project is the perfect lab space for me to apply those new ideas (because of
its relatively simple from an algorithmic perspective problems).

---

My initial foray into the Stronghold project was in an attempt at comparative solutions,
wherein I attempted the exercises in a number of different programming languages
(Python, Go, OCaml, Racket, etc.) while observing any differences in the style I
chose, refactoring them, benchmarking them, and all around having some good fun
with those 😄

One thing I'm embarrassed to admit about that first attempt though, is that while
my solutions worked (or so I can conveniently recall), they didn't contain any
reproducible documentation of their satisfying of the requirements of the
exercise - there were no assertions, no tests, nothing. 😅 I can only attribute it
to my enthusiasm in getting each solution done to move on to the next one.

Bad me.

I'm now revisiting these exercises to atone for my insolence. I'm going to go through
the exercises again, but this time I'm going to be approaching them in a TDD/BDD style.

But before I move on to actual code, what on Earth is TDD (and its cousin, BDD)? We
already saw that *TDD* stands for *Test-Driven Development*. By that, we mean a
programming approach that encourages writing tests for the feature code **before**
the actual feature code is written, so that the tests guide the design of the code
itself.

*Behaviour-Driven Development* (BDD for short), is a sister approach to TDD, but for
the purposes of this article, BDD is the approach of *writing the tests in a way
that they reflect prose specification of the behaviour of the module* under test.

Okay, are you ready now? Let's roll.

---

I'm going to start with the [first exercise](https://rosalind.info/problems/dna/),
which is about counting nucleotides in a DNA strand, which is given as an input of
a `string` type.

Now, if you visit the problem page, you will see that it also gives us a sample
dataset, along with the expected output for that.

(You may have noticed that the above sentence is just a particularly verbose way
of describing a *test case*. 😉 )

Our implementation language for this exercise is going to be Ruby, for two reasons.

1) I started learning Ruby recently and I've been enjoying it a lot, and
2) Ruby comes with excellent built-in support for testing in the form of the `Minitest`
   library.

Let's quickly make a file called `counting_nucleotides.rb`, and add an empty test
specification:

```rb
require 'minitest/autorun'

describe 'nucleotide counting function' do
end
```

At this point it's worth having a pause to think about our test cases before we move
forward.

We already have been given a sample input, as we mentioned above, that we could use
as our test case. The problem, however, with that particular input is that it describes
the functionality of the module when it's finished.

That's probably a bit *too* elaborate for us to use now that we start designing our
function.

We probably want something much simpler - indeed, this is what TDD as an approach
is advocating. What might be simpler for us?

What about a strand with a very small length? Say, 8 bases long?

Sounds like it *should* work.

```rb
require 'minitest/autorun'

describe 'nucleotide counting function' do
  it 'returns a count of 2 2 2 2 for strand "ATCGATCG"' do
    strand = 'ATCGATCG'
    nucleotide_count = '2 2 2 2'
    result = count_nucleotides(strand)

    assert_equal nucleotide_count, result
  end
end
```

Looks good for a first test. Let's run it and see what happens.

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 64068

# Running:

E

Finished in 0.000265s, 3773.5860 runs/s, 0.0000 assertions/s.

  1) Error:
nucleotide counting function#test_0001_returns a count of 2 2 2 2 for strand "ATCGATCG":
NoMethodError: undefined method `count_nucleotides' for #<#<Class:0x000000015e831da0>:0x000000015b940028>
    counting_nucleotides.rb:8:in `block (2 levels) in <main>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips
```

Ahh, it complains that we "forgot" to define our function `count_nucleotides`.
Easy to fix, let's add a function called that, taking in one parameter, but
with an empty body.

```rb
require 'minitest/autorun'

def count_nucleotides(strand)
end

describe 'nucleotide counting function' do
  it 'returns a count of 2 2 2 2 for strand "ATCGATCG"' do
    strand = 'ATCGATCG'
    nucleotide_count = '2 2 2 2'
    result = count_nucleotides(strand)

    assert_equal nucleotide_count, result
  end
end
```

Nice, let's run it again, and see what we get.

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 20901

# Running:

F

Finished in 0.000287s, 3484.3209 runs/s, 3484.3209 assertions/s.

  1) Failure:
nucleotide counting function#test_0001_returns a count of 2 2 2 2 for strand "ATCGATCG" [counting_nucleotides.rb:12]:
Expected: "2 2 2 2"
  Actual: nil

1 runs, 1 assertions, 1 failures, 0 errors, 0 skips
```

Okay, this seems a bit more intriguing. Now it doesn't come back to us with an **error**.
Rather, it comes back with a **failure**, indicating that the test got executed,
but the expected and the actual results differ. In our case, we asserted in our test
that we expect the result to be a string with the contents `"2 2 2 2"` in exactly
that form (spaces and everything), but we got back `nil` from the actual execution.

The reason for the `nil` in particular is that ruby is an *expression-based language*.

In an expression-based language every program fragment is an *expression*, meaning
that it will return a value upon execution of that program fragment (we call that,
in more technical terms, *expression evaluation*).

A function, thus, is also an expression, and will upon evaluation return the value
of the last expression in its body. For a function with an empty body, there are no
such expressions, so a default of `nil` is returned.

---

Right, so we run our test, and got back `nil` for a return value. This is our clue
that our test is executing the function as we expect, but our function is not yet
implemented (does not contain a function body). Let's crack on with that.

In Ruby, there's a very convenient method defined on the `String` type whose job
is to count the presence of particular subsequences (substrings in our case).

To no one's suprise, it's called `count`.

Let's use that to count the number of nucleotides and return that in a string format.

```rb
def count_nucleotides(strand)
    strand.count('A') + strand.count('C') + strand.count('G') + strand.count('T')
end
```

Let's run our test again.

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 3996

# Running:

F

Finished in 0.000411s, 2433.0901 runs/s, 2433.0901 assertions/s.

  1) Failure:
nucleotide counting function#test_0001_returns a count of 2 2 2 2 for strand "ATCGATCG" [counting_nucleotides.rb:13]:
Expected: "2 2 2 2"
  Actual: 8

1 runs, 1 assertions, 1 failures, 0 errors, 0 skips
```

Whoops!

That looks like it found the number of substrings correctly. However, because
of a programming mistake, it looks like it added all the occurences together,
instead of presenting them in a formatted string.

Let's do that in the easiest way that comes to mind - using string concatenation
and casting the `integer` representing the count back to a `string`, while also
adding some spaces (so that we get closer to the expected output):

```rb
def count_nucleotides(strand)
    strand.count('A').to_s + " " + strand.count('C').to_s + " " + strand.count('G').to_s + " " + strand.count('T').to_s
end
```

Let's see what happens now...

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 37259

# Running:

.

Finished in 0.000321s, 3115.2648 runs/s, 3115.2648 assertions/s.

1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

It worked! I mean, our code ~~is a bit atrocious~~ could be better, but here
we have our first version of it working. 🎉

---

Now that we have our first unit test passing, let's think a bit more about
the test cases we want.

We want at least a representative sample of each of the following:

* Positive cases,
* Negative cases,
* Degenerate cases.

*Positive cases* are cases in which we exercise the *happy path* - the code path we
were most anticipating when we were designing our code.

*Negative cases* are cases in which we divert away from the happy path, and
try to exercise error conditions, etc.

*Degenerate cases* are cases in which we test around boundary conditions, such as
empty lists, strings, etc, to see if our function can handle these cases.

We already have a test for a positive case, so right now, it might make more sense
for us to test against a negative case. So what would be a negative case for us?

We are being passed a strand in as a `string`. Given that a `string` can have a
lot more characters than just the four representing nucleobases, what happens if we
have a string that has characters that don't represent a nucleotide base? What happens
if we have something like `ATCGW` for a `strand`? Let's see.

```rb
it 'throws an exception if a non-base encoding character is found in the strand' do
    strand = 'ATCGW'
    
    assert_raises(ArgumentError) { count_nucleotides(strand) }
  end
```

Let's run it to see what happened this time.

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 54524

# Running:

.F

Finished in 0.000506s, 3952.5692 runs/s, 3952.5692 assertions/s.

  1) Failure:
nucleotide counting function#test_0002_throws an exception if a non-base encoding character is found in the strand [counting_nucleotides.rb:19]:
ArgumentError expected but nothing was raised.

2 runs, 2 assertions, 1 failures, 0 errors, 0 skips
```

😱

Yikes! We were expecting an exception to be raised, but none was raised.
That means that our code had no issue handling the invalid string. Let's fix that.

Let's fix that the simplest way we can: by defining a list of illegal characters
for the strand string and seeing if they are present in the string.

That gets us with the following version of `count_nucleotides`:

```rb
def count_nucleotides(strand)
    illegal_chars = 'BDEFHIJKLNOPQRSUVWXYZ'
    illegal_chars.split('').each do |char|
        if strand.include?(char) then
            raise ArgumentError.new('Illegal character in strand ' + char)
        end
    end
    strand.count('A').to_s + " " + strand.count('C').to_s + " " + strand.count('G').to_s + " " + strand.count('T').to_s
end
```

Let's see where we stand now:

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 25460

# Running:

..

Finished in 0.000348s, 5747.1265 runs/s, 5747.1265 assertions/s.

2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

Nice. That works, so now both our positive case and our negative test cases pass.

The only downside is that we are left with a `counting_nucleotides` function that
looks a bit hard to read - not to mention a bit wasteful, too.

(Aside: It loops through the string a lot more times than it needs to, as it loops
once per every illegal character it's looking for, and then once for every character
it's searching the count for.)

---

At this point, it's worth to pause, and reflect on where we are in the process so far.

TDD is a loop of the following 3 steps:

1. Write a *failing test*.
2. Make the test *pass*.
3. *Refactor* the implementation.

(Refactoring is the reorganisation of the code with the aim of improving it with
regard to some metric, say, robustness, readability, performance, etc)

Up until this point, we have been focusing on the first two steps, but did none
of the third one.

We usually refactor once we get some of our implementation done, and **all our
tests are passing**.

In other words, now is as good time as any to refactor our code.

---

Let's have a look at our feature code, the `count_nucleotides` function.

What if, instead of looping so many times, we looped just once, and collected
both counts and watched out for any illegal character at the same time?

That does sound like it should improve our performance, now, doesn't it?

Let's go ahead and do this, and see what happens.

```rb
def count_nucleotides(strand)
    count_a = 0
    count_t = 0
    count_c = 0
    count_g = 0

    strand.split('').each do |base|
        if base == 'A' then
            count_a += 1
        elsif base == 'T' then
            count_t += 1
        elsif base == 'C' then
            count_c += 1
        elsif base == 'G' then
            count_g += 1
        else
            raise ArgumentError.new('Invalid character in strand ' + base)
        end
    end

    "#{count_a} #{count_t} #{count_c} #{count_g}"
end
```

Looks simpler to me. Does it work, though?

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 48449

# Running:

..

Finished in 0.000378s, 5291.0053 runs/s, 5291.0053 assertions/s.

2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

It does.

And just like this, we saw the massive benefit of having automated tests for this:
we did some pretty significant *structural changes* to our function under test,
but even so, we are confident that its observable behaviour remains unchanged
given our tests and their coverage.

---

Now that we have both the positive and negative tests, can we write a test for
the degenerate case?

Turns out we can.

A degenerate case for us would be an **empty string** (`""`), given that we anticipate
the `strand` to exist (signified by a non-empty string).

Before we go ahead and write our test case, let's have a bit of a think around
the behaviour of our function in the case of an empty string. Should it:

1. Return a count of `0 0 0 0`, or
2. Raise an exception?

Usually, in situations like this, a decision like this already forms part of
our specification - but in our case, though, the exercise contains no indication
as to what is considered canonical, so we can choose either.

Let's go with expecting a count of `0 0 0 0` for this one (there don't appear to
be any significant benefits whichever one we choose).

```rb
it 'returns a count of 0 0 0 0 for a strand with zero bases (empty string)' do
    strand = ''
    nucleotide_count = '0 0 0 0'
    result = count_nucleotides(strand)

    assert_equal nucleotide_count, result
  end
```

Let's check our function's behaviour:

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 33926

# Running:

...

Finished in 0.000378s, 7936.5079 runs/s, 7936.5079 assertions/s.

3 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

Very nice.

---

Are we done, now?

Not so fast.

There's a requirement in our specification that we have ignored so far:

> Given: A DNA string s of length *at most 1000 nt*.

(Emphasis mine.)

Let's quickly add a test case with an invalid length (> 1000 nucleotides) to see
how our code behaves with against this requirement:

```rb
it 'throws an exception if a strand is more than 1000nt long' do
    strand = 'A' * 1005

    assert_raises(ArgumentError) { count_nucleotides(strand) }
end
```

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 15834

# Running:

...F

Finished in 0.000579s, 6908.4628 runs/s, 6908.4628 assertions/s.

  1) Failure:
nucleotide counting function#test_0004_throws an exception if a strand is more than 1000nt long [counting_nucleotides.rb:52]:
ArgumentError expected but nothing was raised.

4 runs, 4 assertions, 1 failures, 0 errors, 0 skips
```

The test fails, as we were anticipating an exception but none was raised.

Let's change our function to factor in this new requirement.

```rb
def count_nucleotides(strand)
    count_a = 0
    count_t = 0
    count_c = 0
    count_g = 0

    if strand.length > 1000 then
        raise ArgumentError.new('A strand of at most 1000nt is expected')
    end

    strand.split('').each do |base|
        if base == 'A' then
            count_a += 1
        elsif base == 'T' then
            count_t += 1
        elsif base == 'C' then
            count_c += 1
        elsif base == 'G' then
            count_g += 1
        else
            raise ArgumentError.new('Invalid character in strand ' + base)
        end
    end

    "#{count_a} #{count_t} #{count_c} #{count_g}"
end
```

Let's see how our test does now:

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 14091

# Running:

....

Finished in 0.000355s, 11267.6056 runs/s, 11267.6056 assertions/s.

4 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

Very nice. Everything passes now.

---

Before we wrap this up, let's make one final addition to our test case.

Do you remember how I mentioned that the exercise specification describes
a test case already?

We can incorporate this into our test cases. As a matter of fact, we can
substitute this one for the simpler positive case we had.

```rb
it 'returns a count of 20 12 17 21 for the specification strand' do
    strand = 'AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC'
    nucleotide_count = '20 12 17 21'
    result = count_nucleotides(strand)

    assert_equal nucleotide_count, result
  end
```

Let's see how we fare against the story test case (the one given to us in
the specification).

```sh
$ ruby counting_nucleotides.rb
Run options: --seed 17159

# Running:

.....

Finished in 0.000428s, 11682.2430 runs/s, 11682.2430 assertions/s.

5 runs, 5 assertions, 0 failures, 0 errors, 0 skips
```

Looks like everything works as expected. 🎉

---

Before I wrap up, I would be remiss if I did not mention that this particular
approach of designing code (*Test-Driven Development*) works very well when we
know the expected output of our code (say, when we know a lot about the domain,
or when our specification allows for examples that demonstrate expected input
and output).

It doesn't work as great, however, when we don't know what the output is (say,
for instance, when we do exploratory programming, as in the case of exploring
an API that's given to us).

The complete code for this small exercise is listed below:

```rb
require 'minitest/autorun'

## IMPLEMENTATION CODE

def count_nucleotides(strand)
    count_a = 0
    count_t = 0
    count_c = 0
    count_g = 0

    if strand.length > 1000 then
        raise ArgumentError.new('A strand of at most 1000nt is expected')
    end

    strand.split('').each do |base|
        if base == 'A' then
            count_a += 1
        elsif base == 'T' then
            count_t += 1
        elsif base == 'C' then
            count_c += 1
        elsif base == 'G' then
            count_g += 1
        else
            raise ArgumentError.new('Invalid character in strand ' + base)
        end
    end

    "#{count_a} #{count_c} #{count_g} #{count_t}"
end


## TEST CODE

describe 'nucleotide counting function' do
  # Positive case
  it 'returns a count of 20 12 17 21 for the specification strand' do
    strand = 'AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC'
    nucleotide_count = '20 12 17 21'
    result = count_nucleotides(strand)

    assert_equal nucleotide_count, result
  end

  # Negative cases
  it 'throws an exception if a non-base encoding character is found in the strand' do
    strand = 'ATCGW'
    
    assert_raises(ArgumentError) { count_nucleotides(strand) }
  end

  it 'throws an exception if a strand is more than 1000nt long' do
    strand = 'A' * 1005

    assert_raises(ArgumentError) { count_nucleotides(strand) }
  end

  # Degenerate cases
  it 'returns a count of 0 0 0 0 for a strand with zero bases (empty string)' do
    strand = ''
    nucleotide_count = '0 0 0 0'
    result = count_nucleotides(strand)

    assert_equal nucleotide_count, result
  end
end
```
