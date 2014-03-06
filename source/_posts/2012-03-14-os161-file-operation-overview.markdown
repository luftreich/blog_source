---
comments: true
date: 2012-03-14 20:33:50
layout: post
title: OS161 File Operation Overview
categories: [os161]
tags: [file, syscall, fdtable ]
---

In user space, when open a file, user program will get a file descriptor (a
integer) that represent that file. User can use this descriptor to perform various
operations on this file: read, write, seek, etc. As I see it, this design is
quite clean in that:

- Hide most of the details from user, for both safety and simplicity

- Enable more high level abstraction: everything (socket, pipe..) is a file

The file descriptor is actually an index to kernel space structure that
contains all the details of opened files. So at kernel side, we need to do a
lot bookkeeping stuff.

<!-- more -->


### What information should be kept?

It's helpful to take a look at `$OS161_SRC/kern/include/vnode.h`. In a nutshell, a file
is represented by a `struct vnode` in kernel space. And most of the underlying
interfaces that help us to manage files have already been provided. **All we
need to do is just bookkeeping.** So basically, we need to record the following
details about a file:

- File name. We don't actually need this, but just in case. For example, we
may want to print a file's name when debuging.

- Open flags. We need to keep the flags passed by `open` so that later on we can check
permissions on read or write.

- File offset. We definitely need this.

- File's reference counter. Mainly for `dup2` and `fork` system call

- A lock to protect the access to this file descriptor. Since it's possible that two
threads share the same copy of this bookkeeping data structure (e.g., after `fork`)

- Actual pointer to the file's `struct vnode`

So a file may be represented by the below structure in kernel space.

``` c
struct fdesc{ 
    char name[MAX_FILENAME_LEN]; 
    int flags; 
    off_t offset; 
    int ref_count; 
    struct lock* lock; 
    struct vnode* vn; 
};
```

__Note__: The name `fdesc` is a bit confusing. Maybe a better name would be `fhandle`.

Why we didn't record the file's fd? Please see next section.


### File descriptor Allocation

There are some common rules about file descriptor:

- 0, 1 and 2 a special file descriptors. They are stdin, stdout and stderr
respectively. (Defined in `$OS161_SRC/kern/include/kern/unistd.h` as
`STDIN_FILENO`, `STDOUT_FILENO` and `STDERR_FILENO`)

- The file descriptor returned by open should be the smallest fd available.
(Not compulsory though)

- **fd space is process specific**, i.e. different process may get the same
file descriptor that represent different files

So, to maintain each process's opened file information, we add a new field to
`struct thread`

``` c
/* OPEN_MAX is defined in $OS161_SRC/kern/include/limits.h */
struct fdesc* t_fdtable[OPEN_MAX];
```

Now you may figure out why there isn't a fd filed in `struct fdesc`, since its
index is the fd! So when we need to allocate a file descriptor, we just need
to scan the `t_fdtable` (from `STDERR_FILENO+1` of course), find an available 
slot (`NULL`) and use it. Also, since it's a `struct thread` field, it's process 
specific.

Does the `t_fdtable` look familiar to you? Yes, it's very similar to our
process array, only that the later is system-wise. (Confused? See 
[my previous post on fork](/2012/03/11/os161-fork-system-call))


### `t_fdtable` Management and Special Files

Whenever you add a new field to `struct thread`, don't forget to initialize
them in `thread_create` and do clean up in `thread_exit` and/or `thread_destroy`.
Since `t_fdtable` is an fixed size array, work a lot much easier: just zero
the array when create, and no clean up is needed. Also, **`t_fdtable` are
supposed to be inheritable: so copy a parent's `t_fdtable` to child when do
`sys_fork`.**

Since parent and child thread are supposed to share the same file table, so
when copy file tables, remember to increase each file's reference counter.

**Console files (std in/out/err) are supposed to be opened "automatically" when 
a thread is created**, i.e. user themselves don't need to open them. Note that **each
thread should open these files separably** , otherwise console I/O won't behave
correctly.

At first glance, `thread_create` would be a intuitive place to  initialize them.
Yes, we can do that. But be noted that when the first thread is created, the console 
is even not bootstrapped yet, so if you open console files in `thread_create`, it'll
fail (silently blocking...) at that time.

Another way is that we can lazily open the console files: when reading or
writing console files, we first check if they've already been opened 
, then open it if not. (This method seems not clean, but it works...)

BTW, **how to open console**? The path name should be "con:", flags should
be: `O_RDONLY` for stdin, `O_WRONLY` for stdout and stderr; options should be `0664`
(Note the zero prefix, it's a octal number)
