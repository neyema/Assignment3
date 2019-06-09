global CORS
GLOBAL COSZ
global SPT
global SPMAIN
global numofDrones
global numofTargets
global K
global beta
global d
global randWord
global resume
global schedulerCO
global printerCO

global main
global generate_rand
global endCo
global quit

%macro scanCmd 2  ;assumption: in ebx the value of argv (char**)
  mov ecx, [ebx+%2]  ;ecx<-argv[...] (char*)
  pushad
  pushfd
  push %1
  push intFormat
  push ecx
  call sscanf
  add esp, 12
  popfd
  popad
%endmacro

STKSZ EQU 16*1024
;stack looks like (from highest): x, y, angle, numOfDestTargets ...
COSZ EQU STKSZ+8  ;private stack and 2 fields: pointer to function, spi

section .rodata
  winnerFormat: db "Drone id %d: I am a winner", 10, 0
  intFormat: db "%d", 0

section .bss
  CURR: resd 1
  SPT: resd 1  ;4 bytes, temporary stack pointer
  SPMAIN: resd 1  ;stack pointer of main, when back from scheduler
  schedulerCO: resb COSZ
  printerCO: resb COSZ
  targetCO: resb COSZ

section .data
  numofDrones: dd 0  ;num of drones
  numofTargets: dd 0  ;num of targets needed to destroy to win
  K: dd 0 ;num of drone steps between broad printing
  beta: dd 0  ;the angle of drone field-of-view
  d: dd 0  ;maximum distance that allows to destroy a target
  randWord: dd 0
  CORS: dd 0  ;address to the array of co-routines
  randHelper: dq 0

section .text
  align 16
  extern drone_routine
  extern target_routine
  extern scheduler_routine
  extern printer_routine
  ;C library functions
  extern malloc
  extern sscanf
  extern free

main:
  push ebp
  mov ebp, esp
  mov ebx, [esp+12]  ;discard ebp, return address and argc, so we have argv (char**)
  ;now in ebx the pointer to argv[0], the file name
  ;remember! push the arguments in opposite order
  scanCmd numofDrones,4  ;argv[1]
  scanCmd numofTargets,8
  scanCmd K,12
  scanCmd beta,16
  scanCmd d,20
  scanCmd randWord,24

  ;allocating size for CORS
  mov eax, [numofDrones]
  mov ebx, COSZ
  mul ebx  ;eax<-COSZ*numofDrones    ;TODO: DAMM YOU ASSEMBLY CHECK malloc with 10 drones
  pushad
  pushfd
  push eax
  call malloc
  add esp, 4  ;discard push eax
  mov [CORS], eax  ;the pointer returned by malloc
  popfd
  popad

  ;init Target
  mov dword [targetCO], target_routine
  mov dword [targetCO+4], targetCO+COSZ
  mov [SPT], esp
  ;TODO: INIT TARGET WITH RAND X,Y
  mov esp, [targetCO+4]
  push target_routine
  pushfd
  pushad
  mov [targetCO+4], esp
  mov esp, [SPT]
  ;init Printer
  mov dword [printerCO], printer_routine
  mov dword [printerCO+4], printerCO+COSZ
  mov [SPT], esp
  mov esp, [printerCO+4]
  push printer_routine
  pushfd
  pushad
  mov [printerCO+4], esp
  mov esp, [SPT]

  mov ecx, 0  ;drone id is 1 to N
