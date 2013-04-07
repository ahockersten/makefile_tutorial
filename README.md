A crash course in GNU Make for the professional software developer
========================

Why would anyone want to learn make? It is fairly old by now, and there are tons of build systems out there that do the same thing but in much better ways. Make has a few very important things that makes it stand out though:

* universal - everyone (who is on a Mac or Linux, anyway) has make installed already
* well-known - many people know how to read and write makefiles, and there is a ton of help out there if you get stuck
* stable - while make is still being worked on and improved, the basic format has not changed in years. It is very unlikely that a new version of make will be released in the future and force you to make big changes to your build scripts

So why would you not want to use make?

* horrible syntax - it is not that bad once you get the hang of it, but there is no denying that make does not quite work the way most people expect it to
* hard to track what goes wrong - sure you can get make to output fairly verbose debugging information, but debugging makefiles can still be an exercise in extreme frustration
* very hard to do some things. Make is designed for building and dependency checking, and while it does that well, handling stuff like conditional compiles can quickly get complicated

So maybe you looked at the alternatives and after some consideration decided to bite the bullet and use make for your project, but you have no idea how and where to start. That is another of make's little quirks, it is quite uncommon for anyone to create a makefile from scratch. In this blog post I will however walk you all the way from a very simple example to a complex one, evolving a makefile that with a small amount of customization should be useful in any project.

