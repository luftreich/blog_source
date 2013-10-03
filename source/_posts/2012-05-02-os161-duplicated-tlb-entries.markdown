---
comments: true
date: 2012-05-02 17:18:47
layout: post
title: OS161 Duplicated TLB entries
categories: [os161]
tags: [tlb, vm]
---

Sys161 will panic if you try to write a TLB entry with a `entryhi`, but
there are already a TLB entry with the same `entryhi` but in a different TLB
slot. This is because **entryhi should be a UNIQUE key in the TLB bank.**

<!-- more -->

When you want to update a TLB entry (e.g., shoot down a TLB entry, or set the
Dirty bit, etc.), you need to first use `tlb_probe` to query the TLB bank to get
the TLB slot index and then use `tlb_read` to read the original value, and then
use `tlb_write` to write the updated TLB entry value to this slot. **But what
if there is a interrupt after you `tlb_probe` but before `tlb_read`?** Chance
maybe that the TLB bank is totally refreshed so that you read a stale value
and also write a stale value. Things get totally messed up and errors such as
"Duplicated TLB entries" may occur.

To resolve this, **you need to protect your whole "`tlb_probe`->`tlb_read`->
`tlb_write`" flow and make sure that this flow won't get interrupted.** So you 
really want to disable interrupt (`int x = splhigh()`) before you do `tlb_probe` 
and re-enable it (`splx(x)`) after `tlb_write`. Alternatively, you can also use a
spin lock to protect your access to TLB.
