global printer_routine

section .rodata
  printTargetFormat: db "%.2f,%.2f", 10, 0    ;x,y
  printDroneFormat: db "%d,%.2f,%.2f,%.2f,%d", 10, 0  ;id,x,y,alpha,destoyedTargets
  printDecFormat: db "%d,", 0
  printDecWithNewLineFormat: db "%d",10, 0
  printFloatFormat: db "%.2f", 0

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
  extern printerHelper
  ;C library functions
  extern printf

printer_routine:
  ;TODO: UNCOMMENT!
  push dword [targetY + 4]
  push dword [targetY]
  push dword [targetX + 4]
  push dword [targetX]
  push printTargetFormat
  call printf
  mov ecx, 0
  .printDrone:
    ;TODO: PROBLEM IN STACK POINTER HERE
    mov eax, COSZ
    mul ecx  ;eax<-ecx*COSZ
    mov eax, [CORS+eax] ;get pointer to COi (i=ecx) struct
    add eax, 4        ;eax is the pointer to the stack
    mov [printerHelper], eax
    ;TODO: uncomment!
    push dword [eax + 8]    ;dronesDestroyedTargets
    push dword [eax + 16]   ;second part of alpha
    push dword [eax + 12]   ;alpha
    push dword [eax + 24]   ;second part of y
    push dword [eax + 20]   ;y
    push dword [eax + 32]   ;second part of x
    push dword [eax + 28]   ;x
    push dword [eax + 4]    ;id
    push printDroneFormat
    call printf
    ;CHECKING!
    ;mov eax, dword [pointerToStack]
    ;push dword [eax + 4]
    ;push printDecWithNewLineFormat
    ;call printf
    add ecx, 1
    cmp ecx, dword [numofDrones]
    jl .printDrone
  mov ebx, schedulerCO
  call resume
  jmp printer_routine
