---
comments: true
date: 2012-04-27 23:27:26
layout: post
title: OS161 TLB Miss and Page Fault
categories: [os161]
tags: [tlb, page fault, vm]
---

Now we've set up user address space, it's time to handle TLB/page faults. Note
that there is a difference between TLB and page faults:

- TLB fault means the hardware don't know how to translate a virtual address
  since the translation didn't present in any TLB entry. So the hardware raise a
  TLB fault to let the kernel decide how to translate that address.

- Page fault means the user program tries to access a page that is not in
  memory, either not yet allocated or swapped out.


<!-- more -->


### TLB Entry Format

In sys161, which simulates MIPS R3000, there are totally 64 TLB entries. Each
entry is a 64-bit value that has the following format:


{% img center /images/2012-04-27-mipsr3000-tlb.png %}


Section 18.6 of [this document][tlb] contains a detailed description of the 
meaning of each bits. But briefly, VPN (abbr. for Virtual Page Frame Number) 
is the high 20 bits of a virtual address and PPN is the high 20 bits of a 
physical address space. **When Dirty bit is 1, it means this page is writable, 
otherwise, it's read-only.** When Valid bit is 1, it means this TLB entry 
contains a valid translation.

In OS161, we can just ignore the ASID part and Global bit, unless you really
want to do some tricks such as multiplex TLB among processes instead of just
shoot down all TLB entries when context switch. Also, we can ignore the NoCache
bit.

[tlb]: http://pages.cs.wisc.edu/~remzi/OSFEP/vm-tlbs.pdf


### TLB Miss Type

When translation a virtual address, the hardware will issue a parallel search
in all the TLB entries, using the VPN as a search key. If the hardware failed to
find a entry or find a entry but with Valid bit is 0, a TLB Miss will be
issued. The miss type could be `VM_FAULT_READ` or `VM_FAULT_WRITE`, depending on
whether it's a read or write operation. On the other hand, if it's a write
operation and hardware find a valid TLB entry of VPN, but the Dirty bit is 0,
then this is also a TLB miss with type `VM_FAULT_READONLY`.

If none of above cases happen, then this is a TLB hit, everybody is happy :-)


### TLB Manipulate Utils

Before we discuss how to handle a TLB fault. We first take a look at how
to manipulate the TLB entries. The functions that access TLB can be found
at `$OS161_SRC/kern/arch/mips/include/tlb.h`. Four routines are provided. And the
comments there are quite clear. We use `tlb_probe` to query the TLB bank, and use
`tlb_read`/`tlb_write` to read/write a specific TLB entry, and use `tlb_random` to
let the hardware decide which entry to write to.


### Finally, handle TLB Miss

On a TLB fault, the first thing to do is to check whether the faulting address
is a valid user space address. Since it's possible that the fault is caused by
`copyin`/`copyout`, which expect an TLB fault. So what's an "valid" user space
address?

- User code or date segment
- User heap, between `heap_start` and `heap_end`
- User stack

If the address is invalid, then we directly return some non-zero error code, to
let the `badfault_func` capture the fault.

For `VM_FAULT_READ` or `VM_FAULT_WRITE`, we just walk current address space's page
table, and see if that page actually exists (by checking the `PTE_P` bit). If no then we just
allocate a new page and modify the page table entry to insert the mapping
(since we haven't turn on swap yet, so **not exist means this is the first time
we access this page**). The permissions of the newly allocated page should be
set according to the region information we stored in `struct addrspace`.
Finally we just use `tlb_random` to insert this mapping to TLB. Of course,
you can adopt some TLB algorithm here that choosing a specific TLB victim. But
**only do this when you have all your VM system working.**

For `VM_FAULT_READONLY`, **this page is already in memory and the mapping is
already in TLB bank**, just that the Dirty bit is 0 and user try to write
this page. So **we first check if user can really write this page**, maybe
by the access bits in the low 12 bits of page table entry. (Recall that in
`as_define_region`, user passed in some attributes like readable, writable and
executable. You should record them down there and use them to check here).

If user want to write a page that he has no rights to write, then this is a
access violation. You can just panic here or more gracefully, kill current
process. But if user can actually write this page, then we first query TLB
bank to get the index of the TLB entry, set the Dirty bit of `entrylo` and write
it back use `tlb_write`. Don't forget to change the physical page's state to
`PAGE_STATE_DIRTY` (It's useless now but will be useful in swapping)

The above are pretty much what `vm_fault` does. Three extra tips:


- Since TLB is also a shared resource, so you'd better **use a lock to
protect the access to it**. And it's better be a `spinlock` since sometimes we
perform TLB operations in interrupt handler, where we don't want to sleep.

- **Do not print anything inside `vm_fault`.** `kprintf` may touch some of the
TLB entry so that the TLB has been changed between the miss and `vm_fault`, which
can lead to some really weird bugs.

- **Assumption is the source of all evil. Use a lot KASSET to make your
assumption explicit and check if they are right.**
