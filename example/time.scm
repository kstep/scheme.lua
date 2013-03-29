(let loop ([i 0] [sum 0])
  (if (> i 100000) '()
  ;(if (> i 500) '()
    (loop (+ i 1) (+ sum i))))
