;decides to which co-routine will be executed next, in a round-robin manner.
;ebx<-the pointer to the thread
;save the current state
section .text
  global scheduler_routine
  extern CORS

scheduler_routine:



  mov ebx, [ebp+8] ; get co-routine ID number
  mov ebx, [4*ebx + CORS] ; get pointer to COi struct
  mov eax, [ebx+CODEP] ; get initial EIP value – pointer to COi function
  mov [SPT], ESP ; save ESP value
  mov esp, [EBX+4] ; get initial ESP value – pointer to COi stack
  push eax ; push initial “return” address
  pushfd ; push flags
  pushad ; push all other registers
  mov [ebx+4], esp ; save new SPi value (after all the pushes)
  mov ESP, [SPT]
