---
comments: true
date: 2011-11-24 19:47:51
layout: post
title: Bash Alias with Argument
categories: [linux]
tags: [bash, alias, argument]
---

Alias is a very useful feature of shell (e.g. bash). For example, I have this
line in my `.bashrc`:

``` bash
alias ll="ls -alF | more"
```

<!-- more -->

So I can simply use `ll` to view all the files in current directory and view
them in my favorite style.

It works fine until one day, I want to view the files in a sub directory
instead of current directory, so I tried:

``` bash
$ ll subdirectory/
```

But it failed - still just display the content of current directory. The reason
is, for bash, the above command is interpreted as:

``` bash
$ ls -alF | more subdirectory/
```

But what I have in mind is actually:

``` bash
$ ls -alF subdirectory | more
```

I Googled and found that alias can just not take arguments, but devise a simple
functions is applicable, so I have the below code instead of the `ll` alias:

``` bash
unalias ll
function ll(){
    ls -alF "$@" | more;
}
```

**We need to first unalias since by default, `ll` is aliased as `ls -l
--color=auto`. If we don't remove the alias, our function won't be invoked.**
