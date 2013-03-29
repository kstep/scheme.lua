#!../bin/runscm.lua

; vim: ft=scheme

;(define (print arg) (display arg) (newline))

(include "prelude.scm")

(print "Hello, world!")

(let loop ((i 0))
  (if (> i 10) '()
    (begin
      (print i)
      (loop (+ 1 i))
     )))

(assert (= (fold-left + 0 (map (lambda (a) (+ a 2)) '(1 2 3 4 5))) 25))

(define (fact n acc)
  (if (= n 0) acc (fact (- n 1) (* acc n))))

(assert (= (fact 10 1) 3628800))

(print
  (table
    (a 1)
    (b 2)
    (c 3)))

(define (sub1 n) (- n 1))
(letrec ((is-even? (lambda (n)
                     (or (zero? n)
                         (is-odd? (sub1 n)))))
         (is-odd? (lambda (n)
                    (and (not (zero? n))
                         (is-even? (sub1 n))))))
  (assert (is-odd? 11) #t))

(assert (equal? (fold-left cons '() '(1 2 3)) '(3 2 1)))
(assert (equal? (fold-right cons '() '(1 2 3)) '(1 2 3)))

(assert (= (fold-left / 1 '(1 2 3)) 1.5))
(assert (= (fold-right / 1 '(1 2 3)) 1.5))

