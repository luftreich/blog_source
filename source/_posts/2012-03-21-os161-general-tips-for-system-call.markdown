---
comments: true
date: 2012-03-21 14:45:32
layout: post
title: "OS161: General Tips for System Call"
categories: [os161]
tags: [bmake, ctags, gdb, syscall]
---

Here are some practice that will hopefully make you feel more comfortable and
more productive when you poking around with os161 syscalls.

<!-- more -->

### Tired of bmake & bmake install every time?

Edit `$OS161_SRC/mk/os161.kernel.mk`, find this line:

```
all: includelinks .WAIT $(KERNEL) 
```

Add some lines below it:

```
all: includelinks .WAIT $(KERNEL) 
    #generate tags for ctags, excluding some directories
    cd $(TOP);ctags -R --exclude='.git' --exclude='build' --exclude='kern/compile' .; cd- 
    #automatically execute bmake install after bmake
    bmake install 
```

Then a single `bmake` will automatically generate tags for your source file as
well as install the executable.


### Work on file system calls first

Work on file system calls and make them work correctly first, since user level
I/O functions (most importantly `printf`) rely heavily on `sys_write` and
`sys_read` of console. If you first work on the process system calls, how would
you assure your code is right? Without a working and correct `printf`, most of
the test programs won't work.


### Test your code

Test programs in `$OS161_SRC/user/testbin` are very helpful when you want
to test your code, especially `badcall(asst2)`, `filetest`, `crash` (for
`kill_curthread`), `argtest` (for `execv`) and `forktest`.

You can use the `p` command provided by os161 kernel menu to execute this test
programs:

```make
OS/161 kernel [? for menu]: p /testbin/argtest abc def ghi jkl mno p 
```

### Use GDB

Without GDB, you're dead. It's really worth spending some time to learn the
basic usage of gdb. An upset fact is that you can not watch user level code (or
you don't want to bother), so use the "`printf` debug method" in user code.

Here are a few excellent gdb tutorials that you'll probably find helpful.

 - [GDB Tutorial from CMU][gdb_cmu]
 - [Tips from Harvard][gdb_harvard]

[gdb_cmu]: http://www.cs.cmu.edu/~gilpin/tutorial/ 
[gdb_harvard]: http://www.eecs.harvard.edu/~mdw/course/cs161/handouts/gdb.html
