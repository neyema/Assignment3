all: ass3

ass3: ass3.o scheduler.o drone.o printer.o target.o
		gcc -g -m32 -Wall -o ass3 ass3.o scheduler.o drone.o printer.o target.o

ass3.o: ass3.s
	nasm -g -f elf -w+all -o ass3.o ass3.s

scheduler.o: scheduler.s
	nasm -g -f elf -w+all -o scheduler.o scheduler.s

drone.o: drone.s
	nasm -g -f elf -w+all -o drone.o drone.s

printer.o: printer.s
	nasm -g -f elf -w+all -o printer.o printer.s

target.o: target.s
	nasm -g -f elf -w+all -o target.o target.s

.PHONY: clean

clean:
	rm -f *.o ass3
