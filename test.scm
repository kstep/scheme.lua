#!./runscm.lua

; vim: ft=scheme

(include "prelude.scm")

(print "Hello, world!")

(print
  (reduce (lambda (a b) (+ a b))
          (map (lambda (a) (+ a 2)) '(1 2 3 4 5))
          0)
  )

[define (fact n)
  (if (= n 0) 1 (* (fact (- n 1)) n))]

(print (fact 20))

(print
  (table
    [a 1]
    [b 2]
    [c 3]))
