;; LambdaNative gui template

(define gui #f)

(main
;; initialization
  (lambda (w h)
    (make-window 320 480)
    (glgui-orientation-set! GUI_PORTRAIT)
    (set! gui (make-glgui))

    ;; initialize gui here
    (glgui-pixmap gui 50 200 glgui_keypad_toggleChar.img)
    (glgui-label gui 10 325 300 60 "Press TAB to show problem" ascii_18.fnt Cyan)
    (glgui-label gui 10 300 300 60 "Those rendered at runtime are fine, but newly" ascii_18.fnt Cyan)
    (glgui-label gui 10 275 300 60 "added ones are broken boxes. [Clipping?]" ascii_18.fnt Cyan)
    (set! Pone (glgui-pixmap gui 100 200 glgui_keypad_toggleChar.img))
    (set! Ptwo (glgui-pixmap gui 100 100 glgui_keypad_shift_on.img))
    (glgui-widget-set! gui Pone 'hidden #t)
    (glgui-widget-set! gui Ptwo 'hidden #t)
  )
;; events
  (lambda (t x y)
    (if (= t EVENT_KEYPRESS) (begin
      (if (= x EVENT_KEYESCAPE) (terminate))
      (if (= t EVENT_KEYTAB) (begin
        (glgui-widget-set! gui Pone 'hidden (not (glgui-widget-get gui Pone 'hidden)))
        (glgui-widget-set! gui Ptwo 'hidden (not (glgui-widget-get gui Ptwo 'hidden)))
      ))
    ))
    (glgui-event gui t x y))
;; termination
  (lambda () #t)
;; suspend
  (lambda () (glgui-suspend) (terminate))
;; resume
  (lambda () (glgui-resume))
)

;; eof
