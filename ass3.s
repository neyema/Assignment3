STKSZ EQU 16*1024
;stack looks like (from lowest): angle, x, y, id, ...
COSZ EQU STKSZ+8

section .rodata
  winnerFormat: db "Drone id %d: I am a winner", 10, 0

section .bss
  curr: resd 1
  SPT: resd 1
  SPMAIN: resd 1

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
  align 16
  global CORS
  extern malloc
  ;extern drone_routine
  ;extern target_routine

main:
  push ebp
  mov ebp, esp
  add ebp, 8 ;discard argc and argv[0]
  ;;sscanf
  mov eax, [ebp]
  mov dword [numofDrones], eax
  mov dword eax, [ebp+4]
  mov dword [numofTargets], eax
  mov dword eax, [ebp+8]
  mov dword [K], eax
  mov dword eax, [ebp+12]
  mov dword [beta], eax
  mov dword eax, [ebp+16]
  mov dword [d], eax
  mov dword eax, [ebp+20]
  mov dword [seed], eax

  mov eax, [numofDrones]
  ;eax-<eax*(STKSZ+8)
  mov eax, eax*(STKSZ+8)
  push eax
  call malloc
  mov [CORS], eax

  mov ecx, 0
initCORS:
  mov eax, [COSZ*ecx + CORS] ; get pointer to COi (i=ecx) struct
  mov dword [eax], drone_routine  ;pointer to function
  mov dword [eax+4], eax+8+STKSZ  ;stack pointer initialized to end of stack
  mov [SPT], esp
  mov esp, [eax+4]
  push 0 ;angle TODO: change to random [0,360]
  push 0 ;x TODO: change to random
  push 0 ;y
  push ecx  ;drone-id
  cmp ecx, [numofDrones]
  jl initCORS
  ;initialize threads and their states

  ;initialize scheduler, can be static
  ;his size is: his private stack and 2 fields: pointer to function, spi.
  ;call the scheduler, no need to context-switch

initCo:  ;in ecx the id of the drone
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

startCo:
  pushad; save registers of main ()
  mov [SPMAIN], ESP; save ESP of main ()
  mov EBX, [EBP+8]; gets ID of a scheduler co-routine
  mov EBX, [EBX*4 + CORS]; gets a pointer to a scheduler struct
  jmp do_resume

;free all and exit
quit:
