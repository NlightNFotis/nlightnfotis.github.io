---
layout: post
title: "GSOC: Week 4 report"
date: 2013-07-15 11:43
comments: false
categories: gsoc gcc golang
---

# Yeah baby! It builds!

**The highlight of this week's progress was managing to successfully build
gccgo under the Hurd.**
Not only did it compile successfully, it also run its tests, with the
results [matching the ones provided by my mentor Thomas Schwinge](http://lists.gnu.org/archive/html/bug-hurd/2013-06/msg00117.html).
This was a checkpoint in my summer of code project. Successful building of
the compiler meant that I am (happily) in the position to carry on with the
next part (and the main one) of my project, that is, to make sure that
the **go library (libgo) also passes all its tests 
and works without any major issues.**

# So where are we now?

## gccgo

Compiling gccgo on the Hurd was big. But we also had to see how it 
compared to the build that was successful on Linux. The most effective
way to compare the two builds, is to check the test results of the two.

Taking a look at the gccgo results on the Hurd, I was delighted to find 
that it passed most of its tests. There were few that were failing, but 
for the most part, it did well. Below are the test results of gccgo on the Hurd:

~~~
     === go Summary ===

# of expected passes        5069
# of unexpected failures    11
# of expected failures      1
# of untested testcases     6
/root/gcc_new/gccbuild/gcc/testsuite/go/../../gccgo  version 4.9.0 20130606 (experimental) (GCC)

~~~
{:lang="shell"}

So it's passing 99% of its tests. That's cool. But it could help to take a look
at the tests that are failing, to get an idea of what the fails are, how critical they are, etc

~~~
nlightnfotis@earth:~/HurdVM/HurdFiles$ grep -v ^PASS: < go.sum
Test Run By root on Thu Jul 11 10:33:34 2013
Native configuration is i686-unknown-gnu0.3

        === go tests ===

        Schedule of variations:
            unix

            Running target unix
            Running /root/gcc_new/gcc/gcc/testsuite/go.dg/dg.exp ...
            Running /root/gcc_new/gcc/gcc/testsuite/go.go-torture/execute/execute.exp ...
            Running /root/gcc_new/gcc/gcc/testsuite/go.test/go-test.exp ...
            FAIL: go.test/test/chan/doubleselect.go execution,  -O2 -g 
            FAIL: go.test/test/chan/nonblock.go execution,  -O2 -g 
            UNTESTED: go.test/test/chan/select2.go
            FAIL: go.test/test/chan/select3.go execution,  -O2 -g 
            FAIL: go.test/test/chan/select5.go execution
            UNTESTED: go.test/test/closure.go
            FAIL: go.test/test/fixedbugs/bug147.go execution,  -O2 -g 
            FAIL: go.test/test/fixedbugs/bug347.go execution,  -O0 -g 
            FAIL: go.test/test/fixedbugs/bug348.go execution,  -O0 -g 
            XFAIL: bug429.go  -O2 -g  execution test
            FAIL: go.test/test/goprint.go execution
            UNTESTED: go.test/test/goprint.go compare
            UNTESTED: go.test/test/init1.go
            FAIL: go.test/test/mallocfin.go execution,  -O2 -g 
            FAIL: go.test/test/nil.go execution,  -O2 -g 
            FAIL: go.test/test/recover3.go execution,  -O2 -g 
            UNTESTED: go.test/test/rotate.go
            UNTESTED: go.test/test/stack.go

                    === go Summary ===

# of expected passes        5069
# of unexpected failures    11
# of expected failures      1
# of untested testcases     6
/root/gcc_new/gccbuild/gcc/testsuite/go/../../gccgo  version 4.9.0 20130606 (experimental) (GCC) 
~~~
{:lang="shell"}

Hmm. So these are the failing tests. Before we go through them, it might be a good idea
to check the status of the gccgo tests on the Linux build too. Let's see.

~~~
nlightnfotis@earth:~$ grep -v ^PASS: < linux_go.sum 
Test Run By fotis on Mon Jul 15 10:28:38 2013
Native configuration is i686-pc-linux-gnu

        === go tests ===

        Schedule of variations:
            unix

            Running target unix
            Running /home/fotis/Software/gcc/gcc/testsuite/go.dg/dg.exp ...
            Running /home/fotis/Software/gcc/gcc/testsuite/go.go-torture/execute/execute.exp ...
            Running /home/fotis/Software/gcc/gcc/testsuite/go.test/go-test.exp ...
            UNTESTED: go.test/test/closure.go
            XFAIL: bug429.go  -O2 -g  execution test
            UNTESTED: go.test/test/init1.go
            UNTESTED: go.test/test/rotate.go

                    === go Summary ===

# of expected passes        5183
# of expected failures      1
# of untested testcases     3
/home/fotis/Software/gcc_build/gcc/testsuite/go/../../gccgo  version 4.9.0 20130702 (experimental) (GCC) 
~~~
{:lang="shell"}

So, it seems like there are less tests failing here. But wait a minute. Those tests that are failing.
They are the same as with the Hurd build. So I can assume that we are left with 4 less tests to check
regarding their failures (Go on Linux works without any issues,so I guess it would be safe to skip those tests at the moment).
That leaves us with these tests to check:

~~~
FAIL: go.test/test/chan/doubleselect.go execution,  -O2 -g
FAIL: go.test/test/chan/nonblock.go execution,  -O2 -g
UNTESTED: go.test/test/chan/select2.go
FAIL: go.test/test/chan/select3.go execution,  -O2 -g
FAIL: go.test/test/chan/select5.go execution
FAIL: go.test/test/fixedbugs/bug147.go execution,  -O2 -g
FAIL: go.test/test/fixedbugs/bug347.go execution,  -O0 -g
FAIL: go.test/test/fixedbugs/bug348.go execution,  -O0 -g
FAIL: go.test/test/goprint.go execution
UNTESTED: go.test/test/goprint.go compare
FAIL: go.test/test/mallocfin.go execution,  -O2 -g
FAIL: go.test/test/nil.go execution,  -O2 -g
FAIL: go.test/test/recover3.go execution,  -O2 -g
UNTESTED: go.test/test/stack.go
~~~
{:lang="shell"}

Discussing this with my mentor [Thomas Schwinge](https://plus.google.com/101468009864620818344) in IRC (#hurd)


> <tschwinge> For now, please ignore any failing tests that have »select« in their name -- that is, do file them, but do not spend a lot of time figuring out what might be wrong there.
> <tschwinge> The Hurd's select implementation is a bit of a beast, and I don't want you -- at this time -- spend a lot of time on that.  We already know there are some deficiencies, so we should postpone that to later.


So that leaves us with even less tests to check:

~~~
FAIL: go.test/test/chan/nonblock.go execution,  -O2 -g
FAIL: go.test/test/fixedbugs/bug147.go execution,  -O2 -g
FAIL: go.test/test/fixedbugs/bug347.go execution,  -O0 -g
FAIL: go.test/test/fixedbugs/bug348.go execution,  -O0 -g
FAIL: go.test/test/goprint.go execution
UNTESTED: go.test/test/goprint.go compare
FAIL: go.test/test/mallocfin.go execution,  -O2 -g
FAIL: go.test/test/nil.go execution,  -O2 -g
FAIL: go.test/test/recover3.go execution,  -O2 -g
UNTESTED: go.test/test/stack.go
~~~
{:lang="shell"}

Nice. **This narrowed down the list of errors that I have to go through to make sure that gccgo
works as well on the Hurd as it does on Linux.**

## libgo

So, we talked about gccgo, but what about the runtime libraries (libgo)? They are also getting 
tested when we run `make check-go`and seeing as they are a vital part 
of enabling programs written on go to run on the Hurd, we ought
to take a look. (This was also the original goal of my project proposal).

So let us see what we have at the libgo.sum:

~~~
Test Run By root on Fri Jul 12 17:56:44 UTC 2013
Native configuration is i686-unknown-gnu0.3

        === libgo tests ===

        Schedule of variations:
            unix

            Running target unix
            Running ../../../gcc/libgo/libgo.exp ...
            FAIL: bufio
            FAIL: bytes
            FAIL: errors
            FAIL: expvar
            FAIL: flag
            FAIL: fmt
            FAIL: html
            FAIL: image
            FAIL: io
            FAIL: log
            FAIL: math
            FAIL: mime
            FAIL: net
            FAIL: os
            FAIL: path
            FAIL: reflect
            FAIL: regexp
            FAIL: runtime
            FAIL: sort
            FAIL: strconv
            FAIL: strings
            FAIL: sync
            FAIL: syscall
            FAIL: time
            FAIL: unicode
            FAIL: archive/tar
            FAIL: archive/zip
            FAIL: compress/bzip2
            FAIL: compress/flate
            FAIL: compress/gzip
            FAIL: compress/lzw
            FAIL: compress/zlib
            FAIL: container/heap
            FAIL: container/list
            FAIL: container/ring
            FAIL: crypto/aes
            FAIL: crypto/cipher
            FAIL: crypto/des
            FAIL: crypto/dsa
            FAIL: crypto/ecdsa
            FAIL: crypto/elliptic
            FAIL: crypto/hmac
            FAIL: crypto/md5
            FAIL: crypto/rand
            FAIL: crypto/rc4
            FAIL: crypto/rsa
            FAIL: crypto/sha1
            FAIL: crypto/sha256
            FAIL: crypto/sha512
            FAIL: crypto/subtle
            FAIL: crypto/tls
            FAIL: crypto/x509
            FAIL: database/sql
            FAIL: database/sql/driver
            FAIL: debug/dwarf
            FAIL: debug/elf
            FAIL: debug/macho
            FAIL: debug/pe
            FAIL: encoding/ascii85
            FAIL: encoding/asn1
            FAIL: encoding/base32
            FAIL: encoding/base64
            FAIL: encoding/binary
            FAIL: encoding/csv
            FAIL: encoding/gob
            FAIL: encoding/hex
            FAIL: encoding/json
            FAIL: encoding/pem
            PASS: encoding/xml
            FAIL: exp/cookiejar
            FAIL: exp/ebnf
            FAIL: exp/html
            FAIL: exp/html/atom
            FAIL: exp/locale/collate
            FAIL: exp/locale/collate/build
            FAIL: exp/norm
            FAIL: exp/proxy
            FAIL: exp/terminal
            FAIL: exp/utf8string
            FAIL: html/template
            FAIL: go/ast
            FAIL: go/doc
            FAIL: go/format
            FAIL: go/parser
            FAIL: go/printer
            FAIL: go/scanner
            FAIL: go/token
            FAIL: go/types
            FAIL: hash/adler32
            FAIL: hash/crc32
            FAIL: hash/crc64
            FAIL: hash/fnv
            FAIL: image/color
            FAIL: image/draw
            FAIL: image/jpeg
            FAIL: image/png
            FAIL: index/suffixarray
            FAIL: io/ioutil
            FAIL: log/syslog
            FAIL: math/big
            FAIL: math/cmplx
            FAIL: math/rand
            FAIL: mime/multipart
            FAIL: net/http
            FAIL: net/http/cgi
            FAIL: net/http/fcgi
            FAIL: net/http/httptest
            FAIL: net/http/httputil
            FAIL: net/mail
            FAIL: net/rpc
            FAIL: net/smtp
            FAIL: net/textproto
            FAIL: net/url
            FAIL: net/rpc/jsonrpc
            FAIL: old/netchan
            FAIL: old/regexp
            FAIL: old/template
            FAIL: os/exec
            FAIL: os/signal
            FAIL: os/user
            FAIL: path/filepath
            FAIL: regexp/syntax
            FAIL: runtime/pprof
            FAIL: sync/atomic
            FAIL: text/scanner
            FAIL: text/tabwriter
            FAIL: text/template
            FAIL: text/template/parse
            FAIL: testing/quick
            FAIL: unicode/utf16
            FAIL: unicode/utf8

                    === libgo Summary ===

# of expected passes        1
# of unexpected failures    130
/root/gcc_new/gccbuild/./gcc/gccgo version 4.9.0 20130606 (experimental) (GCC)
~~~
{:lang="shell"}

**Oh boy!** Oh boy! Well, on second thoughts, this was not unexpected. 
**This was the core of my GSOC work**. This is how it starts :)

Before this goes any further, maybe we should visit the Linux test results too.

~~~

Test Run By fotis on Τρι 02 Ιούλ 2013 09:20:20 μμ EEST
Native configuration is i686-pc-linux-gnu

        === libgo tests ===

        Schedule of variations:
            unix

            Running target unix
            Running ../../../gcc/libgo/libgo.exp ...
            PASS: bufio
            PASS: bytes
            ...

                    === libgo Summary ===

# of expected passes        131
/home/fotis/Software/gcc_build/./gcc/gccgo version 4.9.0 20130702 (experimental) (GCC)
~~~
{:lang="shell"}

Wow. Considering the results from the Hurd, they really are **not** unexpected. [Remember
that **getcontext, makecontext, setcontext and swapcontext** are not working as expected.](http://darnassus.sceen.net/~hurd-web/open_issues/gccgo/)

And recalling from an email from Ian Lance Taylor (the GCCgo maintainer, and a member of the Go team)
early in the summer:

> Go does require switching stacks.  A port of Go that doesn't support
> goroutines would be useless--nothing in the standard library would
> work

# Conclusion / Work for next week.

**So now it comes down to work on implementing correctly the context switching functions.** 
Apart from that, going through the test results that fail from gccgo is also something that
is to be done, however I am not sure that it should be a first priority. I also have to go
through go.log to see if there any clues as to why the gccgo tests fail.

Having finally built gccgo on the Hurd, and **more importantly still being on schedule,
(the original one, from my proposal) means that I can now concentrate on the core part of my 
project proposal (and the most exciting one too)**, that is proper implementation 
of what is *blocking effective context switching, which
in its part is blocking goroutines, without which, the go library will not work properly.*
