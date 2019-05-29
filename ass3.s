global CORS
global SPT
global SPMAIN

section .text
  align 16
  extern drone_routine
  extern target_routine
  extern scheduler_routine
  ;C library functions
  extern malloc
  extern sscanf
  global generate_rand
section .rodata
  winnerFormat: db "Drone id %d: I am a winner", 10, 0
  printTargetFormat: db "%.2f,%.2f", 10, 0    ;x,y
  printDroneFormat: db "%d,%.2f,%.2f,%.2f,%d"  ;id,x,y,alpha,destoyedTargets

section .bss
  STKSZ EQU 16*1024
  ;stack looks like (from highest): x, y, angle, numOfDestTargets ...
  COSZ EQU STKSZ+8  ;private stack and 2 fields: pointer to function, spi
  CURR: resd 1
  SPT: resd 1  ;4 bytes, temporary stack pointer
  SPMAIN: resd 1  ;stack pointer of main, when back from scheduler
  schedulerCO: resb COSZ
  printerCO: resb COSZ
  targetCO: resb COSZ

section .data
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
  add esp, 4
  push esp
  call sscanf
  push K
  push "%d "
  add esp, 4
  push esp
  call sscanf
  ;QUESTION: BETA IN DEGS OR IN RADS?
  push beta
  push "%d "
  add esp, 4
  push esp
  call sscanf
  push d
  push "%d "
  add esp, 4
  push esp
  call sscanf
  push seed
  push "%d "
  add esp, 4
  push esp
  call sscanf

  ;allocating size for CORS
  mov eax, [numofDrones]
  mov ebx, COSZ
  mul ebx  ;eax<-COSZ*numofDrones
  push eax
  call malloc
  mov [CORS], eax  ;the pointer returned by malloc

  mov ecx, 1  ;drone id is 1 to N
initCORS:
  ;TODO: FIRST, INIT TARGET
  mov ebx, [CORS]
  sub ecx, 1
  mov eax, COSZ
  mul ecx  ;ecx<-COSZ*(ecx-1)
  add ebx, ecx  ;get pointer to COi (i=ecx-1) struct
  mov dword [ebx], drone_routine  ;pointer to function
  add eax, COSZ
  mov dword [eax+4], eax  ;stack pointer initialized to end of stack
  mov [SPT], esp
  mov dword esp, [ebx+4]
  ;push ecx  ;drone-id
  push 0 ;x TODO: change to random
  push 0 ;y
  push 0 ;angle TODO: change to random [0,360]
  push 0 ;number of destoryed targets
  cmp ecx, [numofDrones]
  add ecx, 1
  jle initCORS

initScheduler:
  mov dword [schedulerCO], scheduler_routine  ;pointer to function
  mov dword [schedulerCO+4], schedulerCO+COSZ ;stack pointer initialized to end of stack
  mov [SPT], esp
  mov dword esp, [schedulerCO+4]

  ;start scheduler
  pushad; save registers of main ()
  mov [SPMAIN], ESP; save ESP of main ()
  mov ebx, schedulerCO; gets a pointer to a scheduler struct
  jmp do_resume

endCo:
  mov ESP, [SPMAIN]  ; restore ESP of main()
  popad; restore registers of main()

;the inveriant that helps the resume-do_resume method is:
;in every private stack of co-routine the top contains (from top): fd, ad, return address in that routine
;return address can be to the line 'jmp drone_routine'
resume: ;save state of current co-routine
  push dword [ebx]  ;pointer to function
  pushfd
  pushad
  mov edx, [CURR]
  mov dword [edx+4], ESP  ;save current ESP

do_resume: ;load ESP for resumed co-routine
  mov esp, [ebx+4]
  mov [CURR], ebx
  popad ;restore resumed co-routine state
  popfd
  ret  ;"return" to resumed co-routine
  ;this will pop the address to the function and jmp there

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
