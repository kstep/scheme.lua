(define (map fn list)
  (if (null? list) '()
    (cons (fn (car list)) (map fn (cdr list)))))

(define (reduce fn list acc) (begin
                               (if (null? list) acc
                                 (reduce fn (cdr list) (fn acc (car list))))))

