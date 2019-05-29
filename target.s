  extern generate_rand
  extern targetX
  extern targetY
  extern schedulerCO
  extern resume
section .data
  targetRandHelper: dd 0

section .text
  align 16
  global target_routine

createTarget:
  pushfd
  pushad
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
  fimul dword [esp]          ;to get [0, 100]
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
  fimul dword [esp]          ;to get [0, 100]
  fstp qword [targetY]
  ret

target_routine:
  call createTarget
  mov ebx, [schedulerCO]
  call resume
