global targetX
global targetY
global target_routine

section .data
  targetX: dq 44.654     ;TODO: MAKE ZERO!
  targetY: dq 87.9136    ;TODO: MAKE ZERO!
  targetRandHelper: dd 0

section .text
  align 16
  extern generate_rand
  extern schedulerCO
  extern resume
  extern randWord

target_routine:  ;creating new target
  pushfd
  pushad
  call generate_rand
  ;mov dword [targetRandHelper], eax
  popad
  popfd
  finit
  fild dword [randWord]
  push 2147483647   ;max int
  fidiv dword [esp]
  pop eax
  push 100
  fimul dword [esp]   ;to get [0, 100]
  fstp qword [targetX]
  pushfd
  pushad
  call generate_rand
  ;mov dword [targetRandHelper], eax
  popfd
  popad
  fild dword [randWord]
  push 2147483647   ;max int
  fidiv dword [esp]
  pop eax
  push 100
  fimul dword [esp]  ;to get [0, 100]
  fstp qword [targetY]
  mov ebx, [schedulerCO]
  call resume
