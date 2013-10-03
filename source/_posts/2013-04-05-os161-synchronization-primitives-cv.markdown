---
layout: post
title: "OS161 Synchronization Primitives: CV"
date: 2013-04-05 12:37
comments: true
categories: [os161]
tags: [cv, synchronization]
---

[Condition variable][cv] is used for a thread to wait for some condition to be
true before continuing. The implementation is quite simple compared to
[lock][lock], yet the difficult part is to understand how a CV is supposed to
used.

[cv]: http://en.wikipedia.org/wiki/Monitor_(synchronization)
[lock]: /2013/04/04/os161-synchronization-primitives-lock

<!-- more -->

### CV Interface

Condition variable has two interfaces: `cv_wait` and `cv_signal`. `cv_wait` is
used to wait for a condition to be true, and `cv_signal` is used to notify other
threads that a certain condition is true.

So what?

Let's consider a producer-consumer case, where a bunch of threads share a
resource pool, some of them (producer) is responsible to put stuff to the pool
and others (consumer) are responsible to take stuff from the pool. Obviously, we
have two rules.

1. If the pool is full, then producers can not put to the pool
2. If the pool is empty, then consumers can not take stuff from the pool

And we use two condition variables for each of these rules: `pool_full` and
`pool_empty`. Here is the pseudo code for producer and consumer:

``` c
void producer(void) {
    lock_acquire(pool_lock);
    while (pool_is_full) {
        cv_wait(pool_full, pool_lock);
    }
    produce();
    /* notify that the pool now is not empty, so if any one is waiting
     * on the pool_empty cv, wake them up 
     */
    cv_signal(pool_empty, pool_lock);
    lock_release(pool_lock);
}

void consumer(void) {
    lock_acquire(pool_lock);
    while (pool_is_empty) {
        cv_wait(pool_empty, pool_lock);
    }
    consume();
    /* notify that the pool now is not full, so if any one is waiting
     * on the pool_full cv, wake them up 
     */

    cv_signal(pool_full, pool_lock);
    lock_release(pool_lock);
}
```

Here we also use a lock to protect access to the pool. We can see from this
example:

1. Condition variable is virtually a wait channel
2. Condition variable is normally used together with lock, but **condition
   variable itself doesn't contain a lock**

### What's in `cv` structure?

Obviously, we need a wait channel. And that's it (probably plus a `cv_name`).


### `cv_wait` and `cv_signal`

Now let's get to business. The comment in `$OS161_SRC/kern/inlucde/synch.h`
basically told you everything you need to do. 

In `cv_wait`, we need to:

1. Lock the wait channel
2. Release the lock passed in
3. Sleep on the wait channel
4. When waked up, re-acquire the lock.

So before `cv_wait`, we should already hold the lock (so that we can release
it). And after `cv_wait`, we still hold the lock.

In `cv_signal`, we just wake up somebody in the wait channel using
`wchan_wakeone`.
