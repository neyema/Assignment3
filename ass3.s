STKSZ EQU 16*1024
;stack looks like (from lowest): x, y, angle, numOfDestTargets, id, ...
COSZ EQU STKSZ+8

section .rodata
  winnerFormat: db "Drone id %d: I am a winner", 10, 0
  printTargetFormat: db "%.2f,%.2f", 10, 0    ;x,y
  printDroneFormat: db "%d,%.2f,%.2f,%.2f,%d"  ;id,x,y,alpha,destoyedTargets
section .bss
  curr: resd 1
  SPT: resd 1  ;4 bytes, temporary stack pointer
  SPMAIN: resd 1  ;stack pointer of main, when back from scheduler

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
  schedulerCO: rebs COSZ ;private stack and 2 fields: pointer to function, spi
  CORS: dd 0  ;address to the array of co-routines

section .text
  align 16
  global CORS
  global SPT
  global SPMAIN
  extern do_resume
  ;extern drone_routine
  ;extern target_routine
  ;extern scheduler_routine
  ;C library functions
  extern malloc
  extern sscanf

main:
  push ebp
  mov ebp, esp
  add esp, 8 ;discard argc and argv[0]
  ;;scanf
  mov eax, esp
  ;push the argument in opposite order
  push numofDrones
  push "%d "
  push esp
  call sscanf
  push numofTargets
  push "%d "
  push esp+4
  call sscanf
  push K
  push "%d "
  push esp+4
  call sscanf
  push beta
  push "%d "
  push esp+4
  call sscanf
  push d
  push "%d "
  push esp+4
  call sscanf
  push seed
  push "%d "
  push esp+4
  call sscanf

  ;malloc CORS
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
  mov dword esp, [eax+4]
  push 0 ;x TODO: change to random
  push 0 ;y
  push 0 ;angle TODO: change to random [0,360]
  push 0 ;number of destoryed targets
  push ecx  ;drone-id
  cmp ecx, [numofDrones]
  jl initCORS

initScheduler:
  mov dword [schedulerCO], scheduler_routine  ;pointer to function
  mov dword [schedulerCO+4], schedulerCO+COSZ ;stack pointer initialized to end of stack
  mov [SPT], esp
  mov dword esp, [schedulerCO+4]
  push ecx  ;drone-id

  ;start scheduler
  pushad; save registers of main ()
  mov [SPMAIN], ESP; save ESP of main ()
  mov ebx, [schedulerCO]; gets a pointer to a scheduler struct
  call startScheduler
  mov ESP, [SPMAIN]  ; restore ESP of main()popad; restore registers of main()

resume:; save state of current co-routine
  pushfd
  pushad
  mov edx, [CURR]
  mov dword [edx+4], ESP  ;save current ESP

do_resume: ; load ESP for resumed co-routine
  mov esp, [ebx+4]
  mov [CURR], ebx
  popad; restore resumed co-routine state
  popfd
  ret; "return" to resumed co-routine

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
