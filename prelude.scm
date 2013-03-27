(define (map fn lst)
  (if (null? lst) '()
    (cons (fn (car lst)) (map fn (cdr lst)))))

(define (for-each fn lst)
  (if (null? lst) '()
    (begin
      (fn (car lst))
      (for-each fn (cdr lst)))))

(define (reduce fn lst acc)
  (if (null? lst) acc
    (reduce fn (cdr lst) (fn acc (car lst)))))

