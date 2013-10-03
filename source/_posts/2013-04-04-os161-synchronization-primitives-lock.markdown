---
layout: post
title: "OS161 Synchronization Primitives: Lock"
date: 2013-04-04 15:23
comments: true
categories: [os161]
tags: [synchronization, lock]
---

Lock is basically just a semaphore whose initial counter is 1. `lock_acquire` is
like `P`, while `lock_release` is like `V`. You probably want to go over 
[my previous post about semaphore][semaphore]

[semaphore]: /2013/04/04/os161-synchronization-primitives-semaphore

<!-- more -->

### Lock's holder

However, since only one can hold the lock at any given time, that guy is
considered to be the **holder** of this lock. While in semaphore, we don't have
such a holder concept since multiple thread can "hold" the semaphore at the same
time.

Thus we need to store the holder information in our lock structure, along with the
conventional spin lock and wait channel. Intuitively, you may tempted to use the
thread name (`curthread->t_name`) as the thread's identifier. Nevertheless, same
with the case in real world, the thread's name isn't necessarily unique. The 
OS161 doesn't forbidden us to create a bunch of threads with the same name.

There is a global variable defined in `$OS161_SRC/kern/include/current.h` named
`curthread`, which is a pointer to the kernel data structure of current thread.
Two different threads definitely have different thread structures, which makes
it a good enough thread identifier.

### Reentrant Lock

Another trick thing is to decide whether we support [reentrant lock][wiki] or not.
Basically, a process can acquire a reentrant lock multiple times without
blocking itself.

At first glance, you may wonder what kind of dumb thread would acquire a lock
multiple times anyway? Well, that kind of thread does exist, and they may not be
dumb at all. Reentrant lock is useful when it's difficult for a thread to track
whether it has grabbed the lock. Suppose we have multiple threads that traverse
a graph simultaneously, and each thread need to first grab the lock of a node
before it can visit that node. If the graph has a circle or there are multiple
paths leads to the same node, then it's possible that a thread visit the same
node twice. Although there is a function named `lock_do_i_hold` that can tell
whether a thread holds a lock or not, unfortunately it's not a public interface of lock.

In OS161, it's OK that you choose to not support reentrant lock, so when you
detect a thread try to acquire a lock while it's the lock's holder, just panic.
But if you want to support reentrant lock, **you need to make sure a thread won't
accidentally loose a lock.** For example,

``` c
void A(void) {
    lock_acquire(lock1);

    B();

    lock_release(lock1);
}

void B(void) {
    lock_acquire(lock1);

    printf("Hello world!");

    lock_release(lock1);
}
```

In this case, the thread is supposed to still hold the lock **after** B
returns.

The simplest way would be, keep a counter (initial value 0) for each lock. When 
a thread acquires a lock, increase that counter. When it release the lock, decrease 
the counter, only actually release a lock when the counter reaches 0.

[wiki]: http://en.wikipedia.org/wiki/Reentrant_mutex
