---
comments: true
date: 2012-05-07 19:08:56
layout: post
title: Use trap to Do Cleanup Work When Script Terminates
categories: [linux]
tags: [trap, shell script]
---

Now I have the script that monitoring the output of several UART devices:

<!-- more -->

``` bash
#!/bin/bash

for i in `seq 0 7`; do
# use grep here to enforce line-buffered output, so concurrent
# input from UART isn't messed up
    cat /dev/crbif0rb0c${i}ttyS0 | grep ^ --line-buffered &
done

wait
```

But there is one problem, when you terminate the script (`ctrl+c`), these cat
processes won't be killed, so that the next time you run this script, you'll not
be able to access these UART device since they are busy.

To solve this problem, we need to do some cleanup work when the script
terminates. In this case, we need to kill these `cat` processes. We can use the
`trap` command to do this. Basically, **trap enables you to register a kind of
handler for different kind of signals**.

In this case, we can add a line into the script:

``` bash
trap "pkill -P $$" SIGINT

for i in `seq 0 7`; do
# use grep here to enforce line-buffered output, so concurrent
# input from UART isn't messed up
    cat /dev/crbif0rb0c${i}ttyS0 | grep ^ --line-buffered &
done

wait
```

`$$` is the process id of the script. `pkill -P $$` will kill all the child
processes of `$$`. So that when the script terminates (`SIGINT` signal from
`ctrl+c`), this `pkill` command will be executed and all the cat processes will
be killed.

Thanks to these post.

- <http://steve-parker.org/sh/trap.shtml>
- <http://www.davidpashley.com/articles/writing-robust-shell-scripts.html#id2564782>
