all: assignment3

assignment3: main.o scheduler.o
		gcc -m32 -g -Wall -o hello hello.o start.o

main.o: main.s
	nasm -g -f elf -w+all -o main.o main.s

scheduler.o: scheduler.s
	nasm -g -f elf -w+all -o scheduler.o scheduler.s

.PHONY: clean
