global printer_routine

section .data
  loopIndex: dd 0

section .rodata
  printTargetFormat: db "%.2f,%.2f", 10, 0    ;x,y
  printDroneFormat: db "%d,%.2f,%.2f,%.2f,%d", 10, 0  ;id,x,y,alpha,destoyedTargets
  printDecFormat: db "%d,", 0
  printDecWithNewLineFormat: db "%d",10, 0
  printFloatFormat: db "%.2f", 0
  wentHere: db "went there!", 10, 0
  wentHere2: db "went there2!", 10, 0

section .text:
  align 16
  extern STKSZ
  extern COSZ
  extern CORS
  extern targetX
  extern targetY
  extern numofDrones
  extern schedulerCO
  extern resume
  extern dronesDestroyedTargets
  extern dronesAlpha
  extern dronesX
  extern dronesY
  extern dronesId
  ;C library functions
  extern printf

printer_routine:
  push dword [targetY + 4]
  push dword [targetY]
  push dword [targetX + 4]
  push dword [targetX]
  push printTargetFormat
  call printf
  mov dword [loopIndex], 0
  .printDrone:
    mov ecx, dword [loopIndex]
    mov eax, COSZ
    mul ecx  ;eax<-ecx*COSZ
    add eax, [CORS]  ;eax<-the pointer to the routine in CORS
    mov eax, [eax+4]  ;eax is the value of the stack pointer
    add dword eax, 4    ;skip return address
    add dword eax, 32  ;32 bytes size of pushad
    add dword eax, 4   ;ef flags is 32 bit = 4 bytes
    pushad  ;these are in the printer stack, so we don't care about them now
    pushfd
    ;in order to reach the fields, saved in stack
    ;we need to skip on: retrun address, fd, ad
    push dword [eax + 4]    ;dronesDestroyedTargets
    push dword [eax + 8]   ;second part of alpha
    push dword [eax + 12]   ;alpha
    push dword [eax + 16]   ;second part of y
    push dword [eax + 20]   ;y
    push dword [eax + 24]   ;second part of x
    push dword [eax + 28]   ;x
    push dword [eax]    ;id
    push printDroneFormat
    call printf
    ;clean stack!
    pop dword eax
    pop dword eax
    pop dword eax
    pop dword eax
    pop dword eax
    pop dword eax
    pop dword eax
    pop dword eax
    add dword [loopIndex], 1
    mov ecx, [loopIndex]
    cmp ecx, dword [numofDrones]
    jl .printDrone
  mov ebx, schedulerCO
  call resume
jmp printer_routine
