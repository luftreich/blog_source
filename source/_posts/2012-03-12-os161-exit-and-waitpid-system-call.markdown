---
comments: true
date: 2012-03-12 15:51:46
layout: post
title: OS161 exit and waitpid System Call
categories: [os161]
tags: [exit, waitpid, syscall]
---

Before going on, assume you've read my previous post on [pid management][pid_post]

Thanks to the `struct process`, our work is much simplified. Quoting [Eric S.Raymond ][eric_quote] 
here.


> Smart data structures and dumb code works a lot better than the other way
around.

[pid_post]: /2012/03/12/os161-pid-management
[eric_quote]: http://en.wikipedia.org/wiki/Eric_S._Raymond


<!-- more -->

### `sys_waitpid`


At first glance, the logic of `waitpid` is trivial. Yes, it's indeed in
terms of the "core code": Just acquire the exitlock and then see if the
process has exited, then wait it exit using `cv_wait` on exitcv and get
it's exitcode. Here I use `cv` to coordinate child and parent process. Or you can
use semaphore with initial count 0: child will `V` the semaphore when it exits,
and parent will `P` the semaphore on `waitpid`.

But it turns out that most the code of `waitpid` is argument
checking! More arguments means more potential risks from user space.
Sigh~ Anyway, we are doing kernel programming. And just take a look at
`$OS161_SRC/user/testbin/badcall/bad_waitpid.c` and you'll know what I mean.

So basically, we need to check:

- Is the status pointer properly aligned (by 4) ?
- Is the status pointer a valid pointer anyway (NULL, point to kernel, ...)?
- Is options valid? (More flags than `WNOHANG | WUNTRACED` )
- Does the waited pid exist/valid?
- If exist, are we allowed to wait it ? (Is it our child?)

And also, after successfully get the exitcode, don't forget to destroy the
child's process structure and free its slot in the procs array. Since one child
has only one parent, and after we wait for it, no one will care for it any
more!


### `sys_exit`

This part is easy. (Mostly because exit only take on integer argument!) All
we need to do is find our `struct process` entry using `curthread->t_pid`.
And then indicate that "I've exited" and fill the exitcode. The only
thing to note that the exitcode must be maked using the MACROs in
`$OS161_SRC/kern/include/kern/wait.h`. Suppose user passing in `_exitcode`, then we need
to set the real `exitcode` as `_MKWAIT_exit(_exitcode)`.

And if we are smarter, we can first check if parent exist or if parent has
exited, then we even don't bother fill the exitcode since no one cares! Anyway,
it's just a tiny shortcut.
