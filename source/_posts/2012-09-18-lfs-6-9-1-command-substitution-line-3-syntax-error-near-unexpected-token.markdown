---
comments: true
date: 2012-09-18 18:57:23
layout: post
title: "LFS 6.9.1: command substitution: line 3: syntax error near unexpected token  `)'"
categories: [errors]
tags: [lfs, bison, glic, yacc]
---

I encountered this error when compiling glibc. The apparent cause is that
bash can not deal with brackets correctly. So even a simple command like echo
`$(ls)` will fail with the same error (command substitution).

<!-- more -->

The most suspicious cause is that when compile bash in section 5.15.1, I use
`byacc` for walk around when the compiler complained the absence of `yacc`. **Bash
uses yacc grammer rules and only GNU bison will generate the correct parsing
code for the bash build**. So I un-installed byacc and installed bison. Then
	
- Make a soft link at `/usr/bin/yacc` to bison
	
- Recompile all the package after 5.10 (tcl) and before 5.15 (include 5.15)
	
- Test if problem solved using echo `$(ls)` command
	
- If yes, then using `/tools/bin/bash --login +h` to lunch the new bash


Also see:

- <http://www.mail-archive.com/lfs-support@linuxfromscratch.org/msg16549.html>
- <http://unix.stackexchange.com/questions/28369/linux-from-scratchs-bash-problem-syntax-error>
