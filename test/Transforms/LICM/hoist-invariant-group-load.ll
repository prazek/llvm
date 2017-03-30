; RUN: opt < %s -licm -disable-basicaa -S < %s | FileCheck %s

%struct.A = type { i32 (...)** }

; CHECK-LABEL: define void @hoist
define void @hoist(%struct.A* dereferenceable(8)) {
entry:
  %call1 = tail call i32 @_Z3barv()
  %tobool2 = icmp eq i32 %call1, 0
  br i1 %tobool2, label %while.end, label %while.body.lr.ph

while.body.lr.ph:                                 ; preds = %entry
  %b = bitcast %struct.A* %0 to void (%struct.A*)***
; CHECK:   %vtable = load {{.*}} %b, align 8, !dereferenceable {{.*}}, !invariant.group
; CHECK-NEXT:  %1 = load void (%struct.A*)*, void (%struct.A*)** %vtable, align 8, !invariant.load
; CHECK-NEXT:  br label %while.body
  br label %while.body
; CHECK-NOT: load
while.body:                                       ; preds = %while.body.lr.ph, %while.body
  %vtable = load void (%struct.A*)**, void (%struct.A*)*** %b, align 8, !dereferenceable !1, !invariant.group !0
  %1 = load void (%struct.A*)*, void (%struct.A*)** %vtable, align 8, !invariant.load !0
  tail call void %1(%struct.A* %0)
  %call = tail call i32 @_Z3barv()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %while.end.loopexit, label %while.body

while.end.loopexit:                               ; preds = %while.body
  br label %while.end

while.end:                                        ; preds = %while.end.loopexit, %entry
  ret void
}


declare i32 @_Z3barv()

; CHECK-LABEL: define void @dontHoist
define void @dontHoist(%struct.A** %a) {
entry:
  %call4 = tail call i32 @_Z3barv()
  %cmp5 = icmp sgt i32 %call4, 0
  br i1 %cmp5, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  br label %for.body

for.cond.cleanup.loopexit:                        ; preds = %for.body
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  ret void

; CHECK: for.body:
for.body:                                         ; preds = %for.body.preheader, %for.body
; CHECK: load {{.*}} !invariant.group
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %for.body.preheader ]
  %arrayidx = getelementptr inbounds %struct.A*, %struct.A** %a, i64 %indvars.iv
  %0 = load %struct.A*, %struct.A** %arrayidx, align 8
  %1 = bitcast %struct.A* %0 to void (%struct.A*)***
  %vtable = load void (%struct.A*)**, void (%struct.A*)*** %1, align 8, !dereferenceable !1, !invariant.group !0
  %2 = load void (%struct.A*)*, void (%struct.A*)** %vtable, align 8, !invariant.load !0
  tail call void %2(%struct.A* %0)
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  %call = tail call i32 @_Z3barv()
  %3 = sext i32 %call to i64
  %cmp = icmp slt i64 %indvars.iv.next, %3
  br i1 %cmp, label %for.body, label %for.cond.cleanup.loopexit
}


!0 = !{}
!1 = !{i64 8}