; RUN: opt  -instcombine -S < %s | FileCheck %s

; CHECK-LABEL: define i8* @siplifyNullBarrier()
define i8* @siplifyNullBarrier() {
; CHECK-NEXT: ret i8* null
  %b2 = call i8* @llvm.invariant.group.barrier(i8* null)
  ret i8* %b2
}

; CHECK-LABEL: define i8* @dontSiplifyNullBarrierForOtherAddressSpace()
define i8* @dontSiplifyNullBarrierForOtherAddressSpace() {
; CHECK-NEXT: %b2 = call i8* @llvm.invariant.group.barrier(i8* addrspace(4) null)
  %X = addrspacecast i8* null to i8 addrspace(1)*
  %b2 = call i8* @llvm.invariant.group.barrier(i8* %X)
  ret i8* %b2
}


; CHECK-LABEL: define i8* @siplifyUndefBarrier()
define i8* @siplifyUndefBarrier() {
; CHECK-NEXT: ret i8* undef
  %b2 = call i8* @llvm.invariant.group.barrier(i8* undef)
  ret i8* %b2
}

declare i8* @llvm.invariant.group.barrier(i8*)
