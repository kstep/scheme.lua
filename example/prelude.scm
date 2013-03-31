;(define (map fn lst)
  ;(if (null? lst) '()
    ;(cons (fn (car lst)) (map fn (cdr lst)))))

(define (for-each fn lst)
  (if (null? lst) '()
    (begin
      (fn (car lst))
      (for-each fn (cdr lst)))))

(define (fold-left fn init lst)
  (if (null? lst) init
    (fold-left fn (fn (car lst) init) (cdr lst))))

(define (fold-right fn init lst)
  (if (null? lst) init
    (fn (car lst) (fold-right fn init (cdr lst)))))

(define (filter fn lst)
  (if (null? lst) lst
    (if (fn (car lst))
      (cons (car lst) (filter fn (cdr lst)))
      (filter fn (cdr lst)))))

(define (concat a b)
  (if (null? a) b
    (cons (car a) (concat (cdr a) b))))

(define (qsort key lst)
  (if (null? lst) lst
    (let* ([pivot (key (car lst))]
           [rest (cdr lst)]
           [left (filter (lambda (a) (< (key a) pivot)) rest)]
           [right (filter (lambda (a) (> (key a) pivot)) rest)])
      (concat (qsort key left) (cons (car lst) (qsort key right))))))

(define (id x) x)
