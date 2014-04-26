#|
LambdaNative - a cross-platform Scheme framework
Copyright (c) 2009-2014, University of British Columbia
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the
following conditions are met:

* Redistributions of source code must retain the above
copyright notice, this list of conditions and the following
disclaimer.

* Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials
provided with the distribution.

* Neither the name of the University of British Columbia nor
the names of its contributors may be used to endorse or
promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
|#

;; Call native camera app
;; NOTE: Like glgui events, PHOTO_TAKEN event has to be handled in the events section of the main loop:
;; (if (= t EVENT_PHOTOTAKEN) (camera:get-image x y))

;; Native C part

(c-declare  #<<end-of-c-declare

#ifdef ANDROID
  void callJavaCameraMethod();
  int* image();
#endif

void start_camera(){
#ifdef ANDROID
  callJavaCameraMethod();
#endif
}

end-of-c-declare
)

(define return-img-as-list (c-lambda (int) scheme-object
#<<c-lambda-end
#ifdef ANDROID
  ___SCMOBJ s,list,tmp;
  int i, *buf = image(), length = ___arg1;
  list = ___NUL;
  for (i = 0; i < length; i++){
    ___EXT(___INT_to_SCMOBJ)(buf[i],&s,___STILL);
    tmp  = ___EXT(___make_pair) (s,list, ___STILL);
    ___EXT(___release_scmobj) (list);
    list = tmp;
  }
  ___EXT(___release_scmobj) (list);
  ___EXT(___release_scmobj) (s);
  ___result = list;
#endif
c-lambda-end
))

;; Scheme part
(c-define-type SAVE_DIRECTORY char-string)
(c-define-type SAVE_FILENAME char-string)
(c-define-type THUMBNAIL_SIZE int)

(define camera:camera (c-lambda (SAVE_DIRECTORY SAVE_FILENAME THUMBNAIL_SIZE) void "start_camera"))
(define camera:c-android-log #f)
(define camera:on-photo-taken #f)

(define (android-log text1 #!optional text2) 
  (call/cc (lambda (exit)
    (if (not (procedure? camera:c-android-log)) (exit))
    (if (number? text1) (set! text1 (number->string text1)))
    (if text2
      (begin
        (if (number? text2) (set! text2 (number->string text2)))
        (set! text1 (string-append text1 ": " text2))
      ))
    (camera:c-android-log text1)
  ))
)

(define (camera:get-image w h)
  (let* ((ww (fix (expt 2. (ceiling (/ (log w) (log 2.))))))
         (hh (fix (expt 2. (ceiling (/ (log h) (log 2.))))))
         (l (* w h 3))
         (texture (list->u8vector (return-img-as-list l)))
         (expanded-texture (expand-u8v texture w h (- ww w))))
    (android-log "calculated" (* ww hh 3))
    (android-log "actual" (u8vector-length expanded-texture))
    (camera:on-photo-taken (list w h (glCoreTextureCreate ww hh expanded-texture) (/ w ww) 0. 0. (/ h hh)))
  ))

(define (expand-u8v img w h incr)
  (define (row-find v w r)
    (let* ((r-start (* (- r 1) (* w 3)))
           (r-end (+ r-start (- (* w 3) 1))))
      (list r-start r-end)
    ))
  (define (u8vector-subset v s e)
    (let ((a (make-u8vector (+ (- e s) 1 ))))
      (let loop ((i s))
        (u8vector-set! a (- i s) (u8vector-ref v i))
        (if (< i e) (loop (+ i 1)))
      )
      a
    ))
  (let ((v (list->u8vector (list))))
    (let loop ((i 1))
      (let ((a (row-find img w i)))
        (set! v (u8vector-append v (u8vector-subset img (car a) (cadr a)) (make-u8vector (* incr 3))))
      )
      (if (< i h) (loop (+ i 1)))
    )
    (set! v (u8vector-append v (make-u8vector (* (* incr 3) (+ w incr)))))
    v
  ))

;; Calls camera activity and defines module callback variable
;; EXAMPLE: (camera:start-camera "DCIM" "Case100" image-callback)
(define (camera:start-camera save-dir save-file thumb-size #!optional callback)
  (call/cc (lambda (exit)
    (cond
      ((not (string? save-dir))
        (begin (android-log "Directory argument is not a string.") (exit)))
      ((not (string? save-file))
        (begin (android-log "Filename argument is not a string.") (exit)))
      ((and callback (not (procedure? callback)))
        (begin (android-log "Callback procedure undefined.") (exit)))
    )
    (camera:camera save-dir save-file thumb-size)
    (if callback (set! camera:on-photo-taken callback))
  ))
)

;;eof