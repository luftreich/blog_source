---
comments: true
date: 2012-03-28 21:59:26
layout: post
title: 'OS161: Arguments Passing in System Call'
categories: [os161]
tags: [syscall, argument passing, copyin, copyout]
---

One principle of kernel programming is that: **do not trust anything users
passed in**. Since we assume that users are bad, they will do anything they can
to crash the kernel (just as `$OS161_SRC/user/testbin/badcall/badcall.c` do). So 
we need pay special attention to the arguments of the system calls, **especially the
pointers**.

<!-- more -->

`$OS161_SRC/kern/vm/copyinout.c` provides several useful facilities to safely copy user
level arguments into kernel or vice versa. They assure that **even if user arguments is
illegal, the kernel can still get control and handle the error, instead of just
crash**. So let's see how can they be applied in the system calls.


### User space strings

Some system call, e.g. `open`, `chdir`, `execv`, requires a user level string as
arguments. We can use `copyinstr` to do this. See the prototype of `copyinstr`:

``` c
int copyinstr(const_userptr_t usersrc, char* dest, size_t len, size_t *actual) 
```

`const_userptr_t` is just a signpost that make `usersrc` explicitly looks like a user
pointer. So basically, this function copies a `\0` terminated user
space string into kernel buffer `dest`, and copy as much as `len` bytes, and
return the actual bytes copied in `actual`. Note that `copyinstr` will also
copy the last `\ 0`. Suppose we have a function that takes a user space string
as argument.

``` c
int foo (char* name) { 
    char kbuf[BUF_SIZE]; 
    int err;
    size_t actual;

    if ((err = copyinstr((const_userptr_t)name, kbuf, BUF_SIZE, &actual)) != 0)
    { 
        return err; 
    } 
    return 0; 
}
```

Then if we call `foo("hello")`, on success, `actual` will be 6, **including the
last `\0`**.

### User space buffer


In system calls like `read` or `write`, we need to read from or write to user space
buffers. We can use `copyin` or `copyout` here. For example:

``` c
int foo_read(unsigned char* ubuf, size_t len) 
{ 
    int err;

    void* kbuf = kmalloc(len); 
    if ((err = copyin((const_userptr_t)ubuf, kbuf, len)) != 0) 
    { 
        kfree(kbuf);
        return err; 
    }

    if ((err = copyout(kbuf, (userptr_t)ubuf, len)) != 0) 
    { 
        kfree(kbuf);
        return err; 
    }

    return 0; 
}
```

