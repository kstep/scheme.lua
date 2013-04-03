# Scheme.Lua #

This is a Scheme dialect compiler for Lua.

It parses S-expressions into Lua structures and evaluates them.

You can run an interpreter to evaluate any Scheme file (well not any, only
subset of Scheme is supported for now, but nevertheless):

    $ ./bin/runscm.lua code.scm

You can "compile" Scheme code into Lua data structures representation
to speed up code loading:

    $ ./bin/compile.lua code.scm
    $ chmod a+x code.lscm

This will create `code.lscm` file by default, where `lscm` is for *Lua Scheme*.

Also there's simple REPL in `example` dir:

    $ cd example
    $ ./repl.scm

This project is a work in progress, so it's buggy and a lot of things missing.

## Disclaimer ##

Although I have good experience in Lua, I'm just a novice in Scheme/Lisp.

This whole project is made to learn Scheme (which I like more than Common
Lisp), and I learn as I write it, so if you are a Lisp or Scheme expert,
don't blame me too much if I implement language features incorrectly.
Just open an issue in this repo or submit a pull request with corrections
so I can fix things up. I'm happy to learn from you!

## Not implemented ##

   * `(call/cc)` and continuations, and it's unlikely I implement them as it's
     non-trivial to do it in Lua, maybe I will implement `(call/cc1)` at some
     point (and there's a strong chance it will be based in coroutines).

     Anyway you can use `coroutine` standard library from Scheme land
     by importing it with `(lua-import coroutine)` form.

   * Error handling with line numbers and full stack backtrace reports.
   
     Most errors are propagated to Lua land as is with thin wrapper around
     `error()` function, and you can deduct what's wrong from normal Lua stack
     backtrace, Lua functions (which back basic Scheme functionality) being
     named by file/line pairs, but no try is made to guess the error location
     in source Scheme code, which is sad and I know it.
     
     I leave it as is now due to performance restrictions and because usage of
     `pcall()` breaks tail recursion chain, and this makes whole thing blow up
     as all the evaluation is based in Lua's tail recursion mechanism.

     If I think of any way to handle errors more Scheme-way without serious
     performance impact and without killing code evaluation with stack overflows,
     I will do it.

   * Scheme macro system and syntax extension forms.

     I don't plan to implement it in near future, as the Scheme dialect is
     easily extensible with Lua code. You can always write your own syntax
     structure in Lua and plug it into Scheme land.

   * A lot of Scheme forms, I will implement at some point (except for
     things which are too difficult or impossible to do in Lua).

## Contributions ##

Of couse any contribution is welcome! Fork me, create topic branch, do your
fancy things and submit a pull request to me to merge.

Thank you!

© 2013 Konstantin Stepnov
