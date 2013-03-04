C_FILES = $(wildcard src/*.c)
O_FILES = $(C_FILES:src/%.c=build/%.o)

.PHONY: all clean
.DEFAULT: all

all: program

program: $(O_FILES)
	gcc -o $@ $^

build:
	@mkdir -p build

build/%.o: src/%.c | build
	gcc -c $< -o $@

clean:
	-rm -f $(O_FILES)
	-rm -f program
	-rm -rf build
