---
comments: true
date: 2012-03-11 20:42:34
layout: post
title: OS161 fork System Call
categories: [os161]
tags: [fork, syscall]
---

If you're not already familiar with UNIX fork system call, here is it's
[function description][unix_fork] and its [entry on Wikipedia][fork_wiki].

Basically, in `sys_fork`, we need to do the follow things:

1. Copy parent's trap frame, and pass it to child thread
2. Copy parent's address space
3. Create child thread (using `thread_fork`)
4. Copy parent's file table into child
5. Parent returns with child's pid immediately
6. Child returns with 0

So, let's get started.

[unix_fork]: http://linux.die.net/man/2/fork
[fork_wiki]: http://en.wikipedia.org/wiki/Fork_(operating_system)

<!-- more -->

### Pass parent's trap frame to child thread

Trap frame (`struct trapframe`) records the exact state (e.g. registers, stack, 
etc.) of parent when
it call fork. Since we need the child exactly the same with parent (excluding
return value of fork), we need child thread to start run with parent's trap
frame.

So we need to pass parent's `trapframe` pointer to `sys_fork`, and store a full
copy of it **in the kernel heap** (i.e., allocated by `kmalloc`). Then pass the
pointer to child's fork entry function (I name it as `child_forkentry`).


### Copy parent's address space

We can use the `as_copy` facility to do this. Note that `as_copy` will allocate
a `struct addrspace` for you and also copy the address space contents, so you
don't need to call `as_copy` by yourself. 

### Creating Child Thread

`thread_fork` will create a new child thread structure and copy various fields
of current thread to it. Again, you don't need to call `thread_create` by
yourself, `thread_fork` will call it for you. You can get the pointer of child's
thread structure by the last argument of `thread_fork`.


### Parent's and Child's fort return different values

This is the trickiest part. You may want to take a look at the end of `syscall`
to find out the convention of return values. That is: **on success, `$a3` stores
0, and `$v0` stores return value (or `$v0:$v1` if retval is 64-bit); on failure, `$a3`
stores 1, and `$v0` store error code**.

Parent part is quite easy, after call `thread_fork`, just copy current thread's
file table to child, and other book-keeping stuff you need to do, and finally,
return with child's pid, and let `syscall` deal with the rest.

Child part is not that trivial. In order to let child feel that `fork` returns
0, we need to play with the trapframe a little bit. Remember that when we call
`thread_fork` in parent's `sys_fork`, we need to pass it with an entry point
together with two arguments (`void* data1, unsigned long data2`). As said before,
I name the entry point as `child_forkentry`, then what should we pass to it?
Obviously, one is parent's trapframe copy (lies in kernel heap buffer) and
another is parent's address space!

Once we've decided what to pass, how to pass is depend on your preference. One
way is to pass trapframe pointer as the `data1`, and address space pointer as
`data2` (with explicit type-case of course). Another way may be we pass trapframe pointer
as `data1`, and assign the address space pointer to `$a0` since we know `fork` takes
no arguments.


### `child_forkentry`

Ok, now `child_forkentry` becomes the first function executed when child
thread got run. First, we need to modify parent's trapframe's `$v0` and `$a3`
to make child's fork looks success and return 0. Also, **don't forget to
forward $epc by 4** to avoid child keep calling fork. (BTW, we don't need
to do this in parent since `syscall` will take care of this.). 

Then we
need to load the address space into child's `curthread->t_addrspace` and
activate it using `as_activate`. Finally, we need to call `mips_usermode`
to return to user mode. But before that, we need to** copy the modified
trapframe from kernel heap to stack** since `mips_usermode` check this
(`KASSERT(SAME_STACK(cpustacks[curcpu->c_number]-1, (vaddr_t)tf))`. How? Before
call `mips_usermode`, just declare a `struct trapframe` and copy the content
into it, then use its address as parameter to call `mips_usermode`

### Synchronization

Note that `thread_fork` will set newly created child thread runnable and try to
switch to it immediately. So it's highly possible that before `thread_fork`
returns, the child thread is already running. This is not desired since we
need to copy other stuff, like file table, to child thread after
`thread_fork`. We definitely don't want the child thread running without a
file table. So **we need to prevent child thread from running until parent
thread set everything up.**

So we need to disable interrupts before `thread_fork` using `splhigh`, and
restore the old interrupt level using `splx` after parent thread is done.
