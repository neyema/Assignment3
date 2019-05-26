;Generates rand number between 1 and max int
generate_rand:
  mov eax, [seed]   ;eax is lfsr
  mov ebx, 0    ;bit will be in bx
  mov esi, 0    ;period will be in esi
  .doLoop:
  ;calculate bit
  mov ebx, eax
  shr ebx, 0
  mov edx, eax
  shr edx, 2
  xor ebx, edx
  mov edx, eax
  shr edx, 3
  xor ebx, edx
  mov edx, eax
  shr edx, 5
  xor ebx, edx
  ;calculate lfsr
  mov ecx, eax
  shr ecx, 1
  mov edx, ebx
  shl ebx, 15
  or ecx, edx
  mov ecx, eax
  add esi, 1
  cmp eax, [seed]
  jne .doLoop
  push esi ;push period to return it
  ret

;returns dword 0 or 1 in the stack
mayDestroy:
  ;needs Y, X and alpha somehow
  ;assumes pointer to alpha is in eax
  ;assumes pointer to X is in ebx
  ;assumes pointer to Y is in ecx
  ;assumes pointer to X of target in edx
  ;assumes pointer to Y of target in esi

  ret

drone_routine: ;the code for drone co-routine
  pushad
  pushfd
  call generate_rand
  pop dword [dronesRandRetHelper]
  popfd
  popad
  finit
  fild dword [dronesRandRetHelper]  ;the angle itself
  push 2147483647   ;max int
  fidiv [esp]
  pop eax
  push 120
  fimul [esp]          ;to get [0, 120]
  pop eax
  push 60
  fisub [esp]           ;to get [-60,60]
  pop eax
  ;pop value into dronesRandAngleF
  fstp [dronesRandAngleF]
  pushad
  pushfd
  call generate_rand
  pop dword [dronesRandRetHelper]
  popfd
  popad
  fild dword [dronesRandRetHelper]  ;the angle itself
  push 2147483647   ;max int
  fidiv [esp]
  pop eax
  push 50
  fmul [esp]          ;to get [0, 50]
  pop eax
  ;pop value into dronesRandDistance
  fstp [dronesRandDistance]
  ;TODO: get alpha to eax
  ;assumes that pointer to old alpha is on eax for now
  fild [dronesRandAngleF]
  fadd dword [eax]
  push 360
  fild [esi]
  pop esi    ;clean stack
  ucomiss st1, st0   ;cmp eax and 360
  jb biggerThan360
  fstp esi    ;clean stack
  fldz    ;loads +0.0
  ucomiss st1, st0
  ja lowerThan0
  jmp angleIsCool
  .biggerThan360:
    push 360
    fstp esi    ;clean stack
    fisub [esi]    ;minus 360
    pop esi
    jmp .angleIsCool
  .lowerThan0:
    push 0
    fstp esi    ;clean stack
    fiadd [esi]    ;plus 360
    pop esi
    jmp .angleIsCool
  .angleIsCool:
    fstp [dronesRandAngleF]   ;new alpha in this label
    ;mov [dronesRandAngleF] into alpha (update it)
    ;calculate dx and dy
    ;assumes that pointer to x is in ebx
    ;assumes that pointer to y is in ecx
    fild [dronesRandAngleF]
    fcos st0
    fild [dronesRandDistance]
    fmul st0, st1   ;dx=d*cos(alpha)
    fild [ebx]
    fadd st0, st1   ;new_x=dx+old_x
    ;fstp [x]     ;TODO: UNCOMMET IT. updates x!
    finit
    fild [dronesRandAngleF]
    fsin st0
    fild [dronesRandDistance]
    fmul st0, st1   ;dy=d*sin(alpha)
    fild [ecx]
    fadd st0, st1    ;new_y=dy+old_y
    ;fstp [y]     ;TODO: UCOMMENT IT. updates y!
    ;TODO: fix overflow/undeflow X/Y
  pushad
  pushfd
  call mayDestroy
  pop dword [dronesMayDestroyHelper]
  popfd
  popfd
  cmp dword [dronesMayDestroyHelper], 0
  je .end
  ;TODO: HERE, destroy the targetttt, check if there's a win and finish if theere is
  .end:
  ;call resume
