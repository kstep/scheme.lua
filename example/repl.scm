#!../bin/runscm.lua

(define (quit) "QUIT")

(letrec
  ([PROMPT "> "]
   [get-command
     (lambda ()
       (display PROMPT)
       (set! result (or (read) ""))
       (if (eq? result quit) '()
         (begin
           (display result)
           (newline)
           (get-command))))])
  (get-command))
