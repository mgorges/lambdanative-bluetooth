#|
LambdaNative - a cross-platform Scheme framework
Copyright (c) 2009-2013, University of British Columbia
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

;; communicate over bluetooth (android only)

(c-declare  #<<end-of-c-declare
#include <string.h>

static int _bluetooth_error, _bluetooth_notready;
int bluetooth_error(void) { return _bluetooth_error; }
int bluetooth_timeout(void) { return _bluetooth_notready; }

static char *bt_remote_address[16];
static char *bt_remote_name[16];
static int bt_remote_ct=0;
int bluetooth_remote_number(void) { return bt_remote_ct; }

#ifdef ANDROID
  char* android_get_local_address();
  int android_bluetooth_open(char* address);
  void android_bluetooth_close(int dev);
  void android_bluetooth_flush(int dev);
  int android_bluetooth_writechar(int dev, int val);
  int android_bluetooth_readchar(int dev);
  void bluetooth_error_set(int error){ _bluetooth_error=error; }
  void bluetooth_timeout_set(int timeout){  _bluetooth_notready=timeout; }
#endif

void bluetooth_getlocaladdress(char* addr){
#ifdef ANDROID
  char* tmp=android_get_local_address();
  int i;
  for (i=0;i<17;i++){
    addr[i]=tmp[i];
  }
#else
  return;
#endif
}


int bluetooth_open(char* dev){
#ifdef ANDROID
  return android_bluetooth_open(dev);
#else
  return 0;
#endif
}

void bluetooth_close(int dev){
#ifdef ANDROID
  android_bluetooth_close(dev);
#endif
}

int bluetooth_writechar(int dev, int val){
#ifdef ANDROID
  return android_bluetooth_writechar(dev,val);
#else
  return 0;
#endif
}

int bluetooth_readchar(int dev){
#ifdef ANDROID
  return android_bluetooth_readchar(dev);
#else
  return 0;
#endif
}

void bluetooth_flush(int dev){
#ifdef ANDROID
  android_bluetooth_flush(dev);
#endif
}

char bluetooth_getremoteaddress(int i, char* name, char* address){
  if (i<bt_remote_ct){
    strcpy(name,bt_remote_name[i]);
    strcpy(address,bt_remote_address[i]);
    return 1;
  }
  return 0;
}

end-of-c-declare
)

(define (bluetooth-getlocaladdress)
  (let ((res (string->u8vector "00:00:00:00:00:00")))
    ((c-lambda (scheme-object) void "bluetooth_getlocaladdress(___CAST(char*,___BODY_AS(___arg1,___tSUBTYPED)));") 
     res)
    (u8vector->string res)
  ))

(define (bluetooth-getremoteaddresses)
  (let loop ((i 0) (ret (list)))
    (if (fx= i ((c-lambda () int "bluetooth_remote_number")))
      ret
      (loop (fx+ i 1) (let ((name "") (address ""))
        (if ((c-lambda (int char-string char-string) bool
                       "___result=bluetooth_getremoteaddress(___arg1,___arg2,___arg3);") i name address)
          (append ret (list name address))
          ret
        )
      ))
    )
  ))

(define bluetooth:error (c-lambda () int "bluetooth_error"))
(define bluetooth:timeout (c-lambda () int "bluetooth_timeout"))
(define (bluetooth-error) (not (fx= (bluetooth:error) 0)))
(define (bluetooth-timeout) (not (fx= (bluetooth:timeout) 0)))

(define bluetooth-open (c-lambda (char-string) int "bluetooth_open"))
(define bluetooth-close (c-lambda (int) void "bluetooth_close"))
(define bluetooth-readchar (c-lambda (int) int "bluetooth_readchar"))
(define bluetooth-writechar (c-lambda (int int) void "bluetooth_writechar"))
(define bluetooth-flush (c-lambda (int) void "bluetooth_flush"))

;;eof
