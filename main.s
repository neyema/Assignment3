
;global!!!! array of co-routines so we can execute them in round-robin

__start:
  ;initialize threads and their states
  ;initialize scheduler, can be static
  ;his size is: his private stack and 2 fields: pointer to function, spi.
  ;call the scheduler, no need to context-switch

resume:  ;saves the current state

do_resume:  ;

;for debug: print the details in each iteration of the loop
target_routine: ;the code for targer co-routine

drone_routine: ;the code for drone co-routine
