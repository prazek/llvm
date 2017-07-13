; REQUIRES asserts
; RUN: opt < %s -O2 -S -stats 2>&1 | FileCheck %s

; CHECK-LABEL: define void @devirtualize
define void @devirtualize(i8* %p) {
  %x = bitcast i8* %p to void()**
  store void()* @foo, void()** %x
  %c = load void()*, void()** %x, !vfunction_load !0
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
  %c = load void()*, void()** %x, !vfunction_load !0
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
  %c = load void()*, void()** %x, !vfunction_load !0
  %d = load void()*, void()** %x, !vfunction_load !0
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

define i8 @vtableLoad(i8** %p) {
  %vtable = load i8*, i8** %p, !vtable_load !0, !invariant.group !0
  %x = load i8, i8* %vtable
  call void @foo()
  %vtable2 = load i8*, i8** %p, !invariant.group !0, !vtable_load !0

  %x2 = load i8, i8* %vtable2
  %x3 = add i8 %x, %x2
  ret i8 %x3
}



declare void @foo()
; CHECK-LABEL: Statistics Collected
; CHECK:{{.*}}4 ir {{.*}}Number of indirect calls devirtualized
; CHECK:{{.*}}3 ir {{.*}}Number of indirect calls partially devirtualized

!0 = !{}