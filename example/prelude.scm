(define (map fn lst)
  (if (null? lst) '()
    (cons (fn (car lst)) (map fn (cdr lst)))))

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
