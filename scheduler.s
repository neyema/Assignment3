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
  extern N

section .data
  idCURR: dd 1  ;1->N
  steps: dd 0

scheduler_routine:
  mov eax, [N]
  cmp [idCURR], eax
  je first_drone
  add [idCURR], 1
  mov ebx, [CORS+idCURR*COSZ]
  call resume
  jmp after_droneroutine
  first_drone:
    mov ebx, [CORS]
    call resume
    jmp after_droneroutine  ;so that the drone will get to that code

after_droneroutine:
  ;print the board
  mov ebx, printerCO
  call resume
  jmp scheduler_routine
  ;check if this drone won
  mov eax, eax*COSZ  ;change these 2 lines to mov eax, [CORS+eax*COSZ]
  add eax, [CORS]
  add eax, 4 ;stack pointer
  add eax, 12 ;discard x,y,angle
  mov eax, [eax]
  cmp dword eax, [K]
  jge endCo
