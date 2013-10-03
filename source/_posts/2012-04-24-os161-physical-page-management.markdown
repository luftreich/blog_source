---
comments: true
date: 2012-04-24 22:11:05
layout: post
title: OS161 Physical Page Management
categories: [os161]
tags: [vm, coremap]
---

We'll talk about `page_alloc`, `page_free`, `alloc_kpages` and `free_kpages`.


<!-- more -->


### Allocate one single physical page with `page_alloc`

This is relatively easy once you've decided which paging algorithm to use. FIFO
seems good enough in in terms of simplicity as well as acceptable performance.
We just scan the coremap, find out if there is any FREE page, or find out the
oldest page. At this stage (before swapping), I will use a magic function
called `MAKE_PAGE_AVAIL`, which obviously makes a page available, by flushing or
swapping, we don't care :-). Once we find a victim (maybe free, clean, or
dirty, but **must not be fixed**), we call `MAKE_PAGE_AVAIL` on it, and update
it's internal fields like time stamp, `as`, `va`, etc. And don't forget to zero the
page before we return.

A trade-off here is what parameters should we pass to `page_alloc`? One
choice is nothing: I just tell you to give me a page, and I'll deal with
the page meta-info by myself. But this manner will probably cause page-info
inconsistency, e.g., caller forget to set page's state. So to avoid this case,
I prefer caller tell `page_alloc` all he needs, like `as`, `va`, whether the
allocate page need to keep in memory, etc. And let `page_alloc` set the page's
meta info accordingly.

BTW, since coremap is a globally share data structure, so **you really want to
use lock to protect it every time you read/write it.**


### Allocate n continuous pages with `page_nalloc`

Since kernel address will bypass TLB and are directly-mapped. (See
[this][mips_r3000] and [this][mips_arch] for details), when we're asked to allocate 
n (where n > 1) pages by `alloc_kpages`, we must **allocate n continuous pages**! 
To do this, we need to first find a chunk of n available (i.e., not fixed) continuous 
pages, and then call `MAKE_PAGE_AVAILABLE` on these pages. Like `page_alloc`, we 
also need to update the coremap and zero the allocated memory.

As mentioned in [my previous blog about coremap][coremap_post], in `alloc_kpages`, 
**we need to first check whether vm has bootstrapped**: if not, we just use 
`get_ppages`, otherwise, we use our powerful `page_nalloc`.

Also, we need to record how many pages we allocated so that when calling `free_kpages`, 
we can free all these `npages `page.


[mips_r3000]: http://www.eecs.harvard.edu/~mdw/course/cs161/handouts/mips.html#segments
[mips_arch]: http://cgi.cse.unsw.edu.au/~cs3231/10s1/os161/man/sys161/mips.html
[coremap_post]: /2012-04-24-os161-coremap


### Free a page with `page_free` and `free_kpages`

We just need to mark this page as FREE. But if this page was mapped to user
address space (`page->as != NULL`), then we need first unmap it, and shoot down
the TLB entry if needed. We'll talk about user address space management lately.


Only one tip for this part, **do not forget to protect every access to coremap
using lock (but not spinlock).**
