; RUN: opt -licm < %s

; This test check if nothing explodes if invariant.group.barrier of null is
; reduced to null.
; Function Attrs: nounwind uwtable
define fastcc void @_ZN12_GLOBAL__N_117GlobalISelEmitter3runERN4llvm11raw_ostreamE() unnamed_addr align 2 {
entry:
  switch i8 undef, label %if.end8.i.i [
    i8 0, label %if.then.i.i3
    i8 1, label %if.then4.i.i
  ]

if.then.i.i3:                                     ; preds = %entry
  br label %for.body

if.then4.i.i:                                     ; preds = %entry
  unreachable

if.end8.i.i:                                      ; preds = %entry
  unreachable

for.body:                                         ; preds = %for.cond66.i.i.for.end151.i.i_crit_edge, %if.then.i.i3
  br label %for.body69.i.i

for.body69.i.i:                                   ; preds = %for.body69.i.i, %for.body
  %0 = call i8* @llvm.invariant.group.barrier(i8* null) #2, !noalias !1
  br i1 undef, label %for.cond66.i.i.for.end151.i.i_crit_edge, label %for.body69.i.i

for.cond66.i.i.for.end151.i.i_crit_edge:          ; preds = %for.body69.i.i
  br label %for.body
}

; Function Attrs: inaccessiblememonly nounwind
declare i8* @llvm.invariant.group.barrier(i8*) #1

attributes #1 = { inaccessiblememonly nounwind }
attributes #2 = { nounwind }

!1 = !{!2}
!2 = distinct !{!2, !3, !"_ZN4llvm5Error11takePayloadEv: %agg.result"}
!3 = distinct !{!3, !"_ZN4llvm5Error11takePayloadEv"}
