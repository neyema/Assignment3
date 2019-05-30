global targetX
global targetY
global target_routine

section .data
  targetX: dd 0
  targetY: dd 0
  targetRandHelper: dd 0

section .text
  align 16
  extern generate_rand
  extern schedulerCO
  extern resume

target_routine:  ;creating new target
  call generate_rand
  pop dword [targetRandHelper]
  popad
  popfd
  finit
  fild dword [targetRandHelper]
  push 2147483647   ;max int
  fidiv dword [esp]
  pop eax
  push 100
  fimul dword [esp]   ;to get [0, 100]
  fstp qword [targetX]
  pushfd
  pushad
  call generate_rand
  pop dword [targetRandHelper]
  popfd
  popad
  fild dword [targetRandHelper]
  push 2147483647   ;max int
  fidiv dword [esp]
  pop eax
  push 100
  fimul dword [esp]  ;to get [0, 100]
  fstp qword [targetY]
  mov ebx, [schedulerCO]
  call resume
