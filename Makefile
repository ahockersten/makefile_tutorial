C_FILES = $(wildcard *.c)
O_FILES = $(C_FILES:.c=.o)

.PHONY: all clean
.DEFAULT: all

all: program

program: $(O_FILES)
	gcc -o $@ $^

%.o: %.c
	gcc -c $^

clean:
	-rm -f $(O_FILES)
	-rm -f program