There is a git repository belonging to this project where you can download the results and test them out, as well as explore in detail how the makefile evolves. You may find it [here](https://github.com/maskinskrift/makefile_tutorial).

Let's start by writing a makefile that is as simple as possible. This makefile just produces a binary from a single input C file:

	a.out: main.c
		gcc main.c

Makefiles consist of declarations of rules for building target files. This makefile contains just one target, the `a.out` binary. On the left side of the `:` we list the target output(s) (these are by default treated as files by make, though they can be other things). On the right side we list the dependencies for that output. After this follows a list of commands that should be run to produce the output. This line is indented with a TAB character. This is **required** syntax by make. If we were to use spaces instead, we would get an error message complaining about a "missing separator".

Here we can also see the first and important magic piece of the make puzzle. When you run `make`, make will compare the modification date on the output file(s) to the modification date of the input file(s), and if and only if the input file(s) are newer than the output file(s), it will run the commands associated with the target.

Now, let us make the example a bit more complicated:

	program: main.o
		gcc -o program main.o

	main.o: main.c
		gcc -c main.c

Here we split compilation of object files and the linking of the binary (which has been renamed to `program`). Since `main.o` is a dependency of `program`, make knows it should run the rule for the `main.o` target first to create that file, before it can try to build `program`.

Let us use some of make's features to make this a little more generic:

	program: main.o
		gcc -o $@ $^

	%.o: %.c
		gcc -c $^

There are three new concepts in the code above. The first one is to use a generic rule. `%.o: %.c` means: "to produce any '.o' file, you need a '.c' file with the same name, and the procedure to do this is outlined in the build instructions below". `$^` is a special variable that means "input(s) of this target" (which would be "main.o" in the topmost case). `$@` means "output(s) of this target" (which would be "program" in the topmost case).

Now if we add more files we can simply add them as dependencies for `program`:

	program: main.o extra.o
		gcc -o $@ $^

	%.o: %.c
		gcc -c $^

But let us assume we have a lot of object files, and keeping track of them manually in the makefile is both error prone and tedious. Then we can just use something like this:

	C_FILES = $(wildcard *.c)
	O_FILES = $(C_FILES:.c=.o)

	program: $(O_FILES)
		gcc -o $@ $^

	%.o: %.c
		gcc -c $^

We introduce two variables above. `C_FILES` is all of the C source input files, and `O_FILES` are the corresponding object files. `$(wildcard *.c)` just asks make to expand this variable so it contains the name of every C file in this directory (so using `$(C_FILES)` would be the same as writing `main.c extra.c` in our example).

`O_FILES` is produced by doing a pattern substitution on every white-space separated element in `C_FILES`, replacing any file with a ".c" file ending with one with a ".o" file ending. Why not just use `$(wildcard ...)` for `O_FILES` and skip creating the `C_FILES` variable? Because `$(wildcard ...)` will only produce listings of files that actually exist, and the first time we run our makefile no object files will exist. In other words, there will be no dependencies for `program`, which means that no object files will be build, and the `program` target will not be built correctly either.

The construction of `O_FILES` uses the shorthand syntax for make's `$(patsubst pattern,replacement,$(var))` function. Thus, the declaration of `O_FILES` is equivalent to writing `O_FILES = $(patsubst %.c,%.o,$(C_FILES))`. Generally I find the shorthand syntax to be clearer, but there may be times explicitly using the `$(patsubst ...)` function is preferable.

Let us take this example and make it more complete:

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

First, I added two phony targets, `all` and `clean`. These are used as shorthands for users, so you can run `make all`, and `make clean` instead of having to tell make which files should be produced. I then added two special targets, `.PHONY` and `.DEFAULT`. `.PHONY` tells make that "this target is not an actual file". Without this line, if you created a file named "all" or "clean", make would start behaving in unexpected ways. `.DEFAULT` tells make that if the user does not specify any other target, we should build the target(s) listed for `.DEFAULT`. In other words, running `make` now means the same thing as running `make all` (this line is not strictly necessary in this file. By default, make will build the first real target it sees listed, which in this case is `all`).

Finally, I added a `clean` target above. The idea of the `clean` target is to remove any files produced by all the other make targets. If you're reading carefully, you'll notice that I put a `-` in front of the `rm` command. This tells make to ignore any errors from running this command, and continue with the build process. Obviously, having no object files is not an error (it just means they haven't been previously built), so that should not stop us from deleting `program` if it exists.

Thus, we have arrived at the "bare minimum" makefile. There are however still some improvements I would like to do before I consider it be a good example.

First, I want source files in their own directory, and I do not want to pollute the directory our makefile is in with object files either:

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

So, ".c" files are now in the "src" directory, and object files end up in the "build" directory. If the build directory does not exist, it gets created. I added an `@` to the front of the mkdir command to silence it, as well; make will output any command not prefixed with an `@` as it runs it.

You will also notice the usage of a `|` before the dependency on "build" above. This means it is an "order-only dependency". This way make will ensure that the directory exists, but will not look at its timestamp to determine if anything needs to be rebuilt. Since the modification date of a directory changes whenever a file inside it is modified, we need this to make sure files aren't rebuilt unnecessarily.

I also changed the usage of `$^` to `$<`. `$<` expands to the first dependency in the list. We don't want to pass `build` to gcc when building.

I consider this example complete. Modifying it to build other types of files should be easy if you've followed how it was constructed above. One thing that is pretty popular though, is having your build script produce prettier output. So let us expand our example to do that as well, and take the opportunity to learn some more concepts in make:

	CC_VERBOSE = $(CC)
	CC_NO_VERBOSE = @echo "Building $@..."; $(CC)

	ifeq ($(VERBOSE),YES)
	  V_CC = $(CC_VERBOSE)
	  AT := 
	else
	  V_CC = $(CC_NO_VERBOSE)
	  AT := @
	endif

	C_FILES = $(wildcard src/*.c)
	O_FILES = $(C_FILES:src/%.c=build/%.o)

	.PHONY: all clean
	.DEFAULT: all

	all: program

	program: $(O_FILES)
		$(V_CC) -o $@ $^

	build:
		$(AT)mkdir -p build

	build/%.o: src/%.c | build
		$(V_CC) -c $< -o $@

	clean:
		@echo Removing object files
		$(AT)-rm -f $(O_FILES)
		@echo Removing application
		$(AT)-rm -f program
		@echo Removing build directory
		$(AT)-rm -rf build

What this does, is that if `VERBOSE` is set to `YES` when you call make, then it will output all information on what commands are run. If not, that information will be suppressed. To be able to do this, I have to introduce some new variables. First, I replace all relevant usages of `@` with the new variable `$(AT)`. `$(AT)` is only set to the real `@` if we are in non-verbose mode. To do this I use the operator `:=`. The difference between `:=` and `=` in make is a bit complicated and a cause of many bugs. `:=` forces all variables on the right-hand side to be expanded immediately, while using `=` makes sure they are expanded at the last possible moment. Perhaps this is easiest to illustrate with a two small examples:

	FOO := $(BAR)
	BAR = bar

	output: input
		$(FOO) hello world

Running `make output` here would be equal to running the command `hello world`, since `$(BAR)` is not defined when `$(FOO)` is set. `$(FOO)` will thus be an empty string.

	FOO = $(BAR)
	BAR = bar

	output: input
		$(FOO) hello world

Running `make output` here would be equal to running the command `bar hello world`. `$(BAR)` is still not defined when `$(FOO)` is set. However, since it is available when `$(FOO)` is expanded in the `output` rule, it will expand to `$(BAR)`, which will in turn expand to "bar".

Note that in the example makefile, it would be possible to use `=` instead of `:=`. I only use `:=` here to demonstrate the usage of `:=`.

This wraps up this short but hopefully fairly complete tour of the most important features of make. There is still lots of stuff left to learn. In the next blog post, I will borrow a makefile from a real application and see how it can be improved.
