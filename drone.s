global drone_routine
global dronesDestroyedTargets
global dronesAlpha
global dronesX
global dronesY
global dronesId

section .rodata
  printFloatFormat: db "x: %.2f", 10, 0
  printFloatY: db "y: %.2f", 10, 0
  printFloatR: db "r: %.2f", 10, 0
  printRandAng: db "randAng: %.2f", 10, 0
  printAlpha: db "alphaBeforeShitHappends: %.2f", 10, 0

section .data
  dronesMayDestroyHelper: dd 0
  dronesRandRetHelper: dd 0
  dronesRandAngleF: dq 0.0
  dronesRandDistance: dq 0.0
  dronesAlpha: dq 0.0
  dronesX: dq 0.0
  dronesY: dq 0.0
  dronesNewAlphaInRad: dq 0.0
  dronesDestroyedTargets: dd 0
  dronesId: dd 0
  mayDestroyAlphaHelper: dq 0.0
  mayDestroyGamma: dq 0
  junkHelper: dq 0.0
  junkDword: dd 0

section .text
  align 16
  extern generate_rand
  extern numofTargets
  extern target_routine
  extern printf
  extern quit
  extern schedulerCO
  extern resume
  extern targetX
  extern targetY
  extern beta
  extern d
  extern randWord
  extern targetDestroyed

drone_routine: ;the code for drone co-routine
  pop dword [dronesId]
  pop dword [dronesDestroyedTargets]
  pop dword [dronesAlpha+4]
  pop dword [dronesAlpha]
  pop dword [dronesY+4]
  pop dword [dronesY]
  pop dword [dronesX+4]
  pop dword [dronesX]

  ;push dword [dronesX + 4]
  ;push dword [dronesX]
  ;push printFloatFormat
  ;call printf

  ;push dword [dronesY + 4]
  ;push dword [dronesY]
  ;push printFloatY
  ;call printf

  ;push dword [dronesAlpha + 4]
  ;push dword [dronesAlpha]
  ;push printAlpha
  ;call printf

  pushad
  pushfd
  call generate_rand
  ;mov dword [dronesRandRetHelper] eax
  popfd
  popad
  .deb:
  finit
  mov eax, 0
  mov ax, word [randWord]
  mov dword [junkDword], eax
  fild dword [junkDword]  ;the angle itself
  push 65535   ;max short
  fidiv dword [esp]
  pop eax
  push 120
  fimul dword [esp]          ;to get [0, 120]
  pop eax
  push 60
  fisub dword [esp]           ;to get [-60,60]
  pop eax
  ;pop value into dronesRandAngleF
  fstp qword [dronesRandAngleF]

  ;push dword [dronesRandAngleF + 4]
  ;push dword [dronesRandAngleF]
  ;push printRandAng
  ;call printf

  pushad
  pushfd
  call generate_rand
  ;pop dword [dronesRandRetHelper]
  popfd
  popad
  mov eax, 0
  mov ax, word [randWord]
  mov dword [junkDword], eax
  fild dword [junkDword]  ;the angle itself
  push 65535   ;max int
  fidiv dword [esp]
  pop eax
  push 50
  fimul dword [esp]          ;to get [0, 50]
  pop eax
  fstp qword [dronesRandDistance]

  ;push dword [dronesRandDistance + 4]
  ;push dword [dronesRandDistance]
  ;push printFloatR
  ;call printf

  mov eax, dronesAlpha ;pointer to old alpha is on eax for now
  ;make new alpha in [0,360]
  fld qword [dronesRandAngleF]
  fadd qword [eax]
  push 360
  fild dword [esp]
  pop esi  ;clean stack
  fcomi      ;cmp [dronesRandAngleF] and 360
  jb .biggerThan360
  fstp qword [junkHelper]    ;clean stack
  fldz    ;loads +0.0
  fcomi     ;cmp [dronesRandAngleF] and 0
  ja .lowerThan0
  fstp qword [junkHelper]
  jmp .angleIsCool
  .biggerThan360:
    push 360
    fstp qword [junkHelper]    ;clean stack
    fisub dword [esp]    ;minus 360
    pop esi
    jmp .angleIsCool
  .lowerThan0:
    push 360
    fstp qword [junkHelper]    ;clean stack
    fiadd dword [esp]    ;plus 360
    pop esi
    jmp .angleIsCool
  .angleIsCool:
    fstp qword [dronesAlpha]   ;new alpha in this label
    ;calculate dx and dy
    mov ebx, dronesX
    mov ecx, dronesY
    fld qword [dronesAlpha]
    fldpi
    fmul
    push 180
    fidiv dword [esp]    ;alphaInRad = alphaInDeg*pi/180
    pop esi
    fstp qword [dronesNewAlphaInRad]
    fld qword [dronesNewAlphaInRad]
    fcos
    fld qword [dronesRandDistance]
    fmul  ;dx=d*cos(alpha)
    fld qword [ebx]
    fadd   ;new_x=dx+old_x
    ;in fstack we got old_x+something, can be over 100 or below 0 (can it be below 0? nvm)
    ;make sure that new x is in [0,100]
    push 100
    fild dword [esp]
    pop eax   ;clean stack
    fcomi    ;cmp x and 100
    jb .xBiggerThan100
    fstp qword [junkHelper]
    push 0
    fild dword [esp]
    pop eax    ;clean stack
    fcomi      ;cmp x and 0
    ja .xLowerThan0
    jmp .xIsOk
  .xBiggerThan100:
    fstp qword [junkHelper]
    push 100
    fisub dword [esp]
    fild dword [esp]
    pop eax
    jmp .xIsOk
  .xLowerThan0:
    fstp qword [junkHelper]
    push 100
    fiadd dword [esp]
    fild dword [esp]
    pop eax
  .xIsOk:
    ;TODO: next 2 lines seems odd. CHECK!
    fstp qword [junkHelper]   ;clean junk
    fstp qword [dronesX]     ;updates x!
    fld qword [dronesNewAlphaInRad]
    fsin
    fld qword [dronesRandDistance]
    fmul   ;dy=d*sin(alpha)
    fld qword [ecx]
    fadd   ;new_y=dy+old_y
    ;in fstack we got old_y+something, can be over 100 or below 0 (can it be below 0? nvm)
    ;make sure that new y is in [0,100]
    push 100
    fild dword [esp]
    pop eax   ;clean stack
    fcomi     ;cmp y and 100
    jb .yBiggerThan100
    fstp qword [junkHelper]
    push 0
    fild dword [esp]
    pop eax    ;clean stack
    fcomi    ;cmp y and 0
    ja .yLowerThan0
    jmp .yIsOk
  .yBiggerThan100:
    fstp qword [junkHelper]
    push 100
    fisub dword [esp]
    fild dword [esp]
    pop eax
    jmp .yIsOk
  .yLowerThan0:
    fstp qword [junkHelper]
    push 100
    fiadd dword [esp]
    fild dword [esp]
    pop eax
  .yIsOk:
    fstp qword [junkHelper]   ;clean junk
    fstp qword [dronesY]     ;updates y!
  pushad
  pushfd
  call mayDestroy
  mov dword [dronesMayDestroyHelper], eax
  popfd
  popad
  cmp dword [dronesMayDestroyHelper], 0
  je .end
  ;destroy the target
  add dword [dronesDestroyedTargets], 1
  mov byte [targetDestroyed], 1  ;the flag to the scheduler

  ;assumes that number of destroyed targets for this drone in eax
  ;cmp eax, dword [numofTargets]
  ;jge .win
  .end:
    push dword [dronesX] ;x
    push dword [dronesX+4]   ;next part of x
    push dword [dronesY] ;y
    push dword [dronesY+4]
    push dword [dronesAlpha]
    push dword [dronesAlpha+4]
    push dword [dronesDestroyedTargets]
    push dword [dronesId]
    ;new code:
    mov ebx, schedulerCO
    call resume
    jmp drone_routine  ;this is the return address
  ;call target_routine
  ;.win:
    ;wow!!! you won!!!!
    ;pushad
    ;pushfd
    ;push dword [dronesId]
    ;push winnerFormat
    ;call printf
    ;add esp, 4
    ;pop eax
    ;popfd
    ;popad
    ;jmp quit
  ;.end:
  ;push dword [dronesX] ;x
  ;push dword [dronesX+4]   ;next part of x
  ;push dword [dronesY] ;y
  ;push dword [dronesY+4]
  ;push dword [dronesAlpha]
  ;push dword [dronesAlpha+4]
  ;push dword [dronesDestroyedTargets]
  ;push dword [dronesId]
  ;mov ebx, schedulerCO
  ;call resume
  ;jmp drone_routine  ;this is the return address

