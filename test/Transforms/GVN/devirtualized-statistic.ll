; REQUIRES asserts
; RUN: opt < %s -O2 -S -stats 2>&1 | FileCheck %s

; CHECK-LABEL: define void @devirtualize
define void @devirtualize(i8* %p) {
  %x = bitcast i8* %p to void()**
  store void()* @foo, void()** %x
  %c = load void()*, void()** %x
; 2 devirtualizations here
; CHECK: call void @foo()
; CHECK: call void @foo()
; CHECK: call void @foo()
  call void %c()
  call void @foo()
  call void %c()
  ret void
}

define void @setPointer(void()** %x) {
  store void()* @foo, void()** %x
  ret void
}
; CHECK-LABEL: define void @devirtualize2
define void @devirtualize2(i8* %p) {
  %x = bitcast i8* %p to void()**
  call void @setPointer(void()** %x)
  %c = load void()*, void()** %x
; 2 devirtualizations here
; CHECK: call void @foo()
; CHECK: call void @foo()
; CHECK: call void @foo()
  call void %c()
  call void @foo()
  call void %c()
  ret void
}

; CHECK-LABEL: define void @partialDevirtualize
define void @partialDevirtualize(i8* %p) {
  %x = bitcast i8* %p to void()**
  %c = load void()*, void()** %x
  %d = load void()*, void()** %x
; 3 partial devirtualizations here
; CHECK: call void %c()
; CHECK: call void %c()
; CHECK: call void %c()
; CHECK: call void %c()
; CHECK: call void %c()
  call void %c()
  call void %d()
  call void %c()
  call void %d()
  call void %d()

  ret void
}



declare void @foo()
; CHECK-LABEL: Statistics Collected
; CHECK:{{.*}}4 ir {{.*}}Number of indirect calls devirtualized
; CHECK:{{.*}}3 ir {{.*}}Number indirect calls partially devirtualized
