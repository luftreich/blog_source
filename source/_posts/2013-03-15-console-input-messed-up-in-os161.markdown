---
comments: true
date: 2013-03-15 04:26:57
layout: post
title: Console Input Messed up in OS161
categories: [os161]
tags: [console, exit, waitpid, syscall]
---

When you finished the process system call (e.g., `fork`, `execv`) and test your
system call by executing some user program, you'll probably find that the
console input behavior is messed up. 


<!-- more -->


For example, when you executing user shell from OS161 kernel menu, and then 
executing `/bin/true` from the shell, you may see this

``` bash
OS/161 kernel [? for menu]: s 
Operation took 0.000285120 seconds 
OS/161 kernel [? for menu]: (program name unknown): Timing enabled. 
OS/161$ /bin/true 
(program name unknown): bntu: No such file or directory 
(program name unknown): subprocess time: 0.063300440 seconds 
Exit 1
```

In this case, the shell program only receive the input "bnut" instead of your
input (`/bin/true`).

To find out why, we need to dig into how kernel menu (`$OS161_SRC/kern/startup/menu.c`)
works a little bit. When you hit "s" in the kernel menu. What happens?

1. `cmd_dispatch` will look up the `cmd_table` and call `cmd_shell`

2. `cmd_shell` just call `common_prog` with the shell path argument

3. `common_prog` will first create a child thread with the start function
`cmd_progthread`, then return

4. In the child thread, `cmd_progthread` will try to run the actual program
(in our case, the shell)

Note that the shell program is run in a separate child thread, and the parent
thread (i.e., the menu thread) will continue to run after he "forked" the child
thread.

So now there are actually two thread that want to read console input, which
leads to race condition. This is why the shell program receive corrupted input:
the menu thread eaten some of the inputs!

To solve this problem, we need to let the menu thread wait for the child
thread to complete, then return. So what we need to do is in `common_prog`, we
need to do a `waitpid` operation after we call `thread_fork`. And at the end of
`cmd_progthread`, we need to explicitly call `exit` with proper exit code in
case the user program doesn't do this.

Also note that `waitpid` and `exit` are in fact user land system call, and we can
not directly call them in kernel, so you may need to make some "shortcuts" in
your system call implementation to let the kernel be able to call `sys_waitpid`
and `sys_exit`.
