---
comments: true
date: 2012-03-11 22:27:47
layout: post
title: OS161 execv System Call
categories: [os161]
tags:  [execv, syscall]
---

Basically, `execv` do more or less the same thing with `runprogram` resided in
`$OS161_SRC/kern/syscall/runprogram.c`. The overall flow of `sys_execv` are:

  1. **Copy arguments into kernel buffer**

  2. Open the executable, create a new address space and load the elf into it

  3. **Copy the arguments into user stack**

  4. Return user mode using `enter_new_process`

<!-- more -->

Note that I highlighted step 1 and 3 since they are the trickiest part of
`execv`, step 2 and 4 are just the same with `runprogram`.

### Format of `uargs`

The first argument is `progname` (e.g., `/testbin/argtest`), and the second
argument is `uargs`, it's an array of pointers, each pointer points to a user
space string. The last pointer of `uargs` is `NULL`.

Since we don't know how many arguments are there in `uargs`, we need to copy
the pointers one by one using `copyin` until we encounter a `NULL`.


### Copy arguments into kernel buffer

In whichever way to do this, one of step 1 and 3 must be complicated. I choose
to carefully pack the arguments into a kernel buffer and then just directly
copy this buffer into user stack in bulk. Note that in MIPS, **pointers must be 
aligned by 4**. So don't forget to padding when necessary

For convenience, assume that arguments are {`foo`, `os161`, `execv`, `NULL`}.
Then after packing, my kernel buffer looks like this:

{% img center /images/2012-03-11-kargv.png  Arguments in `kargv` %} 

**Typo: **`kargv[2]` should be 28, not 26.

Note that `kargv[i]` stores the offset of the `i`'th arguments **within the kargv
array**, since up to now we don't know their real user address yet (although we
can actually calculate that out...).


### Copy the arguments into user stack

Why user stack, not anywhere else? Because it's the only space we know for
sure. We can use `as_define_stack` to get the value of initial stack pointer
(normally `0x8000000`, aka `USER_SPACE_TOP`). So what we do is 

1. Fill `kargv[i]` with actual user space pointer, and 
2. Copy `kargv` array into the stack 
3. Minus `stackptr` by the length of `kargv` array. 

Note that **we must modify `kargs[i]` before we do the actual copy**, 
otherwise some weird bus error or TLB miss will occur.

The steps are shown as follows (here we assume `stackptr` initial value is
`0x80000000`):

{% img center /images/2012-03-11-stackptr.png Change of `stackptr`%}
