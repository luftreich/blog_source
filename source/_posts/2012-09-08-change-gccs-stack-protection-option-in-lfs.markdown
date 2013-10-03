---
comments: true
date: 2012-09-08 15:39:27
layout: post
title: "LFS 5.5.1: Change GCC's Stack Protection Option"
categories: [linux]
tags: [lfs, gcc, sed]
---

In [Chapter 5.5][5.5], there is one step that fixes the GCC's stack protection
detection problem. The command is:

``` bash
sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
```

[5.5]: http://www.linuxfromscratch.org/lfs/view/stable/chapter05/gcc-pass1.html

<!-- more -->

This command seems weird to me at first glance. After digging a little more
about `sed` command, it's intention is much clear.

- **-i** means change the file (i.e., `gcc/configure`) in place

- **/k prot/** is the pattern. If you look at `gcc/configure`, you'll find a
line (around 26695) of comment that says:

``` bash
# Test for stack protector support in target C library
```

And you'll see that this is the only occurrence of "stack protector" (as well
as `k prot`. I think we'd better use `/stack protector/` as the pattern for
easy understanding.

- **a** means append a line after the line that contains the pattern. ([sed document][doc])

- **gcc_cv_libc_provides_ssp=yes** is the actual line being appended.

[doc]: http://www.grymoire.com/Unix/Sed.html#uh-40
