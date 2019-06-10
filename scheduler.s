;decides to which co-routine will be executed next, in a round-robin manner.
;ebx<-the pointer to the thread
;save the current state
global targetDestroyed
global idCURR
global steps

section .rodata
  winnerFormat: db "Drone id %d: I am a winner", 10, 0

section .data
  idCURR: dd 0  ;1->N
  steps: dd -1  ;it's not really. it starts as k
  targetDestroyed: db 0  ;boolean, 0 if target have not destroyed, 1 if destroyed

section .text
  align 16
  global scheduler_routine
  extern resume
  extern do_resume
  extern CORS
  extern COSZ
  extern K
  extern numofDrones
  extern numofTargets
  extern dronesDestroyedTargets
  extern printerCO
  extern target_routine
  extern targetCO
  extern endCo
  extern printf



scheduler_routine:
  cmp dword [idCURR], 0
  jne .dontMakeStepsBigger
  add dword [steps], 1
  .dontMakeStepsBigger:
  add dword [idCURR], 1
  mov eax, dword [idCURR]
  cmp eax, [numofDrones]
  jle .doNotMakeOne
  mov dword [idCURR], 1
  add dword [steps], 1
  .doNotMakeOne:
  cmp dword [idCURR], 1
  jg .doNotPrint
  cmp dword [steps], 0
  je .print
  mov edx, 0
  mov eax, 0
  mov ebx, 0
  mov ax, [steps]
  mov bx, [K]
  div bx ;remainder in DX
  cmp word dx, 0
  jne .doNotPrint
  .print:
  mov ebx, printerCO
  call resume
  .doNotPrint:
  cmp dword [idCURR], 2
  je .itsTwo
  jmp .notTwo
  .itsTwo:
  nop
  .notTwo:
  mov byte [targetDestroyed], 0
  mov eax, [numofDrones]
  mov ecx, dword [idCURR]
  sub ecx, 1
  mov eax, COSZ
  mul ecx  ;eax<-ecx*COSZ
  add eax, [CORS]  ;eax<-the pointer to the routine in CORS
  mov ebx, eax
  call resume
;when back fron drone routine, we'll be in this code
check_drone_won:
  cmp byte [targetDestroyed], 0
  je scheduler_routine
  ;so targetDestroyed=1, need to check if he won
  mov eax, [dronesDestroyedTargets]
  cmp dword eax, [numofTargets]
  jl createTarget  ;the drone not won, but target destryoed
  ;if we got here, the current drone won
  pushad
  pushfd
  mov dword eax, [idCURR]
  sub eax, 1
  push dword eax
  push winnerFormat
  call printf
  add esp, 4
  pop eax
  popfd
  popad
  jmp endCo
createTarget:
  mov ebx, targetCO
  call resume
jmp scheduler_routine ;return address from target routine
