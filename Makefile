program: main.o extra.o
	gcc -o $@ $^

%.o: %.c
	gcc -c $^
