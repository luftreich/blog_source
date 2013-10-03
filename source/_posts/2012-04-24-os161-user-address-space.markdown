---
comments: true
date: 2012-04-24 23:14:14
layout: post
title: OS161 User Address Space
categories: [os161]
tags: [addrspace, vm, page table]
---

Now we've set up our coremap and also have the routines to allocate and free
physical pages. It's the time to set up user's virtual address space.

Basically, we'll adopt **two-level page table**. If you're not
already familiar with this, you can check out the [page table wiki][page_table] 
and [this document talking about MIPS and X86 paging][paging].

<!-- more -->


The page table entry format will be much alike those in X86. For a page
directory entry, the upper 20 bits indicates the base physical address of the
page table, and **we use one bit in the lower 12 bits to indicate whether this
page table exist or not**. For a page table entry, the upper 20 bits stores
the base physical address of the actual page, while the lower 12 bits contain
some attribute of this page, e.g., readable, writable, executable, etc. You are
free to define all these (format of page directory and page table entry)
though, since the addressing process are totally done by software in MIPS, but
following the conventions is still better for compatibility as well as easy
programming.

[page_table]: http://en.wikipedia.org/wiki/Page_table
[paging]: http://pages.cs.wisc.edu/~remzi/OSFEP/vm-tlbs.pdf


### What to store in the `addrspace` structure?

**An address space is actually just a page directory**: we can use this
directory and page table to translate all the addresses inside the address
space. And we also need to keep some other information like user heap start,
user heap end, etc. But that's all, and no more.

So in `as_create`, we just allocate a `addrspace` structure using `kmalloc`,
and allocate a physical page (using `page_alloc`) as page directory and store
it's address (either `KVADDR` or `PADDR` is OK, but you can just choose one).

Besides, we need to record somewhere in the `addrspace` structure the valid
regions user defined using `as_define_region`, since we're going to need that
information during page fault handing to check whether the faulted address is
valid or not.


### Address Translating with `pgdir_walk`

**This is another most important and core function in this lab.** Basically,
given an address space and virtual address, we want to find the corresponding
physical address. This is what `pgdir_walk` does. We first extract the page
directory index (top 10 bits) from the `va` and use it to index the page
directory, thus we get the base physical address of the page table. Then we
extract the page table index (middle 10 bits) from `va` and use it to index the
page directory, thus we get the base physical address of the actual page.

Several points to note:

- Instead of return the physical address, **you may want to return the page
table entry pointer** instead. Since in most cases, we use `pgdir_walk` to get
page table entries and modify it

- We'll also need to pass `pgdir_walk` a flag, indicating that whether we want
to create a page table if non-exist (remember the **present bit** of page
directory entry?). Since sometimes, we want to make sure that a `va` is mapped to
a physical page when calling `pgdir_walk`. But most of the time, we just want to
query if a `va` is mapped.

- Think clearly about which is physical address, and which is virtual
address. Page directory entry and page table entry should store the physical
address base. You'll need a lot `PADDR_TO_KVADDR` here.


### Copy address space using `as_copy`

This part is easy if you decide not support Copy-On-Write pages. Basically, you
just `pgdir_walk` old address space's page table, and copy all the present pages.
Only one point, don't forget to **copy all the attribute bits (low 12 bits) of
the old page table entry**.

You'll get some extra work when you enable swapping: you need to copy all the
swapped pages beside present pages as well.

#### Destroy address space with `as_destroy`

Same easy as `as_copy`, just `pgdir_walk` the page table and free all the present
pages. Also same with `as_copy`, you need to free the swapped pages latter


### Define regions using `as_define_region`

Since we'll do **on-demand paging**, so we won't allocate any pages in
`as_define_region` Instead, we just walk through the
page table, and set the attribute bits accordingly. One point, remember the
`heap_start` and `heap_end` field in `struct addrspace`? Question: **where should
user heap start? Immediately after user bss segment!** And how would we know the
end of user bss segment? In `as_define_region`! So each time in `as_define_region`,
we just compare addrspace's current hew` and the region end, and set
the `heap_start` right after (`vaddr+sz`). Don't forget to **proper align the
`heap_start`(by page bound)**, of course.

This should also be the place we record each region information (e.g., base,
size, permission, etc) so that we can check them in `vm_fault`.

{% img center /images/2012-04-24-mips-as1.png %}

### Miscellaneous
In `as_activate`, if you don't use the ASID field of TLB entry, then you can just
shoot down all the tlb entries. It's the easiest to way to go.

In `as_prepare_load`, we need to change each regions' page table permision as read-write
since we're going to load content (code, date) into them. And in
`as_complete_load`, we need to change their page table permissions back to
whatever the original value.

In `as_define_stack`, we just return `USERSTACKTOP`.
