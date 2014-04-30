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

;; OpenGL screenshot function
(c-declare  #<<end-of-c-declare

#include <stdio.h>            
#include <stdlib.h> 

int glcore_screenshot(const char * filename, int width, int height){
  int i;
  int len=width*height*3;
  static unsigned char header[54] = {
    0x42, 0x4D, 			        //BM
    0x00, 0x00, 0x00, 0x00, 	//size in bytes
    0x00, 0x00, 			        //reserved
    0x00, 0x00, 			        //reserved
    0x36, 0x00, 0x00, 0x00, 	//starting address
    0x28, 0x00, 0x00, 0x00, 	//size of header
    0x00, 0x00, 0x00, 0x00, 	//width in px
    0x00, 0x00, 0x00, 0x00, 	//height in px
    0x01, 0x00, 			        //number of color planes [1]
    0x18, 0x00, 			        //number of bits per pixed [24]
    0x00, 0x00, 0x00, 0x00,  	//compression method used [none]
    0x00, 0x00, 0x00, 0x00, 	//image size of raw bitmap data
    0x13, 0x0B, 0x00, 0x00, 	//horizontal resolution in px/m
    0x13, 0x0B, 0x00, 0x00, 	//vertical resolution in px/m
    0x00, 0x00, 0x00, 0x00, 	//number of colors [0]
    0x00, 0x00, 0x00, 0x00};	//colors used [ignored]
  
  // Populate the header
  unsigned char *px = (unsigned char *) malloc(len);
  glReadPixels(0,0,width,height,GL_RGB,GL_UNSIGNED_BYTE,px);
  int flen=len+54;
  header[2] = (unsigned char)(flen);
  header[3] = (unsigned char)(flen>>8);
  header[4] = (unsigned char)(flen>>16);
  header[5] = (unsigned char)(flen>>24);
  header[18] = (unsigned char)(width);
  header[19] = (unsigned char)(width>> 8);
  header[20] = (unsigned char)(width>>16);
  header[21] = (unsigned char)(width>>24);
  header[22] = (unsigned char)(height);
  header[23] = (unsigned char)(height>> 8);
  header[24] = (unsigned char)(height>>16);
  header[25] = (unsigned char)(height>>24); 

  // Switch the R&B order
  unsigned char tmp;
  for (i=0;i<len;i+=3){
    tmp = px[i];
    px[i] = px[i+2];
    px[i+2] = tmp;
  }
  
  // Write data to file
  FILE *fid = fopen(filename, "w");
  if (fid){
    fwrite (header,sizeof(char),sizeof(header), fid);
    fwrite (px,sizeof(char),len, fid);
    fclose(fid);
    free(px);
    return 1;
  }
  return 0;
}

end-of-c-declare
)

(define (glcore-screenshot fname)
  ((c-lambda (char-string int int) bool
    "___result=glcore_screenshot(___arg1,___arg2,___arg3);")
    (string-append (system-appdirectory) (system-pathseparator) fname ".bmp")
    (glgui-width-get) (glgui-height-get))
)
