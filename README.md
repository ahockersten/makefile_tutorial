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

There is a git repository belonging to this project where you can download the results and test them out, as well as explore in detail how the makefile evolves. You may find it here: FIXME INSERT LINK

Let's start by writing a makefile that is as simple as possible. This makefile just produces a binary from a single input C file:

	a.out: main.c
		gcc main.c

Makefiles consist of declarations of rules for building target files. This makefile contains just one target, the `a.out` binary. On the left side of the `:` we list the target output(s) (these are by default treated as files by make, though they can be other things). On the right side we list the dependencies for that output. After this follows a list of commands that should be run to produce the output. This line is indented with a TAB character. This is **required** syntax by make. If we were to use spaces instead, we would get an error message complaining about a "missing separator".

Here we can also see the first and important magic piece of the make puzzle. When you run `make`, make will compare the modification date on the output file(s) to the modification date of the input file(s), and if and only if the input file(s) are newer than the output file(s), it will run the commands associated with the target.
