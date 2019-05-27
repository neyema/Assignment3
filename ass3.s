STKSZ EQU 16*1024
;stack looks like (from lowest): x, y, angle, numOfDestTargets, id, ...
COSZ EQU STKSZ+8

section .rodata
  winnerFormat: db "Drone id %d: I am a winner", 10, 0
  printTargetFormat: db "%.2f,%.2f", 10, 0    ;x,y
  printDroneFormat: db "%d,%.2f,%.2f,%.2f,%d"  ;id,x,y,alpha,destoyedTargets
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
  dronesAlpha: dt 0
  dronesX: dd 0
  dronesY: dd 0
  dronesDestroyedTargets: dd 0
  dronesId: dd 0
  targetRandHelper: dd 0
  targetX: dd 0
  targetY: dd 0
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
  ;TODO: FIRST, INIT TARGET
  mov eax, [COSZ*ecx + CORS] ; get pointer to COi (i=ecx) struct
  mov dword [eax], drone_routine  ;pointer to function
  mov dword [eax+4], eax+8+STKSZ  ;stack pointer initialized to end of stack
  mov [SPT], esp
  mov esp, [eax+4]
  push 0 ;x TODO: change to random
  push 0 ;y
  push 0 ;angle TODO: change to random [0,360]
  push 0 ;number of destoryed targets
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

;Generates rand number between 1 and max int
generate_rand:
  mov eax, [seed]   ;eax is lfsr
  mov ebx, 0    ;bit will be in bx
  mov esi, 0    ;period will be in esi
  .doLoop:
    ;calculate bit
    mov ebx, eax
    shr ebx, 0
    mov edx, eax
    shr edx, 2
    xor ebx, edx
    mov edx, eax
    shr edx, 3
    xor ebx, edx
    mov edx, eax
    shr edx, 5
    xor ebx, edx
    ;calculate lfsr
    mov ecx, eax
    shr ecx, 1
    mov edx, ebx
    shl ebx, 15
    or ecx, edx
    mov ecx, eax
    add esi, 1
    cmp eax, [seed]
    jne .doLoop
  push esi ;push period to return it
  ret

;free all and exit
quit:
