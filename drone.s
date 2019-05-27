section .text
  align 16
  global drone_routine

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

;destorys the target
destroyTarget:

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
  fstp [dronesRandDistance]
  ;assumes that pointer to old alpha is on eax for now
  ;make new alpha in [0,360]
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
    fstp esi       ;clean junk
    ;assumes that pointer to old x is in ebx
    ;in fstack we got old_x+something, can be over 100 or below 0 (can it be below 0? nvm)
    ;make sure that new x is in [0,100]
    push 100
    fild [esp]
    pop eax   ;clean stack
    ucomiss st1, st0
    jb .xBiggerThan100
    fstp eax
    push 0
    fild [esp]
    pop eax    ;clean stack
    ucomiss st1, st0
    ja .xLowerThan0
    jmp .xIsOk
    .xBiggerThan100:
      fstp eax
      push 100
      fisub [esp]
      fild [esp]
      pop eax
      jmp .xIsOk
    .xLowerThan0:
      fstp eax
      push 100
      fiadd [esp]
      fild [esp]
      pop eax
    .xIsOk:
    fstp eax   ;clean junk
    ;fstp [x]     ;TODO: UNCOMMET IT. updates x!
    fild [dronesRandAngleF]
    fsin st0
    fild [dronesRandDistance]
    fmul st0, st1   ;dy=d*sin(alpha)
    fild [ecx]
    fadd st0, st1    ;new_y=dy+old_y
    fstp esi       ;clean junk
    ;in fstack we got old_y+something, can be over 100 or below 0 (can it be below 0? nvm)
    ;make sure that new y is in [0,100]
    push 100
    fild [esp]
    pop eax   ;clean stack
    ucomiss st1, st0
    jb .yBiggerThan100
    fstp eax
    push 0
    fild [esp]
    pop eax    ;clean stack
    ucomiss st1, st0
    ja .yLowerThan0
    jmp .yIsOk
    .yBiggerThan100:
      fstp eax
      push 100
      fisub [esp]
      fild [esp]
      pop eax
      jmp .yIsOk
    .yLowerThan0:
      fstp eax
      push 100
      fiadd [esp]
      fild [esp]
      pop eax
    .yIsOk:
    fstp eax   ;clean junk
    ;fstp [y]     ;TODO: UCOMMENT IT. updates y!
  pushad
  pushfd
  call mayDestroy
  pop dword [dronesMayDestroyHelper]
  popfd
  popad
  cmp dword [dronesMayDestroyHelper], 0
  je .end
  ;destroy the target
  pushad
  pushfd
  call destroyTarget
  popfd
  popad
  ;assumes that number of destroyed targets for this drone in eax
  cmp eax, [numofTargets]
  jge .win
  jmp .end
  .win:
    ;wow!!! you won!!!!
    ;assumes that id in eax
    push eax
    push winnerFormat
    call printf
    add esp, 4
    pop eax
    jmp quit
  .end:
  call resume

  ;returns dword 0 or 1 in the stack
  mayDestroy:
    ;TODO: GET RID OF THE ASSUMPTIONS!
    ;assumes pointer to X is in ebx
    ;assumes pointer to Y is in ecx
    ;assumes pointer to X of target in edx
    ;assumes pointer to Y of target in esi
    finit
    fild dword [ecx]
    fsub dword [esi]
    fild dword [ebx]
    fsub dword [edx]
    ;in st0: x2-x1, in st1: y2-y1
    fpatan
    fstp [mayDestroyGamma]
    ;assumes that pointer to alpha in eax
    fild dword [eax]
    fsub dword [mayDestroyGamma]
    fabs st0
    fild dword [beta]
    ucomiss st1, st0
    ja .otherCond
    jmp .retFalse
    .otherCond:
    fild dword [ecx]
    fsub dword [esi]
    fild dword[ecx]
    fsub dword [esi]
    fmulp
    fild dword [ebx]
    fsub dword [edx]
    fild dword [ebx]
    fsub dword [edx]
    fmulp
    ;in st0: (x2-x1)^2, in st1: (y2-y1)^2
    faddp
    fsqrt
    fild dword [d]
    ucomiss st1, st0
    ja .retTrue
    jmp .retFalse
    .retTrue:
    mov eax, 1
    push eax
    ret
    .retFalse:
    mov eax, 0
    push eax
    ret
