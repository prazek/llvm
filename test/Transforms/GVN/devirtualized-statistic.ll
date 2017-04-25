; REQUIRES asserts
; RUN: opt < %s -O2 -S -stats | FileCheck %s

; CHECK-LABEL: define void @devirtualize(i8* %p)
define void @devirtualize(i8* %p) {
  %x = bitcast i8* %p to void()**
  store void()* @foo, void()** %x
  %c = load void()*, void()** %x
  call void %c()
  call void @foo()
  call void %c()
  ret void
}

define void @setPointer(void()** %x) {
  store void()* @foo, void()** %x
  ret void
}

define void @devirtualize2(i8* %p) {
  %x = bitcast i8* %p to void()**
  call void @setPointer(void()** %x)
  %c = load void()*, void()** %x
  call void %c()
  call void @foo()
  call void %c()
  ret void
}



declare void @foo()