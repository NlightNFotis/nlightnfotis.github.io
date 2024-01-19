---
layout: post
title: "How to Think About And Use the Option And Result Types"
date: 2023-12-16
tags: types rust go c++ haskell
---

This post is written with an aim to provide some clarity as to the purpose and
usage of the (evermore present) types `Option` and `Result` in various programming
languages.

---

## The Beginning: the `bool` type

We're all used to using the `bool` type: its value set has cardinality `2`, basically
admitting two values:

* `true`, and
* `false`.

This means that we can use it as a return type for a function to discriminate
between two outcomes from the function's execution. Thus, it ties well with
predicates (functions answering a decision problem, e.g. `isDiscountValid`
or `any?`) and, more broadly, functions that want to indicate a *successful* outcome
or a *failure* outcome after their execution has finished.

The return of a `bool`-typed value allows these functions to have great synergy
with conditional statements/expressions, directly plugging into the *antecedent*
(condition) part of a conditional statement. Undoubtedly, you've come across
something like this (in C-like pseudocode):

```c++
bool do_something() {
    // --snip--
    if (something_went_wrong) { // signal failure
        return false;
    }

    // all went right in the main path
    return true;
}

int main() {
    // --snip---

    if (do_something()) {
        printf("Operation was successful!\n");
    } else {
        // perform some logging, or error recover here...
    }
}
```

This... works. But it's a fairly rudimentary mechanism, with a significant limitation:
*what happens if we want to pass along some information in either case*?

This is a thought that has crossed many a programmer's mind, and different languages
have provided different solutions to this problem, depending on whether the language
allows for **one** or **more** return values. Solutions fall within the following
general criteria:

* Return a value if successful and `null`/`nil`/`None` otherwise.
* Nest the `bool` and the `value` in a `struct`/`class` and return that.
* Return a single `bool` value and extra values in *out-parameters*.
* Allow the return of `tuple`s containing the values.
* `Option`/`Result`/`Either`.

Let's have a quick look at some examples. For each of the below examples, imagine
that our use case is the following:

> We have a function which searches a rich document (think like a Word document)
> for a particular search text.

This is also called a "needle-in-haystack search".

### Return a value if successful and `null` otherwise

This was pretty much the default way people handled this situation in Algol-family
languages (C, C++, Java, etc.), especially in the past. It would look something
like the following (in Java-like pseudocode):

```java
public class Document {
    // --snip--

    class SearchResult {
        int column;
        int line;
    }

    public SearchResult searchText(String needle) {
        // --snip --
        if (found) {
            return SearchResult(column, found);
        } else {
            return null;
        }
    }
}
```

The approach was fairly similar in C and C++, where instead of `null` someone
might see `return NULL;` or the more modern `return nullptr;` in the case of C++.

This approach came with a major, ***major*** flaw, one that has even been given
its own nickname across the industry, by its own creator (Sir Tony Hoare) nonetheless:
[the billion-dollar mistake](https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/).

The problem is that the return value is usually then perused in a way that gets
dereferenced (either directly, through a pointer, like in C and C++ or indirectly
through objects in Java/C#, etc), causing the program to crash with either a friendly
error message or <s> an occult incantation out of Saruman's grimoire</s> a less descriptive
error message, depending on how well-behaved the language runtime you're using is:

```
// In Java

Exception in thread "main" java.lang.NullPointerException
    at Printer.printString(Printer.java:13)
    at Printer.print(Printer.java:9)
    at Printer.main(Printer.java:19)

// In C/C++

[1]    93157 segmentation fault  ./a.out
```

The computer **really** doesn't like it when you force it to go to address `0x00`,
you see. But...

### Nest the value and the `bool` in a `class` and return that

Seeing as we're very sensitive to the computer's plight (and our own inconvenience
and embarrassment), we might as well try to find a different way: one that, at least,
doesn't result in a crash.

One way to solve the above problem, especially in the past, would be to wrap both
the `bool` and the return value (in the successful case) in a single compound type
(a `class`), and return values of that type. It would look something like the following.

Assume that our string-search function has been programmed to return a `SearchResult`
type of the following form:

```c++
struct SearchResult {
    bool success;
    int column;     // present only if text was found
    int line;       // ditto
};
```

Objects of that type would use the `success` sub-component as a discriminating
value, indicating on whether the search yielded a successful match or not. The
rest of the sub-components (`column` and `line`) would have well-defined values
if the `success` is `true`, and undefined otherwise.

Thus, our function might look something like this:

```c++
SearchResult search_text(const std::string& subtext, const Document& doc) {
    // --snip--
    
    if(found) {
        return {true, column_no, line_no};
    } else {
        return {false, random(), random()}; // random to simulate undefined value
    }
};
```

Now, if we wanted to use our `search_text` function, being the responsible programmers
we are, we would first check the `success` field:

```c++
void perform_action() {
    // --snip--

    const auto result = search_text("the jabberwocky", alice_in_wonderland);
    if (result.success) {
        printf("Found at line %d and column %d\n", result.line, result.column);
    } else { // !result.success 
        printf("Unable to find given text within the document.");
    }
}
```

This is definitely a solution, and one that was adopted in various codebases I've
seen in the past, but it also suffers from a flaw, albeit a less severe one this
time: the pollution of the codebase with many similar but *oh-so-slightly-different*
types which served only as "rich-return-typed objects".

This has the side-effect of an increase in the cognitive load of the programmer,
which makes the experience of programming in that codebase a bit worse than it
needs to be: the editors and other tools might help, but you still need to mentally
keep track of which function returns what, and have some special handling around
any of those.

### Out-parameters

This one is a variation of the two themes above, falling somewhat in the middle:
it still signals success and makes it harder (kinda...) to crash the application.
This time around, our code would look similar to this (in Cpp-like pseudocode):

```c++
// Our SearchResult object
struct SearchResult {
    int column;
    int line;
};

// And the search function
bool search_text(const std::string& needle, const Document& haystack, SearchResult& result) {
    // --snip--
    
    if(found) {
        result = SearchResult{column_no, line_no}; 
        return true;
    } else {
        return false;
    }
};

// With our usage looking like this:

void perform_action() {
    // --snip--

    auto result = SearchResult{}; 

    const auto found = search_text("the jabberwocky", alice_in_wonderland, &result);
    if (found) {
        printf("Found at line %d and column %d\n", result.line, result.column);
    } else { // !found 
        printf("Unable to find given text within the document.");
    }
}
```

This, again, also works. It's a fine solution for many people (given how widespread
out-parameters are) and enjoys a good performance profile because of the pointers/references,
but I personally heavily dislike it from an aesthetics/philosophical standpoint:

