---
comments: true
date: 2012-03-18 15:19:27
layout: post
title: OS161 Process Scheduling
categories: [os161]
tags: [scheduling, MLFQ]
---


OS161 provides a simple round-robin scheduler by default. It works like this: 

- `hardclock` from `$OS161_SRC/kern/thread/clock.c` will be periodically called 
(from hardware clock interrupt handler)

- Two functions may be called there after:
    - `schedule` to change the order the threads in ready queue, which currently
      does nothing
    - `thread_consider_migraton` to enable thread migration among CPU cores

- Then it will call `thread_yield` to cause the current thread yield to another
  thread

We need to play with the `schedule` function to give interactive threads higher
priority.

<!-- more -->

### Why give priority to interactive threads?

There are two reasons about this (at least the two in my mind) :

- **Your time is more valuable than computer's**. So in general, we
should first serve those threads that interact with you. For example, you don't
want to wait the computer in a shell while it's busy doing backup, right?

- Interactive threads tend to be I/O bound, which means they often get stuck
waiting for input or output. So they normally fail to consume their granted
time slice. Thus we can switch to computation bound threads when they stuck and
boost computer utilization.


### How can we know whether a thread is interactive or not?

As said above, interactive threads are normally I/O bound. **So they often need
to sleep a lot.**

In `$OS161_SRC/kern/thread/thread.c`, we can see that `thread_switch` is used to actually
switch between threads. The first argument is `newstate`, which give some hints
about the current thread.

If `newstate` is `S_READY`, it means that **current thread has consumed all
its time slice and is forced to yield to another thread** (by hardware clock).
So we can guess that it's not interactive, or, it's computation intensive.
However, if `newstate` is `S_SLEEP`, then it means **current thread offers to
yield to another thread**, maybe waiting for I/O or a mutex. Thus we can guess
that this thread is more interactive, or, it's I/O intensive.

So by the `newstate`, we can make a good guess of current thread.


### How to implement it?

[Multi-Level Feedback Queue][mlfq] seems to be a good enough algorithm in
this case.

[mlfq]: http://en.wikipedia.org/wiki/Multilevel_feedback_queue

We can add a priority field in `struct thread` and initiate it as medium
priority in `thread_create`. Then in `thread_swith`, we can adjust current
thread's priority by the `newstate`. 

- If it's `S_SLEEP` then we increase current thread's priority. 
- Otherwise, if it's `S_READY` then we decrease current thread's priority. 

Of course, we can only support a finite priority level here, **so be careful 
with boundary case**. For example, if current thread is
already the highest priority and still request `S_SLEEP`, then we just leave it
in that priority.

Then in `schedule`, we need to **find the thread with highest priority
among all the threads in `curcpu->c_runqueue`, and bring it to head**.

Current CPU's run queue is organized as a double linked list with head
element. `$OS161_SRC/kern/include/threadlist.h` provides several useful interface to
let us manipulate the list. Find a maximum/minimum number among a list
is so simple that I won't provide any details here. But note that **the
head element is just a place holder**. So you may want to start from
`curcpu->c_runqueue.tl_head.tln_Next` and stop when `elem->tln_next == NULL`.

Once find the thread, we need to bring it to list head so we can
leave `thread_switch` unchanged. A `threadlist_remove` followed by
`threadlist_addhead` will be sufficient here.

**One problem of MLFQ is starvation**. So you may want to periodically reset all
threads' priority to medium level for fairness.

That's all. Here's just a work solution. Much work has be done if you want
better scheduling for performance.

