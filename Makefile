program: main.o
	gcc -o $@ $^

%.o: %.c
	gcc -c $^
