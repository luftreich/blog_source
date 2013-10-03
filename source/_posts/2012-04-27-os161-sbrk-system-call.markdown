---
comments: true
date: 2012-04-27 22:17:36
layout: post
title: OS161 sbrk System Call
categories: [os161]
tags: [heap, sbrk, syscall, vm]
---

If you're not familiar with `sbrk` system call, here is [it's wiki][sbrk_wiki], 
and its [interface description][sbrk_interface]. In a nutshell,
`malloc` will use `sbrk` to get heap space.

[sbrk_wiki]: http://en.wikipedia.org/wiki/Sbrk
[sbrk_interface]: http://www.cs.utah.edu/flux/moss/node39.html

<!-- more -->

In `as_define_region`, we've find the highest address that user text and data
segment occupy, and based on this, we've set the `heap_start` in `struct
addrspace`. This makes the `sbrk` system call implementation quite easy: almost
just parameter checking work. Several points:

- `inc` could be negative, so make sure `heap_end+inc` >= `heap_start`

- Better to round up inc by 4. This is optional but can lower the chance
of unaligned pointers

After all these checking, just return `heap_end` as a `void*` pointer and increase
`heap_end` by `inc`. Of course, like any other system calls, you need to add a 
case entry in the `syscall` function.