initCORS:
  mov eax, COSZ
  mul ecx  ;eax<-COSZ*(ecx)
  ;we want in eax the offset in bytes in CORS
  mov ebx, [CORS]
  add ebx, eax  ;get pointer to COi (i=ecx-1) struct
  mov dword [ebx], drone_routine  ;pointer to function
  ;add eax, COSZ  ;eax<-end of routine struct
  add eax, [CORS]  ;eax already contains COSZ*currID
  add eax, COSZ   ;eax is the address to the end of stack of COi (i=ecx-1) *in CORS*
  mov dword [ebx+4], eax  ;stack pointer initialized to end of stack
  mov [SPT], esp
  mov dword esp, [ebx+4]
  ;push ecx  ;drone-id
  pushfd
  pushad
  call generate_rand
  popad
  popfd
  finit
  fild dword [randWord]
  push 2147483647   ;max int
  fidiv dword [esp]
  pop eax
  push 100
  fimul dword [esp]   ;to get [0, 100]
  fstp qword [randHelper]
  push dword [randHelper]       ;x
  push dword [randHelper + 4]  ;second part of x
  pushfd
  pushad
  call generate_rand
  popad
  popfd
  fild dword [randWord]
  push 2147483647   ;max int
  fidiv dword [esp]
  pop eax
  push 100
  fimul dword [esp]   ;to get [0, 100]
  fstp qword [randHelper]
  push dword [randHelper]       ;y
  push dword [randHelper + 4]   ;second part of y
  pushfd
  pushad
  call generate_rand
  popad
  popfd
  fild dword [randWord]
  push 2147483647   ;max int
  fidiv dword [esp]
  pop eax
  push 360
  fimul dword [esp]                ;to get [0, 360]
  fstp qword [randHelper]
  push dword [randHelper]        ;angle [0,360]
  push dword [randHelper + 4]   ;second part of angle
  push 0      ;number of destoryed targets
  push ecx    ;droneId
  push drone_routine  ;for the first time calling to the drone (we'll do pop in do_resume)
  pushfd
  pushad
  ;update the private field of stack pointer
  mov dword [ebx+4], esp  ;ebx is the pointer to the co routine in the CORS array
  mov esp, [SPT]
  ;condition of initCORS loop
  add ecx, 1
  cmp ecx, [numofDrones]
  jl initCORS

initScheduler:
  mov dword [schedulerCO], scheduler_routine  ;pointer to function
  mov dword [schedulerCO+4], schedulerCO+COSZ ;stack pointer initialized to end of stack
  mov [SPT], esp
  mov esp, [schedulerCO+4]
  ;only in scheduler routine, init the private stack with ad,fd,address for "ret" for the first do_resume
  push scheduler_routine
  pushfd
  pushad
  mov [schedulerCO+4], esp
  mov dword esp, [SPT]

;start scheduler
  pushad  ;save registers of main
  pushfd
  mov [SPMAIN], esp  ;save ESP of main
  mov ebx, schedulerCO ;gets a pointer to a scheduler routine
  jmp do_resume

endCo:
  mov esp, [SPMAIN]  ;restore ESP of main()
  popfd
  popad ;restore registers of main()
  jmp quit

  ;the inveriant that helps the resume-do_resume method is:
  ;in every private stack of co-routine the top contains (from top): fd, ad, return address in that routine
  ;return address can be to the line 'jmp drone_routine'
resume: ;save state of current co-routine
  ;push dword [ebx]  ;pointer to function
  pushfd
  pushad
  mov edx, [CURR]
  mov dword [edx+4], ESP  ;save current ESP

do_resume: ;load ESP for resumed co-routine
  mov dword esp, [ebx+4]
  mov [CURR], ebx
  popad ;restore resumed co-routine state
  popfd
  ret  ;"return" to resumed co-routine
  ;this will pop the address to the function and jmp there

  ;Generates rand number between 1 and max int
generate_randOld:
  mov eax, [randWord]   ;eax is lfsr
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
    cmp eax, [randWord]
    jne .doLoop
  mov eax, esi ;move period to eax to return
  ret

random_bit:
  mov al, 101101b    ;the taps
  xor al, [randWord]     ;compute parity of bits (PF), clear CF
  jpe result_ok      ;jmp if even parity
  stc                ;set carry flag to be 1
result_ok:
  ;the randomly generated bit is in CF
  rcr word [randWord], 1   ;rotate with carry right new bit (from CF) into pseudo-random state
  ret
generate_rand:
  ;we need 16 random bits
  mov ecx, 16
next_bit:
  call random_bit
  loop next_bit, ecx
  ret

;free all and exit
quit:
  pushad
  pushfd
  mov dword eax,  [CORS]
  push eax  ;in CORS the address to the memory
  call free
  add esp, 4
  popfd
  popad
  ;these next 3 are not needed maybe
  ;push dword schedulerCO
  ;call free
  ;add esp, 4
  ;push targetCO
  ;call free
  ;add esp, 4
  ;push printerCO
  ;call free
  ;add esp, 4
