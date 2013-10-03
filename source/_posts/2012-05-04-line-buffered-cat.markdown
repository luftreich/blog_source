---
comments: true
date: 2012-05-04 14:44:15
layout: post
title: Line Buffered Cat
categories: [linux]
tags: [cat, grep]
---

I'd like to watch the output of a UART device in Linux, and I only want to see
the content when there are a whole line. So I prefer some kind of line-buffered
cat such as:

<!-- more -->

``` bash
$ cat --line-buffered /dev/crbif0rb0c0ttyS0
```

But unfortunately, `cat` doesn't have a line-buffered option. And fortunately,
GNU `grep` has such an option. So we can do

```
$ cat /dev/crbif0rb0c0ttyS0 | grep ^ --line-buffered
```

Since every line has a ^ (line start), so each line matches the `grep`. Note
that I ever tried

```
$ cat /dev/crbif0rb0c0ttyS0 | grep . --line-buffered
```

But this does not work. Only empty lines are printed, and I don't know why...
