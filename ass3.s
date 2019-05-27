
section .rodata
winnerFormat: db "Drone id %d: I am a winner", 10, 0

;global!!!! array of co-routines so we can execute them in round-robin
section .data
mayDestroyGamma: dd 0
dronesMayDestroyHelper: dd 0
dronesRandRetHelper: dd 0
dronesRandAngleF: dt 0
dronesRandDistance: dt 0
dronesRandHelper: dt 0
numofDrones: dd 0  ;num of drones
numofTargets: dd 0  ;num of targets needed to destroy to win
K: dd 0  ;num of drone steps between broad printing
beta: dd 0  ;the angle of drone field-of-view
d: dd 0  ;maximum distance that allows to destroy a target
seed: dd 0
CORS: dd 0  ;address to the array of co-routines

section .text
align 16  ;why?????
global CORS
extern malloc

main:
  push ebp
  mov ebp, esp
  add ebp, ;discard argc and argv[0]
  mov eax, [ebp]
  mov dword [numofDrones], eax
  mov dword eax, [ebp+4]
  mov dword, [numofTargets], eax
  mov dword eax, [ebp+8]
  mov dword [K], eax
  mov dword eax, [ebp+12]
  mov dword [beta], eax
  mov dword eax, [ebp+16]
  mov dword [d], eax
  mov dword eax, [ebp+20]
  mov dword [seed], eax

initCORS:
  mov eax, [numofDrones]
  add dword eax, [numofDrones]  ;eax=numofDrones*2
  add dword eax, eax  ;eax=numofDrones*4
  call malloc

  ;initialize threads and their states

  ;initialize scheduler, can be static
  ;his size is: his private stack and 2 fields: pointer to function, spi.
  ;call the scheduler, no need to context-switch

initCo:
  mov ebx, [ebp+8] ; get co-routine ID number
  mov ebx, [4*ebx + CORS] ; get pointer to COi struct
  mov eax, [ebx+CODEP] ; get initial EIP value – pointer to COi function
  mov [SPT], ESP ; save ESP value
  mov esp, [EBX+SPP] ; get initial ESP value – pointer to COi stack
  push eax ; push initial “return” address
  pushfd ; push flags
  pushad ; push all other registers
  mov [ebx+SPP], esp ; save new SPi value (after all the pushes)
  mov ESP, [SPT]

resume:  ;saves the current state

do_resume:  ;

;free all and exit
quit:


;returns dword 0 or 1 in the stack
mayDestroy:
  ;TODO: GET RID OF THE ASSUMPTIONS!
  ;assumes pointer to X is in ebx
  ;assumes pointer to Y is in ecx
  ;assumes pointer to X of target in edx
  ;assumes pointer to Y of target in esi
  finit
  fild dword [ecx]
  fsub dword [esi]
  fild dword [ebx]
  fsub dword [edx]
  ;in st0: x2-x1, in st1: y2-y1
  fpatan
  fstp [mayDestroyGamma]
  ;assumes that pointer to alpha in eax
  fild dword [eax]
  fsub dword [mayDestroyGamma]
  fabs st0
  fild dword [beta]
  ucomiss st1, st0
  ja .otherCond
  jmp .retFalse
  .otherCond:
  fild dword [ecx]
  fsub dword [esi]
  fild dword[ecx]
  fsub dword [esi]
  fmulp
  fild dword [ebx]
  fsub dword [edx]
  fild dword [ebx]
  fsub dword [edx]
  fmulp
  ;in st0: (x2-x1)^2, in st1: (y2-y1)^2
  faddp
  fsqrt
  fild dword [d]
  ucomiss st1, st0
  ja .retTrue
  jmp .retFalse
  .retTrue:
  mov eax, 1
  push eax
  ret
  .retFalse:
  mov eax, 0
  push eax
  ret