> A function should only ever return its return value and nothing else.

What can I say? I'm a functional-programming kind of guy.

### Allow the return of a tuple containing the values

If we use the above quote as an axiom for our programming system, we kind of
find ourselves in a bind: we both want to return a `bool`, and a secondary value
based on the value of the `bool` itself.

Or are we?

For programming languages that only allow one return value, we can look into
packing our `bool` and the auxiliary value into a `pair` or an `n-tuple` (its
arity-based generalisation).

This used to be harder, but nowadays most programming languages offer more
mathematical primitives in their standard libraries.

For example, adapting our example above to something like Kotlin:

```kotlin
fun searchText(needle: String, haystack: Document): Pair<Boolean, SearchResult> {
    // --snip--

    if (found) {
        return Pair(true, SearchResult(column, line))
    } else {
        return Pair(false, SearchResult())
    }
}
```

And for our usage, this time around:

```kotlin
val result = searchText("The Queen of Hearts", aliceInWonderland);
if (result.first) {
    println("Found The Queen of Hearts at ${result.second}")
}
```

There are also some languages that allow you to return multiple values in their
base syntax (internally, they might do packing/unpacking automatically to achieve
an effect very similar to the above). Of these, perhaps Go is the most famous one,
using this as an idiom for error handling:

```go
import "errors"

func example_function(arg int) (int, error) {
    if arg == 42 {
        return -1, errors.New("can't work with 42")
    }

    return arg + 3, nil
}

func main() {
    result, err := example_function(42);
    if err != nil {
        // Log or do some error handling here
    }
}
```

## `Option`/`Result`/`Either`

Wow. What a trip. Let's have a quick recap so we can review where we've been so
far:

* We started with a function doing something, and returning `true` or `false` to
  show whether it succeeded or not.
* Our requirements evolved to now also need some extra information *in addition*
  to the above `true`/`false` values.
* We explored a number of different ways to satisfy that new requirement.

But all of them were a bit lacking, in various different ways:

* They... allowed us to crash, either by accident or by misuse of their interface.
* They didn't provide enough context to the compiler to assist us with development
  (and to provide guard rails *against* misuse), using pattern matching for instance.
* They depended on the creation of other context-sensitive, non-uniform types.
* They fallback to using types (e.g. `Pair` or `Triple`) that lack specificity
  to guide our expectations and intuition to a specific context.

All of the above are solved by the `Option` and `Result` type (and its more general
dual in Haskell, `Either`).

All of them are what's known in Programming Language Theory as *Sum Types* (sometimes
called *Discriminated Unions*), due to the fact that the value set of the compound
type is the *sum* of the *cardinality* of the *sets* of the *atomic types* (called
constructors) that comprise them.

The type definitions look like these (in an ML-like pseudocode):

```fsharp
type Option<T> =
  | Some<T>
  | None

type Result<T, E> =
  | Ok<T>
  | Err<E>

type Either<L, R> =
  | Left<L>
  | Right<R>
```

