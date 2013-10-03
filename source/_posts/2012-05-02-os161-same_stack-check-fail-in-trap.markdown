---
comments: true
date: 2012-05-02 18:02:11
layout: post
slug: os161-same_stack-check-fail-in-trap
title: OS161 SAME_STACK Check Fail in Trap
categories: [os161]
tags: [stack]
---

There are several `SAME_STACK` asserts in `$OS161_SRC/kern/arch/mips/locore/trap.c` to
ensure that **current thread did not run out of kernel stack**. 

<!-- more -->

A typical assert may looks like:

``` c
KASSERT(SAME_STACK(cpustacks[curcpu->c_number]-1, (vaddr_t)tf)) 
```

### The purpose of `SAME_STACK` assertion

In OS161, each thread has its own kernel stack. When interrupts or exceptions
occur, the CPU will first switch to current thread's kernel stack, both to avoid
polluting user's normal stack, and protect the stack from malicious user
program.

The stack is allocated in `thread_fork` and in `cpu_create` (but not both). The
initial stack size is defined in `$OS161_SRC/kern/include/thread.h` as
`STACK_SIZE`.

Since stack grows downwards, to check if we run out of the stack, we put a few
magic values at the bottom of the stack (`thread_checkstack_init`), so that we
can check if the values are the same with what we filled it
(`thread_checkstack`) to see if we run out of kernel stack.

In `$OS161_SRC/kern/arch/mips/locore/trap.c`, there are a few `SAME_STACK`
assertions to make sure the trap frame at the right place.

### Why would we run out of kernel stack?

Remember that any variables you define in your syscall functions are allocated
in current thread's kernel stack. So if you allocated large variables, such as a
big array buffer, you'll probably have a stack "downflow".

So, either try to shrink your declared buffer size, or use `kmalloc` instead.

Or, you can enlarge the stack size to temporally solve your pain, but this is
not recommended since each thread will have a stack, if it's too large, then
you'll soon run out of physical memory if you have lots of threads.


### Problem of the macro

During the lab, I sometimes fail this assert. At first, I thought I've run
out of kernel stack so I enlarge the `STACK_SIZE` 
to 16 KB. But I still fail this assert after that. Then I take a look at the
definition of the `SAME_STACK` macro:

``` c
#define SAME_STACK(p1, p2) (((p1) & STACK_MASK) == ((p2) & STACK_MASK)) 
```

I found this macro problematic. Suppose `STACK_SIZE = 0X00004000`, then
`STACK_MASK = ~(STACK_SIZE-1) = 0XFFFFC000`. Assume `p1 (stack top) =
0X80070FFF`, `p2 (stack pointer) = 0x8006FFFF`, then we've only used 0x00001000
bytes stack but `SAME_STACK` macro will fail, since `p1 & STACK_MASK =
0X80070000, p2 & STACK_MASK = 0X8006C000.`

**The point here is the stack top address may not be STACK_SIZE aligned. So we
can not do the same stack check by simply checking their base addresss.**

So we need to modify this part to get our kernel work. This is not your fault
but probably a bug shipped with the kernel.

You can use any tricky macros here but a simple pair of comparison will be
suffice.

``` c
KASSERT(((vaddr_t)tf) >= ((vaddr_t)curthread->t_stack)); 
KASSERT(((vaddr_t)tf) < ((vaddr_t)curthread->t_stack+STACK_SIZE));
```
