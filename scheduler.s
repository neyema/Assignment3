;decides to which co-routine will be executed next, in a round-robin manner.
;ebx<-the pointer to the thread
;save the current state

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
  extern printerCO
  extern endCo

section .data
  idCURR: dd 1  ;1->N
  steps: dd 0

scheduler_routine:
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
;the drone will get to this code
after_droneroutine:
  mov eax, [steps]
  cmp eax, [K]
  je printBoard
  add dword [steps], 1
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
  cmp dword eax, [K]
  jge endCo
  jmp scheduler_routine
