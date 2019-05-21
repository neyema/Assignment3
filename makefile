all: ass3

ass: ass3.o scheduler.o drone.o
		gcc -m32 -g -Wall -o ass3 ass3.o scheduler.o drone.o

ass3.o: ass3.s
	nasm -g -f elf -w+all -o ass3.o ass3.s

scheduler.o: scheduler.s
	nasm -g -f elf -w+all -o scheduler.o scheduler.s

drone.o: drone.s
	nasm -g -f elf -w+all -o drone.o drone.s

printer.o: printer.s
	nasm -g -f elf -w+all -o printer.o printer.s

printer.o: printer.s
	nasm -g -f elf -w+all -o printer.o printer.s

.PHONY: clean
