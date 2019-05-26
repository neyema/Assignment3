;Generates rand number between 1 and max int
generate_rand:
  mov eax, [randStartState]   ;eax is lfsr
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
  cmp eax, [randStartState]
  jne .doLoop
  push esi ;push period to return it
  ret

drone_routine: ;the code for drone co-routine
  pushad
  pushfd
  call generate_rand
  pop dword [dronesRandRetHelper]
  popfd
  popad
  finit
  fild dword [dronesRandRetHelper]  ;the angle itself
  fidiv 2147483647   ;max int
  fmul 120          ;to get [0, 120]
  fsub 60           ;to get [-60,60]
  ;pop value into dronesRandAngleF
  pushad
  pushfd
  call generate_rand
  pop dword [dronesRandRetHelper]
  popfd
  popad
  finit
  fild dword [dronesRandRetHelper]  ;the angle itself
  fidiv 2147483647   ;max int
  fmul 50          ;to get [0, 120]
  ;pop value into dronesRandDistance
  ;TODO: calculae new drone position

  
  ;move ebx, [CORS+8]
  ;call resume
