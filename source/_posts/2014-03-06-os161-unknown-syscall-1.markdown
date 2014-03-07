---
layout: post
title: "OS161: Unknown syscall -1"
date: 2014-03-06 16:50
comments: true
categories: ["os161"]
tags: ["syscall"]
---

When working on OS161 system calls, you'll probably see a bunch of this error,
especially you haven't implemented `_exit` syscall and try to do some basic user
programs, e.g., `p /bin/true`.

Note, this problem has been fixed in OS/161 version 1.99.07.

<!--more-->

The code for `/bin/true` is as follows.

```c
int
main()
{
	/* Just exit with success. */
	exit(0);
}
```
It does nothing but just exit with 0. Because at this point, you may don't
have `exit` syscall implemented, so it'll fail, so you'll see one error message
saying "Unknown syscall 3", in which 3 is just `SYS__exit`. Then what happens?
Why are there a bunch of "Unknown syscall -1" following that?

To understand this, you need to know about a bit of GCC optimization and also several
[MIPS instructions][mips], especially `jal` and `jr`.


### MIPS Function Call and Return

Here is the MIPS assembly instruction that "calls" a function `foo`.

```
jal foo
```

`jal` stands for "Jump And Link`, it will first save `$epc+8` into register
`$ra` (return address), and set `$epc` to whatever address `foo` are, to "jump"
to that function.

Now you may wonder why `$ra` is `$epc+8`, since a natural next instruction
would be `$epc+4`. That's because `$epc+4` is in `jal`'s [delay slot][delay],
which means the instruction will get executed __before__ the `jal` instruction.
So the real __next__ instruction after the function call should be `$epc+8`.

And when `foo` is done and about to return, it just does this:

```
jr ra
```

`jr` stands for "Jump Register". It just set `$epc` to whatever value in that
register. In this case, since `$ra` contains the value of return address, the
`foo` functions "returns".

### GCC Optimization

As per the comments in `$OS161_SRC/user/lib/libc/stdlib/exit.c`, GCC is way too
smart to know, without being explicitly told, that `exit` doesn't return. So it
actually omit the `jr` instruction at the end of `exit`. That is, if `exit`
_does_ return, the CPU will continue to execute whatever the following
instructions.


### What really happened?

Here is the assembly code of `/bin/true`. You can obtain it by doing this in the
`root` directory:

```bash
$ os161-objdump -d bin/true > true.S
```

```
00400100 <main>:
  400100:	27bdffe8 	addiu	sp,sp,-24
  400104:	afbf0010 	sw	ra,16(sp)
  400108:	0c10004d 	jal	400134 <exit>
  40010c:	00002021 	move	a0,zero

00400110 <__exit_hack>:
  400110:	27bdfff8 	addiu	sp,sp,-8
  400114:	24020001 	li	v0,1
  400118:	afa20000 	sw	v0,0(sp)
  40011c:	8fa20000 	lw	v0,0(sp)
  400120:	00000000 	nop
  400124:	1440fffd 	bnez	v0,40011c <__exit_hack+0xc>
  400128:	00000000 	nop
  40012c:	03e00008 	jr	ra
  400130:	27bd0008 	addiu	sp,sp,8

00400134 <exit>:
  400134:	27bdffe8 	addiu	sp,sp,-24
  400138:	afbf0010 	sw	ra,16(sp)
  40013c:	0c100063 	jal	40018c <_exit>
  400140:	00000000 	nop
	...

00400150 <__syscall>:
  400150:	0000000c 	syscall
  400154:	10e00005 	beqz	a3,40016c <__syscall+0x1c>
  400158:	00000000 	nop
  40015c:	3c010044 	lui	at,0x44
  400160:	ac220430 	sw	v0,1072(at)
  400164:	2403ffff 	li	v1,-1
  400168:	2402ffff 	li	v0,-1
  40016c:	03e00008 	jr	ra
  400170:	00000000 	nop
```

So `main` calls `exit` (0x400108), `exit` calls `_exit` (0x40013c). __Note that
at this point, `$ra=$epc+8=0x400144`. `_exit` fails, `$v0` is set to -1, and
returns to `$ra`. The memory between 0x400140 and 0x400150 are filled by 0,
which is `nop` instruction in MIPS. So the CPU get all the way down to the
`__syscall` function at 0x400150, and execute the `syscall` instruction. At this
point, the value of `$v0` is -1. That's why we see the first `Unknown syscall
-1` error message.

And after the syscall fails, the CPU will continue execution at 0x400154, and
finally do `jr ra` (0x40016c). Since `$ra` is still 0x400144, the whole process
repeats again. That's why you keep seeing `Unknown syscall -1` error.

### How to fix?

The problem is, GCC assumes `exit` does not return, thus doesn't generate the
`jr ra` instruction for `exit`. But before we implement `_exit` syscall, `exit`
_does_ return. Then we lose control and things get messy.


Then how to fix this? Well, the easiest way to fix this is...implement `_exit`,
of course. After all, that's what you suppose to do in ASST2 anyway.


In terms of the problem itself, the latest version of OS/161 (1.99.07) has fixed
this. Here is how:

```c
void
exit(int code)
{
	/*
	 * In a more complicated libc, this would call functions registered
	 * with atexit() before calling the syscall to actually exit.
	 */

#ifdef __mips__
	/*
	 * Because gcc knows that _exit doesn't return, if we call it
	 * directly it will drop any code that follows it. This means
	 * that if _exit *does* return, as happens before it's
	 * implemented, undefined and usually weird behavior ensues.
	 *
	 * As a hack (this is quite gross) do the call by hand in an
	 * asm block. Then gcc doesn't know what it is, and won't
	 * optimize the following code out, and we can make sure
	 * that exit() at least really does not return.
	 *
	 * This asm block violates gcc's asm rules by destroying a
	 * register it doesn't declare ($4, which is a0) but this
	 * hopefully doesn't matter as the only local it can lose
	 * track of is "code" and we don't use it afterwards.
	 */
	__asm volatile("jal _exit;"	/* call _exit */
		       "move $4, %0"	/* put code in a0 (delay slot) */
		       :		/* no outputs */
		       : "r" (code));	/* code is an input */
	/*
	 * Ok, exiting doesn't work; see if we can get our process
	 * killed by making an illegal memory access. Use a magic
	 * number address so the symptoms are recognizable and
	 * unlikely to occur by accident otherwise.
	 */
	__asm volatile("li $2, 0xeeeee00f;"	/* load magic addr into v0 */
		       "lw $2, 0($2)"		/* fetch from it */
		       :: );			/* no args */
#else
	_exit(code);
#endif
	/*
	 * We can't return; so if we can't exit, the only other choice
	 * is to loop.
	 */
	while (1) { }
}
```

So if `_exit` returns for any reason, we just access an address we know is
invalid, thus trigger an exception, and the kernel just panics.

[mips]: http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html
[delay]: http://en.wikipedia.org/wiki/Delay_slot
