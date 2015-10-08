#lang racket/base
(require racket/match)

(define (syntax-strings->input-port name ss)
  (define line 1)
  (define col 0)
  (define pos 1)
  (define current-idx #f)
  (define current-bs #f)
  (define next-ss ss)

  (define (read-in bs)
    (cond
      [(not current-bs)
       (match next-ss
         ['() eof]
         [(cons ss more-ss)
          (set! line (syntax-line ss))
          (set! col (syntax-column ss))
          (set! pos (syntax-position ss))
          (set! current-bs (string->bytes/utf-8 (syntax->datum ss)))
          (set! current-idx 0)
          (set! next-ss more-ss)
          (read-in bs)])]
      [(< current-idx (bytes-length current-bs))
       (define how-many
         (min (bytes-length bs)
              (- (bytes-length current-bs)
                 current-idx)))
       (define end (+ current-idx how-many))
       (bytes-copy! bs 0 current-bs current-idx end)
       (set! current-idx end)
       (set! col (+ col how-many))
       (set! pos (+ pos how-many))
       how-many]
      [else
       (set! current-bs #f)
       (read-in bs)]))
  (define (get-location)
    (values line col pos))

  (make-input-port name read-in #f void #f #f
                   get-location void #f #f))

(provide syntax-strings->input-port)