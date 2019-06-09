;decides to which co-routine will be executed next, in a round-robin manner.
;ebx<-the pointer to the thread
;save the current state
global targetDestroyed

section .rodata
  winnerFormat: db "Drone id %d: I am a winner", 10, 0

section .data
  idCURR: dd 1  ;1->N
  steps: dd 0
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
  extern endCo
  extern printf

scheduler_routine:
  mov byte [targetDestroyed], 0
  mov eax, [numofDrones]
  cmp [idCURR], eax
  je first_drone
  add dword [idCURR], 1
  mov eax, COSZ
  mov ebx, [idCURR]
  mul ebx  ;eax<-idCURR*COSZ
  add eax, CORS
  mov ebx, eax
  call resume
  jmp after_droneroutine
first_drone:
  mov dword ebx, [CORS]
  call resume
;when back fron drone routine, we'll be in this code
after_droneroutine:  ;check if need to print the board
  add dword [steps], 1
  mov eax, [steps]
  cmp eax, [K]
  je printBoard
  jmp check_drone_won  ;no need to print now, jmp right to check
printBoard:
  mov dword [steps], 0
  mov ebx, printerCO
  call resume
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
  mov ebx, target_routine
  call resume
  jmp scheduler_routine  ;return address from target routine
