program: main.o
	gcc -o program main.o

main.o: main.c
	gcc -c main.c
