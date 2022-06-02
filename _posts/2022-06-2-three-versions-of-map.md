---
layout: post
title: "Three (plus one) different versions of map in Haskell"
date: 2022-06-02
tags: fp haskell
---

`map` is one of the most famous (and pivotal) higher-order functions. It's also
the function that I hold dearest in my heart, as it marked a very pleasant memory
in mind of when [I first understood the concept enough to be able to write
the function on my own](https://gist.github.com/NlightNFotis/b662a0368b5eea68ebfde1e4e4fb9787).

As a quick explainer, `map` is a function that takes two arguments, a function `fn`
and a list `lat`, and produces a new list with the elements being the result of
the application of the function `fn` to the elements of `lat` (in mathematical writing,
this would be `∀x ∈ lat, fn(x)` - that is, for all `x` that belong to `l` we take the
result of `fn` applied to `x`, `fn(x)`).

I always knew of the (*classic*?) way to define that in Scheme (or more generally,
in Lisp), which I had seen also being used in `OCaml`/`SML`, and that would look
something like the following:

```lisp
(define (map fn lat)
  (cond
    ((null? lat) '())
    (else
     (cons (fn (car lat)) (map fn (cdr lat))))))
```

That is, a recursive definition, that does the following:

* if the input list `lat` is empty, it returns the empty list `()` (because that
  is the identity element for the list construction operator `cons`, and is used
  as the basis for the recursion), otherwise
* it returns the list `cons`tructed from the application of the function to the first
  element of the list `(fn (car lat))` and the result of the recursive call on
  the remaining list `(map fn (cdr lat))`.

In OCaml, the same function would probably be defined using pattern matching, but
the pattern is the same:

```ocaml
let rec map fn lat =
  match lat with
  | [] -> []
  | h::t -> (f h)::(map f t)
```

Recently though, I started reading Graham Hutton's excellent [Programming in Haskell](https://www.cs.nott.ac.uk/~pszgmh/pih.html),
as a preparation for some more advanced material I wanted to read that required Haskell
knowledge.

In that book, I was delighted to find not one, not two, but **three** different ways of
defining the function `map` in Haskell.

Let's have a look at the first two ways of defining `map` in Haskell, both defined in
chapter 7 of the book.

## The classical recursive definition of `map`

```haskell
map :: (a -> b) -> [a] -> [b]
map f []     = []
map f (x:xs) = f x : map f xs
```

The first definition is the one that is closest to what we described above for
both Scheme and OCaml. It's the (structural) recursive definition using pattern
matching against two patterns:

* The empty list in the first pattern `[]`, which as before returns the empty list,
  and
* a list with at least one element, which we immediately destructure into a `head`
  and tail component in `(x:xs)`, which when matched will build a `cons` (`:`) of
  the result of the function application `f x` and the result of the recursive call
  of the remaining list (`map f xs`).

This definition is basically the exact equivalent of the OCaml definition above,
with the only notable difference being the explicit function signature given:

```haskell
map :: (a -> b) -> [a] -> [b]
```

This tells us that the `map` function takes two arguments:

* a polymorphic function that maps elements of type `a` to type `b` `(a -> b)`,
* a list of elements of type `a` (`[a]`)

and as a result produces a list of elements of type `b` (`[b]`).

(The `a` and `b` above are called *type variables*, and are implicitly *universally
quantified*, i.e. they read as "for all elements of type `a`").

So far, so classic.

Nothing out of the ordinary here.

## Let the show start: The list comprehension definition of `map`

Later on in the book, we come across this definition:

```haskell
map :: (a -> b) -> [a] -> [b]
map f xs = [f x | x <- xs]
```

Wow!

This one packs a punch in terms of conciseness, but I find it very elegant
and very expressive at the same time.

This definition is based in the syntax for *list comprehensions* in Haskell.

List comprehensions are a concise and convenient way to define new lists
by manipulating elements of other lists. As an example, consider the following:

```haskell
> [x^2 | x <- [1, 2, 3, 4, 5]]
[1, 4, 9, 16, 25]
```

This is read as make a list of "`x` squared, with `x` drawn from (`|`) the list
`[1, 2, 3, 4, 5]`.

Taking this into account, and back to our `map` function definition, our comprehension
there:

```haskell
map f xs = [f x | x <- xs]
```

reads as "make a list of the results of `f x`, where `x` is drawn from the list `xs`".

Beautiful.

## Roll the carpet for Mr. Fold: The `foldr` definition of `map`

One of the coolest things the book opened my eyes to was the fact that we can
use a `fold` in a generative fashion.

I was well aware of `fold` from both Racket and OCaml before, but I always thought
of that in terms of a generalisation of `reduce` - it never occured to me that
I can use the accumulating function to yield a value in a generative recursion
fashion, like a new list 🤯

(Embarassingly, it now looks kind of obvious, and related to ideas I've been exposed
to in the past - this one is related to the `collector functions` idea that the [Little
Schemer](https://mitpress.mit.edu/books/little-schemer-fourth-edition) uses in chapter 8).

Back to our definition.

This one is not given by the book - in fact, it's left for the reader to define as one
of the exercises. This is what I came up with:

```haskell
map :: (a -> b) -> [a] -> [b]
map f = foldr (\ x xs -> f x : xs) []
```

This definition is the one that left me most stunned and amazed with the generalising
power of a fold.

What this definition tells us is that we define `map` as a right fold (`foldr`)
of a lambda that takes two arguments, `x` and `xs`, and `returns` the cons of `f x`
and `xs`. The last value we pass to the `foldr` is the empty list `[]`, because it's
the identity value for the `cons` operator (this means that `cons`ing the empty list
into any other list won't change its structure.)

In order to understand what the `foldr` does, I find the following visual from
[Wikipedia](https://en.wikipedia.org/wiki/Fold_(higher-order_function)) to be
very helpful:

![foldr visualisation](https://upload.wikimedia.org/wikipedia/commons/3/3e/Right-fold-transformation.png)

To understand the above visualisation, you need to understand that a list in Haskell
(and most functional programming languages for that matter), is a `cons` of various
values and the empty list. I.e. you can think of `[1, 2, 3, 4, 5]` as
`1 : (2 : (3 : (4 : (5 : []))))`.

With that in mind, what the `foldr` function does is that replaces the `cons` (`:`)
operator with the function argument supplied to it, and *reduces* it all (*folds the
list*) into a single value.

And here's the trick - because the (anonymous) function we passed to it is building
a new list (by applying the `cons` operator again), what we end up is a new list instead
of just a single value!

In our case, this means that if we had the list:

```haskell
1 : (2 : (3 : (4 : (5 : []))))
```

after the application of the anonymous function we would have a new list, equivalent to

```haskell
f 1 : (f 2 : (f 3 : (f 4 : (f 5 : []))))
```

🤯

### Bonus round: a monadic definition of `map`

Okay, this is a bit of a cheat because this is basically our first definition, except
that the function and the return type are monadic:

```hs
mapM :: Monad m => (a -> m b) -> [a] -> m [b]
mapM f []     = return []
mapM f (x:xs) = do y <- f x
                   ys <- mapM f xs
                   return (y : ys)
```

This is using the [`do` notation to define a sequence of actions](https://en.wikibooks.org/wiki/Haskell/do_notation),
but the actions themselves have a near 1-1 correspondence to our original map implementation:

* First we assign the name `y` to the result of `f x`, then
* We assign the name `ys` to the result of the recursive call on the tail of the list (`mapM f xs`)
* And the return the `cons` of the two values `(y : ys)`

## Conclusion

I enjoyed writing this post quite a bit.

It's a very humbling experience to be visiting books and seeing that ideas that you considered
to be elementary and rather surface-level are a lot more nuanced once you start digging deeper
into them.

It's something I need to keep top of mind as I go forward as well.

This post also highlights one of the nice things of going for breadth of knowledge: exposure
to a wider set of ideas. Had I only stayed in the Racket/OCaml realm, I probably wouldn't have
been exposed to this range of `map` implementations, for the reason that these languages don't
offer some of the language features that enable them, like list comprehensions.

All in all, happy I went down this path, and looking forward to what's next.