All of the above are generic types, admitting generic parameters (the `T`, `E`s,
etc.).

(At this point, it's worth observing that `Either` is isomorphic to `Result`, so
from now on onwards, what we mention for `Result` will apply to `Either` as well,
without the need to explicitly say so).

---

An interesting pattern arises if we also provide a type definition for a `Boolean`
type in the same pseudo syntax:

```fsharp
type Boolean =
  | True
  | False
```

If we also remove the generic parameters from the above type definitions (just
for illustration purposes) and lay them all next to each other, we're going to
observe that their value sets their definitions are identical (with only different
*names* for the various constructors):

```fsharp
type Boolean =
  | True
  | False

type Option =
  | Some
  | None

type Result =
  | Ok
  | Err
```

Wow! This near-identical (isomorphic) form is also a hint that their *semantics*
are also very similar. Let's try to put the generic parameters (but as comment
for a clarity) and see how we do:

```fsharp
type Boolean =
  | True
  | False

type Option =
  | Some -- with extra information
  | None

type Result =
  | Ok  -- with extra information
  | Err -- with extra information
```

A clear pattern now emerges! All of these signal the same sort of binary outcome,
with the capability of also carrying extra information.

Nice! The keen-eyed amongst you will have noticed that this insight has now solved
our original problem in a very clean way, and has at the same time provided a very
clear usage guideline:

* Use `Boolean` whenever you only need to discriminate between two outcomes.
* Use `Option` whenever you want to do the above, but also want to carry extra
  information around in the `True` case.
* Use `Result` whenever you want to discriminate between two outcomes but also
  want to carry extra information around in both of these cases.

Let's have a look at some examples in Rust to see how we would choose which one
to use in practice. Let's have a look at 3 different cases:

```rust
struct Person {
    age: u8,
}

impl Person {
    // A Person can either drink (is of legal age) or not.
    // True or false. No other information needed.
    fn can_drink() -> bool {
        age >= 18
    }
}
```

In the above case we see an example of a *predicate* (a function returning `true`/`false`,
in effect solving a decision problem). Boolean values work very well for predicates:
we only want the first order value - it's either `true` or `false`, but we don't
care why in either case.

Let's now have a look at a case where we might care about extra information in
addition to the first-order value: Let's assume we're searching for a value in a
vector and want to know its index in it:

```rust
fn search(needle: &String, haystack: &Vec<String>) -> Option<usize> {
    // Return `Some(index)` if value is present `None` otherwise
    haystack.iter().position(|x| x == needle)
}

fn main() {
    let fruit = vec![
        "banana".to_string(),
        "mango".to_string(),
        "apple".to_string()
    ];
    let res = search(&"apple".to_string(), &fruit);
    assert_eq!(res, Some(2));
}
```

In this case, our search function will search for the string `needle` inside
the collection `haystack`. If it succeeds (the `true` case), it's going to return
us a value that signals that it succeeded, along with the extra information we
asked for (the index in our case). This is the `Some(T)` constructor that we saw
above in the type definitions. If it fails, it will instead return `None` (the
`false` equivalent).

This is a great example of the typical use-case for `Option`: we use it in contexts
where we want to attach auxiliary data in the successful case, but where if we fail,
we don't care enough to know more about the failure case - only that it happened.

That gap is being filled by `Result` - it's like `Option` semantically, but it allows
us to also carry around extra data in the case `false` case. This is useful in that
it allows us to carry around diagnostic information in the failure case, to allow
with error reporting and recovery.

An example of this need being satisfied would be the following function:

```rust
fn read_to_string(filename: &str) -> Result<String, io::Error> {
    let mut file = match File::open(&filename) {
        Ok(f) => f,
        Err(e) => return Err(e),
    };

    let mut text = String::new();
    match file.read_to_string(&mut text) {
        Ok(_) => Ok(text),
        Err(e) => Err(e),
    }
}
```

Here our `read_to_string` function is doing two things:

1. Open a file, and
2. Read its contents into a string buffer.

Any of these two operations can fail. If we only had a `bool` value as the return
value, we could signal that a failure happened by returning `false`, but we would
be at a loss as to *what* has actually failed.

In this case, our `Result` type allows us to do the following:

* If everything worked fine, return the `Ok()` constructor with an appropriate
  value attached (the string buffer in our case, after completion).
* If there was an error, either at file opening or reading, returning an `Err()`
  constructor, with an appropriate error message attached.

## Conclusion

To wrap everything up in a TL;DR form, here's my usage heuristic for the above types:

* Use `bool` for simple predicates.
* Use `Option<T>` when extra data needs to be carried in the success case (for instance
  when searching for values in a collection) and the failure case is signaling a simple
  absence of value for any reason.
* Use `Result<T,E>` when extra data needs to be carried around in the success and failure
  case (say, if you're reading something from the network, and you want to return
  the data in the success case or an appropriate error message in the failure case).
