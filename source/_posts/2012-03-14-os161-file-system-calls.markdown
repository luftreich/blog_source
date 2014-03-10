---
comments: true
date: 2012-03-14 21:19:17
layout: post
title: OS161 File System Calls
categories: [os161]
tags: [open, read, write, close, dup2, lseek, syscall]
---

Assume you've read my previous post on [file operations in OS161][overview],
then everything is quite straightforward. One more thing, remember to protect
every access to the file descriptor data structure using lock!

Let's get started.

[overview]: /2012/03/14/os161-file-operation-overview/

<!-- more -->


### `sys_open` and `sys_close`

We'll rely on `vfs_open` to do most of the work. But before that, we need to
check:

- Is `filename` a valid pointer? (alignment, NULL, kernel pointer, etc.)

- Is flags valid? flags can only contain exactly one of `O_RDONLY`, `O_WRONLY`
  and `O_RDWR`

After these, we need to allocate a fd to the opened file: just scan the
`curthread->t_fdtable` and find a available slot (`NULL`). Then we need to
actually open the file using `vfs_open`. Note that we need to copy `filename`
into kernel buffer using `copyinstr`, for both security reasons, and that
`vfs_open` may destroy the pathname passed in.

Once `vfs_open` successfully returns, we can initialize a `struct fdesc`. Pay
special attention to `fdesc->offset`. Without `O_APPEND`, it should be zero.
But with `O_APPEND`, it should be file size. So we need to check it and use
`VOP_STAT` to get file size if necessary.

`sys_close` is quite easy. We first decrease the file reference counter. And
close the file using `vfs_close` and free the `struct fdesc` if the counter
reaches 0.


### `sys_read` and `sys_write`

As usual, before do anything, first check the parameters.

The main work here is using `VOP_READ` or `VOP_WRITE` together with `struct
iovec` and `struct uio`. `kern/syscall/loadelf.c` is a good start point.
**However, we need to initialize the `uio` for read/write for user space
buffers**. That means the `uio->uio_segflg` should be `UIO_USERSPACE`.

Note that `uio->uio_resid` is how many bytes left after the IO operation. So you
can calculate how many bytes are actually read/written by `len - uio->uio_resid`.

Since we've carefully handled std files when initialization. Here we just treat
them as normal files and pay no special attention to them.


### `sys_dup2`

The hardest thing here is not how to write `sys_dup2`, but instead how `dup2`
is supposed to be used. Here is a typical code snippet of how to use `dup2`

``` c
int logfd = open("logfile", O_WRONLY);

/* note the sequence of parameter */ 
dup2(logfd, STDOUT_FILENO); 
close(logfd);

/* now all print content will go to log file */ 
printf("Hello, OS161.\n");
```

We can see that in `dup2(oldfd, newfd)`:

- After `dup2`, `oldfd` and `newfd` points to the same file. But we can call 
`close` on any of them and do not influence the other.

- After `dup2`, all read/write to `newfd` will be actually performed on
`oldfd`. (Of course, they points to the same file!!)

- If `newfd` is previous opened, it should be closed in `dup2` ( according
to [`dup2` man page][dup2_man]).

Once we're clear about these. Coding `sys_dup2` is a piece of cake. Just don't
forget to maintain the `fdesc->ref_count` accordingly.

[dup2_man]: http://linux.die.net/man/2/dup2


### `sys_lseek`, `sys_chdir` and `sys__getcwd`

Nothing to say. Use `VOP_TRYSEEK`, `vfs_chidr` and `vfs_getcwd` respectively.
Only one thing, if `SEEK_END` is used. use `VOP_STAT` to get the file size, as
we did in `sys_open`

### 64-bit parameter and return value in lseek

This is just a minor trick. Let's first see the definition of `lseek`

``` c
off_t lseek (int fd, off_t pos, int whence)
```

And from `$OS161_SRC/kern/include/types.h`, we can see that `off_t` is type-defined as
64-bit integer (`i64`). So the question here is: how to pass 64-bit parameter
to `sys_lseek` and how get the 64-bit return value of it.

#### Pass 64-bit argument to sys_lseek

From the comment in `$OS161_SRC/kern/arch/mips/syscall/syscall.c`, we can see that, `fd`
should be in `$a0`, `pos` should be in (`$a2:$a3`) (**`$a2` stores high 32-bit and
`$a3` stores low 32-bit)**, and `whence` should be in `sp+16`. Here, `$a1` is not
used due to alignment.

So in the switch branch of `sys_lseek`, we should first pack (`$a2:$a3`) into a 64-bit
variable, say `sys_pos`. Then we use `copyin` to copy `whence` from user stack (`tf->tf_sp+16`).


### Get 64-bit return value of `sys_lseek`

Also from the comment, we know that a 64-bit return value is stored in
(`$v0:$v1`) (`$v0` stores high 32-bit and `$v1` stores low 32-bit). And note that
after the `switch` statement, `retval` will be assigned to $v0, so here we just
need to copy the low 32-bit of `sys_lseek`'s return value to $v1, and high
32-bit to `retval`.
