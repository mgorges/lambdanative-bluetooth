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

;; get last camera roll image from devices (currently just iphone)
;;
;; Example use:
;;  (define camera:texture (glCoreTextureCreate w h (##still-copy (make-u8vector (* 3 w h) 255))))
;;  (glgui-pixmap gui 0 0 (list w h camera:texture 0. 0. 1. 1.))
;;  (cameraroll-updatetexture camera:texture)

(c-declare  #<<end-of-c-declare

#ifdef IOS
void iphone_cameraroll_update(void);
unsigned int iphone_cameraroll_width(void);
unsigned int iphone_cameraroll_height(void);
void iphone_cameraroll_rgb(unsigned char*,int,int);
#endif

static void cameraroll_update(void){
#ifdef IOS
   iphone_cameraroll_update();
#endif
}

static unsigned int cameraroll_width(void){
#ifdef IOS
  return iphone_cameraroll_width();
#else
  return 0;
#endif
}

static unsigned int cameraroll_height(void){
#ifdef IOS
  return iphone_cameraroll_height();
#else
  return 0;
#endif
}


static void cameraroll_rgb(unsigned char *data, int w, int h){
#ifdef IOS
   iphone_cameraroll_rgb(data,w,h);
#endif
}

end-of-c-declare
)

(define cameraroll:update (c-lambda () void "cameraroll_update"))
(define cameraroll:width (c-lambda () unsigned-int "cameraroll_width"))
(define cameraroll:height (c-lambda () unsigned-int "cameraroll_height"))

(define (cameraroll:rgb data w h)
  ((c-lambda (scheme-object int int) void
    "cameraroll_rgb(___CAST(void*,___BODY_AS(___arg1,___tSUBTYPED)),___arg2,___arg3);")
         data (fix w) (fix h)))

(define (cameraroll-updatetexture t)
  (cameraroll:update)
  (let* ((th (glCoreTextureHeight t))
         (tw (glCoreTextureWidth t))
         (data (glCoreTextureData t)))
    (cameraroll:rgb data tw th)
    (glCoreTextureUpdate t)
 ))

;; eof