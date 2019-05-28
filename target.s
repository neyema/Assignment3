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
  fild [targetRandHelper]
  push 2147483647   ;max int
  fidiv [esp]
  pop eax
  push 100
  fimul [esp]          ;to get [0, 100]
  fstp [targetX]
  pushfd
  pushad
  call generate_rand
  pop dword [targetRandHelper]
  popfd
  popad
  fild [targetRandHelper]
  push 2147483647   ;max int
  fidiv [esp]
  pop eax
  push 100
  fimul [esp]          ;to get [0, 100]
  fstp [targetY]
  ret

target_routine:
  call createTarget
  mov ebx, [schedulerCO]
  call resume
