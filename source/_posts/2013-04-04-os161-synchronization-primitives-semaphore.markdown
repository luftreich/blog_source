---
layout: post
title: "OS161 Synchronization Primitives: Semaphore"
date: 2013-04-04 14:52
comments: true
categories: [os161]
tags: [semaphore, synchronization]
---

[Semaphore][wiki] denotes a certain number of shared resources. Basically, it's
one counter and two operations on this counter, namely `P` and `V`. `P` is used
to acquire one resource (thus decrementing the counter) while `V` is used to
release one resource (thus incrementing the counter).

[wiki]: http://en.wikipedia.org/wiki/Semaphore_(programming)

<!-- more -->

### A Metaphor

My favorite example is the printer. Say we have three printers in a big lab,
where everybody in the lab shared those printers. Obviously only one printing
job can be conducted by one printer at any time, otherwise, the printed content
would be messed up. 

However, we can not use a single lock to protect the access of all these three
printers. It'll be very dumb. An intuitive way is to use three locks, one for
each printer. Yet more elegantly, we use a semaphore with initial counter as 3.
Every time before a user submit a print job, he need to first `P` this semaphore
to acquire one printer. And after he is done, he need to `V` this semaphore to
release the printer. If there is already one print job at each printer, then the
following poor guys who want to `P` this semaphore would have to wait.


### What should a semaphore structure contain?

Apparently, we need an **counter** to record how many resources available. Since
this counter is a shared variable, we need a **lock** to protect it. At this point,
we only have the `spinlock` provided in `$OS161_SRC/kern/include/spinlock.h`.
That's fine since our critical section is short anyway. In order to let the poor
guys have a place to wait, we also need an **wait channel** (in
`OS161_SRC/kern/include/wchan.h`)

### `P` Operation

The flow of `P` would be:

1. Acquire the spin lock
2. Check if there are some resources available (`counter > 0`)
3. If yes, we're lucky. Happily go to step 8. 
4. If no, then we first grab the lock of the wait channel, since the wait
   channel is also shared.
5. Release the spin lock, and wait on the wait channel by calling `wchan_sleep`
6. We're sleeping...
7. After wake up, first grab the spin lock, and go to step 2
8. At this point, the `counter` should be positive, decrement it by 1
9. Release the spin lock, and return

### `V` Operation

`V` is much simpler compared to `P`. The flow is:

1. Acquire the spin lock
2. Increment the `counter` by 1
3. Wake up some poor guy in the wait channel by calling `wchan_wakeone`)
4. Release the spin lock and return

