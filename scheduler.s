;decides to which co-routine will be executed next, in a round-robin manner.
;ebx<-the pointer to the thread
;save the current state
global targetDestroyed

section .text
  align 16
  global scheduler_routine
  global idCURR
  extern resume
  extern do_resume
  extern CORS
  extern COSZ
  extern K
  extern numofDrones
  extern numofTargets
  extern printerCO
  extern target_routine
  extern endCo

section .data
  idCURR: dd 1  ;1->N
  steps: dd 0
  targetDestroyed: db 0  ;boolean, 0 if target have not destroyed, 1 if destroyed

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
  mov ebx, [CORS]
  call resume
;when back fron drone routine, we'll be in this code
cmp byte [targetDestroyed], 0
je after_droneroutine
;so targetDestroyed=1, need to create target
mov ebx, target_routine
call resume
after_droneroutine:  ;check if need to print the board
  add dword [steps], 1
  mov eax, [steps]
  cmp eax, [K]
  je printBoard
  jmp check_drone_won
printBoard:
  mov dword [steps], 0
  mov ebx, printerCO
  call resume

;check if this drone won
check_drone_won:
  mov eax, [idCURR]
  mov ebx, COSZ
  mul ebx
  add eax, [CORS] ;eax<-CORS+idCURR*COSZ
  add eax, 4 ;stack pointer
  add eax, 12 ;discard x,y,angle
  mov eax, [eax]
  cmp dword eax, [numofTargets]
  jge endCo
  jmp scheduler_routine
