
;global!!!! array of co-routines so we can execute them in round-robin
section .data
dronesRandRetHelper: dd 0
dronesRandAngleF: dt 0
dronesRandDistance: dt 0
dronesRandHelper: dt 0
randStartState: dd 0xACE1u   ;random start state
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

mayDestroy:
