#!../bin/runscm.lua

(define (quit) "QUIT")

(letrec
  ([PROMPT "> "]
   [result ""]
   [yes (lambda (exn) #t)]
   [handler (lambda (exn) (print exn) (set! result ""))]
   [get-command
     (lambda ()
       (display PROMPT)
       (with-handlers
         ([yes handler])
         (set! result (or (read) "")))
       (if (eq? result quit) '()
         (begin
           (display result)
           (newline)
           (get-command))))])
  (get-command))
