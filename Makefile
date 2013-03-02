C_FILES = $(wildcard *.c)
O_FILES = $(C_FILES:.c=.o)

program: $(O_FILES)
	gcc -o $@ $^

%.o: %.c
	gcc -c $^