;returns dword 0 or 1 in the stack
mayDestroy:
  mov ebx, dronesX
  mov ecx, dronesY
  mov edx, targetX
  mov esi, targetY
  push dword [dronesNewAlphaInRad]
  push dword [dronesNewAlphaInRad+4]
  pop dword [mayDestroyAlphaHelper+4]
  pop dword [mayDestroyAlphaHelper]
  finit
  fld qword [ecx]
  fsub qword [esi]
  fld qword [ebx]
  fsub qword [edx]
  ;in st0: x2-x1, in st1: y2-y1
  fpatan
  fstp qword [mayDestroyGamma]
  .calc:
  finit
  mov eax, mayDestroyAlphaHelper
  fld qword [eax]
  fsub qword [mayDestroyGamma]
  fabs
  fldpi
  fcomi   ;cmp pi, (alpha-gamma)
  jb .greaterThanPi
  jmp .coolWithPi
  .greaterThanPi:
    finit
    fld qword [mayDestroyGamma]
    fld qword [dronesNewAlphaInRad]
    fcomi
    ja .alphaIsBigger
    jmp .gammaIsBigger
    ;adding 2pi to the smaller angle and calc again
    .alphaIsBigger:
      ;somehow it's in infinte loop here
      finit
      fldpi
      push 2
      fimul dword [esp]
      pop eax
      fld qword [mayDestroyGamma]
      fadd
      fstp qword [mayDestroyGamma]
      jmp .computeAgain
    .gammaIsBigger:
      finit
      fldpi
      push 2
      fimul dword [esp]
      pop eax
      fld qword [mayDestroyAlphaHelper]
      fadd
      fstp qword [mayDestroyAlphaHelper]
    .computeAgain:
      jmp .calc
  .coolWithPi:
  fstp qword [junkHelper]
  fild dword [beta]
  fcomi
  ja .otherCond
  jmp .retFalse
  .otherCond:
  fld qword [ecx]
  fsub qword [esi]
  fld qword [ecx]
  fsub qword [esi]
  fmulp
  fld qword [ebx]
  fsub qword [edx]
  fld qword [ebx]
  fsub qword [edx]
  fmulp
  ;in st0: (x2-x1)^2, in st1: (y2-y1)^2
  faddp
  fsqrt
  fild dword [d]
  fcomi
  ja .retTrue
  jmp .retFalse
  .retTrue:
  mov eax, 1
  ret
  .retFalse:
  mov eax, 0
  ret
