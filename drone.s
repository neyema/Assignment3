;Generates rand number between 1 and max int
generate_rand:
  mov eax, [randStartState]   ;eax is lfsr
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
  cmp eax, [randStartState]
  jne .doLoop
  push esi ;push period to return it
  ret

;returns 0 or 1 in the stack
mayDestroy:
  ;needs Y, X and alpha somehow
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
  fidiv st0, 2147483647   ;max int
  fmul 120          ;to get [0, 120]
  fsub 60           ;to get [-60,60]
  ;pop value into dronesRandAngleF
  fstp [dronesRandAngleF]
  pushad
  pushfd
  call generate_rand
  pop dword [dronesRandRetHelper]
  popfd
  popad
  finit
  fild dword [dronesRandRetHelper]  ;the angle itself
  fidiv st0, 2147483647   ;max int
  fmul 50          ;to get [0, 120]
  ;pop value into dronesRandDistance
  fstp [dronesRandDistance]
  ;TODO: get alpha to eax
  ;assumes that pointer to alpha is on eax for now
  fild dronesRandAngleF
  fadd st0, [eax]  ;should be tenword or something like that near eax
  fild 360
  ucomiss [eax], st0   ;cmp eax and 360
  jb biggerThan360
  fldz    ;loads +0.0
  ucomiss [eax], st0
  ja lowerThan0
  jmp angleIsCool
  .biggerThan360:
    sub eax, 360   ;TODO: TURN TO FPOINT
    jmp .angleIsCool
  .lowerThan0:
    add eax, 360  ;TODO: TURN TO FPOINT
    jmp .angleIsCool
  .angleIsCool:
    ;mov [dronesRandAngleF] into alpha (update it)
    ;calculate dx and dy
    ;assumes that pointer to x is in ebx
    ;assumes that pointer to y is in ecx
    finit
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
