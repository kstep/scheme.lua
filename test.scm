#!./runscm.lua

; vim: ft=scheme

(include "prelude.scm")

(print "Hello, world!")

(let loop ([i 0])
  (if (> i 10) '()
    (begin
      (print i)
      (loop (+ 1 i))
     )))

(for-each print (list
  (reduce (lambda (a b) (+ a b))
          (map (lambda (a) (+ a 2)) '(1 2 3 4 5))
          0)))

[define (fact n acc)
  (if (= n 0) acc (fact (- n 1) (* acc n)))]

(print (fact 98 1))

(print
  (table
    [a 1]
    [b 2]
    [c 3]))

(define (sub1 n) (- n 1))
(let* ([is-even? (lambda (n)
                  (or (zero? n)
                      (is-odd? (sub1 n))))]
      [is-odd? (lambda (n)
                 (and (not (zero? n))
                      (is-even? (sub1 n))))])
  (print (is-odd? 11)))
