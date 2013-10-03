---
comments: true
date: 2012-03-12 15:13:54
layout: post
title: OS161 pid Management
categories: [os161]
tags: [pid, syscall]
---

There are many way to manage each process's pid. Here is the way I do it.

I decided to make minimal modification to `$OS161_SRC/kern/thread/thread.c`,
in case anything is ruined. So I only add two things to the thread module. One
is I add a `t_pid` field to `struct thread` so that `getpid` system call is
trivial. Another is I add a call of `pid_alloc` in `thread_alloc` to initialize
new thread's `t_pid`. That's it. No more touch on the thread module.

<!-- more -->


### The process Structure

In os161, we stick to the 1:1 process:thread model. That is, a process has and
only has one thread. Thus process and thread are basically the same thing in
this scenario. However, I still decided to use a `struct process` to do process
bookkeeping stuff. It's independent to `struct thread` and outside the thread
module. Thus when a thread exits and its `thread` structure is destroyed. I
still have its meta-data (e.g. exitcode) stored in the `process` structure.

So, what should we record about a process? As we already have the `struct
thread` to record most of the information about a thread, we just use a pointer
to `struct thread` to get all these information. What we do in `struct process`
is mainly for our `waitpid` and `exit` system call. So we should keep the
information of:

- Its parent's (if any) pid

- Whether a process has exited

- If this process has exited, then the exitcode

- Synchronous facilities to protect the exit status (lock, cv, samophore, etc)

- Of course a pointer to `struct thread`

So the structure looks like:

``` c
struct process { 
    pid_t ppid; 
    struct semphore* exitsem; 
    bool exited; 
    int exitcode; 
    struct thread* self; 
};
```

### Pid allocation

For convenience and simplicity, I decided to support a maximum number of
`MAX_RUNNING_PROCS (256)` processes in the OS, regardless the `__PID_MAX (32767)` 
macro in `$OS161_SRC/kern/inlude/kern/limits.h`. So I just use a global static
array of `struct process*` to maintain all the processes in system. Of course
it's very dumb but hope it's sufficient for a toy OS like 161.

Then allocate a pid is very easy, just scan the process array and find a
available slot (`NULL`). One important thing to note is that leave `pid=0`
alone and do not use it. Since in `/kern/include/kern/wait.h`, there are two
special MACROs:

```
#define WAIT_ANY (-1) 
#define WAIT_MYPGRP (0)
```

That is, pid = 0 has a special meaning. So we'd better not use it, staring
allocate pid from 1. We can also see this from the `__PID_MIN (2)` macro in
`$OS161_SRC/kern/inlude/kern/limits.h`.

Once a available slot is found, we need to create a `struct process` and
initialize it appropriately, especially it's ppid (-1 or other invalid value).
