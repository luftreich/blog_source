---
comments: true
date: 2012-07-11 15:39:14
layout: post
title: "Dropbox: Unable to monitor filesystem"
categories: [errors]
tags: [dropbox]
---

Sometime this error occurs that says:

> "Unable to monitor file system. Please run: echo 100000 | sudo tee
> /proc/sys/fs/inotify/max_user_watches and restart Dropbox to correct the
> problem.

<!-- more -->


We need to adjust the system setting on the maximum file number that Dropbox
can watch.

The following command will solve your pain:


``` bash
$ echo fs.inotify.max_user_watches=100000 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p
```

Here is [the tip from Dropbox website][tip].

[tip]: https://www.dropbox.com/help/145/en
