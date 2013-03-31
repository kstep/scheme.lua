#!../bin/runscm.lua

; vim: ft=scheme

;(define (print arg) (display arg) (newline))

(include "prelude.scm")

(let loop ([i 0])
  (if (> i 10) (print "All OK!") (begin

(assert void (print "Hello, world!"))

(let loop ((i 0))
  (if (> i 10) (assert (= i 11))
    (loop (+ 1 i))))

(assert (= (fold-left + 0 (map (lambda (a) (+ a 2)) '(1 2 3 4 5))) 25))

(define (fact n acc)
  (if (= n 0) acc (fact (- n 1) (* acc n))))

(assert (= (fact 10 1) 3628800))

(assert (equal? (qsort id '(1 10 5 8 9 11 33))
                (list       1 5 8 9 10 11 33)))

(let* ([t '([a 1] [b 2] [c 3])]
       [tt (apply table t)]
       [rt (qsort car (table->list tt))])
  (assert (equal? t rt)))

(letrec ((is-even? (lambda (n)
                     (or (zero? n)
                         (is-odd? (- n 1)))))
         (is-odd? (lambda (n)
                    (and (not (zero? n))
                         (is-even? (- n 1))))))
  (assert (is-odd? 11) #t))

(assert (equal? (fold-left cons '() '(1 2 3)) '(3 2 1)))
(assert (equal? (fold-right cons '() '(1 2 3)) '(1 2 3)))

(assert (= (fold-left / 1 '(1 2 3)) 1.5))
(assert (= (fold-right / 1 '(1 2 3)) 1.5))

(loop (+ i 1))

)))
