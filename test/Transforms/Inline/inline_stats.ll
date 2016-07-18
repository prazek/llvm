; RUN: opt -S -inline -enable-import-graph-stats -enable-list-stats < %s 2>&1 | FileCheck %s

; CHECK: Inlined not external function [internal2]: #inlines = 5, #real_inlines = 1
; CHECK: Inlined imported function [external2]: #inlines = 3, #real_inlines = 1
; CHECK: Inlined imported function [external1]: #inlines = 1, #real_inlines = 1
; CHECK: Inlined imported function [external3]: #inlines = 1, #real_inlines = 0

; CHECK: Number of inlined imported functions: 3
; CHECK: Number of real inlined imported functions: 2
; CHECK: Number of real not external inlined functions: 1

define void @internal() {
    call fastcc void @external1()
    call coldcc void @external_big()
    ret void
}

define void @internal2() alwaysinline {
    ret void
}

define void @external1() alwaysinline !thinlto_src_module !0 {
    call fastcc void @internal2()
    call fastcc void @external2();
    ret void
}

define void @external2() alwaysinline !thinlto_src_module !1 {
    ret void
}


define void @external3() alwaysinline !thinlto_src_module !1 {
    ret void
}

; Assume big pice of code here. This function won't be inlined, so all the
; inlined function it will have won't affect real inlines.
define void @external_big() noinline !thinlto_src_module !1 {
; CHECK-NOT: call fastcc void @internal2()
    call fastcc void @internal2()
    call fastcc void @internal2()
    call fastcc void @internal2()
    call fastcc void @internal2()

; CHECK-NOT: call fastcc void @external2()
    call fastcc void @external2()
    call fastcc void @external2()
; CHECK-NOT: call fastcc void @external3()
    call fastcc void @external3()
    ret void
}

; It should not be imported, but it should not break anything.
define void @external_notcalled() !thinlto_src_module !0 {
    call void @external_notcalled()
    ret void
}

!0 = !{!"file.cc"}
!1 = !{!"other.cc"}
