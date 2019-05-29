section .text:
  align 16

printer_routine:
  push dword [targetY]
  push dword [targetX]
  push printTargetFormat
  call printf
  mov ecx, 0
  .printDrone:
    mov eax, [COSZ*ecx + CORS] ; get pointer to COi (i=ecx) struct
    add eax, 4                 ;eax is the pointer to the stack
    push dword [eax + 8]   ;dronesDestroyedTargets
    push dword [eax + 12]   ;alpha
    push dword [eax + 16]   ;second part of alpha
    ;TODO: convert from radians to degrees
    push dword [eax + 20]    ;y
    push dword [eax + 24]   ;second part of y
    push dword [eax + 28]    ;x
    push dword [eax + 32]   ;second part of x
    push dword [eax + 4]   ;id
    push printDroneFormat
    call printf
    add ecx, 1
    cmp ecx, dword [numofDrones]
    jl .printDrone
  mov ebx, schedulerCO
  call resume
  jmp printer_routine
