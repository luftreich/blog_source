---
layout: post
title: "OS161 Synchronization Primitives: RWLock"
date: 2013-04-05 13:30
comments: true
categories: [os161]
tags: [rwlock, synchronization]
---

The idea of [Reader-Writer Lock][wiki] is quite simple. In normal [lock][lock],
we don't differentiate the threads. That said, each thread who wants to enter the
critical section must first acquire the lock. But on a second thought, you may
find that threads actually have different behavior inside the critical section:
some threads just want to see the values of shared variable, while others really
want to update those variables.

[wiki]: http://en.wikipedia.org/wiki/Readers%E2%80%93writer_lock
[lock]: /2013/04/04/os161-synchronization-primitives-lock

<!-- more -->

### An Example

Suppose we have a book database in a library, each reader who wants to query the
database must first acquire the lock before he can actually do the query. The
library manager, who wants to update some book info also need to acquire the
lock before he can do the actual update. In this case, we can see that the
queries of multiple readers in fact have no conflict. So ideally they should be
allowed to be in the critical section at the same time. On the other hand, the
library manager must have exclusive access to the database while he's updating.
No readers, no other managers can enter the critical section until the first
manager leaves.

So, two rules for rwlock:

1. Multiple readers can in the critical section at the same time
2. One and only one writers can in the critical section at any time

### Starvation

Suppose the coming sequence of threads are "RWRRRRR...", in which R denotes reader
and W denotes writer. The first reader arrives, and found no one in the critical
section, and he happily comes in. Before he leaves, the writer arrives, but
found there is a reader inside the critical section, so the writer wait. While
the write is waiting, the second reader comes and find there is one reader
inside the critical section, literally, it's OK for him to come in according to
the rules, right? The same case applies to the third, forth,..., readers.

So without special attention, we see readers come and go, while the poor writer
keeps waiting, for virtually a "unbounded" time. In this case, the writer is
starved.

The thing is, the second, third, forth..., readers shouldn't enter critical section 
since there is a write waiting before them!

### Implementation

There are many ways to implement rwlock. You can use any of the semaphore, cv or 
lock. Here I introduce one using semaphore and lock. It's very simple, yet has
the limitation that only support support at most a  certain number of readers in
the critical section.

Let's imagine the critical section as a set of resources. The initial capacity
is `MAX_READERS`. The idea is each reader needs one of these resources to enter 
the critical section, while each writer needs all of these resources (to prevent other
readers or writers) to enter.

To let the readers be aware of the waiting writers, each thread should first
acquire a lock before he can acquire the resource. 

So for `rwlock_acquire_read`:

1. Acquire the lock
2. Acquire a resource using `P`
3. Release the lock

For `rwlock_release_read`, just release the resource using `V`.

In `rwlock_acquire_write`:

1. Acquire the lock, so that no other readers/writer would be able to acquire
   the rwlock
2. Acquire **ALL** the resources by doing `P` `MAX_READERS` times
3. Release the lock. It's safe now since we got all the resources.

For `rwlock_release_write`, just release all the resources.
