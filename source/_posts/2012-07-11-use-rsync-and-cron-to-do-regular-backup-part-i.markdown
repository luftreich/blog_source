---
comments: true
date: 2012-07-11 16:23:45
layout: post
title: Use rsync and cron to do regular backup (Part I)
categories: [linux]
tags: [cron, rsync, backup]
---

Recently I do most of my work on a remote data center through a slow network
connection (<100KB/sec). I usually backup my project source tree as follows.
I first do make clean and also delete any unnecessary obj files to shrink the
total file size, then I compress the whole source tree as a tar ball and then I
use `scp` locally to fetch the backup tar ball to my local machine. The procedure
is quite boring since I need to do this every day before I go home, otherwise
the whole bandwidth will be occupied for near an hour during which I can almost
do nothing.

Situation gets better when I find `rsync` and `cron`. Here is how I do automatic
regular (daily) backup with them.

<!-- more -->

[Rsync][rsync] is a file synchronization tool
that aims to minimize the data transfer during copy files. This is done via
only send the diffs to destination. It is perfect when you need to do regular
copy between two fixed locations. Rsync has many options (well, as most of
other GNU tools), here is two of them that are used more frequently:

[rsync]: http://en.wikipedia.org/wiki/Rsync

``` bash
# ensure that symbolic links, devices, attributes, permissions, 
# ownerships, etc are preserved in the transfer 
-a, --archive

#compress data during transfer, especially useful when the bandwidth is limited
-z, --compress

# exclude the directories or files that you don't want to sync, such as obj
# files, tag files, etc 
--exclude
```
Suppose that you have a source tree on host B: `~/src`, and you want to sync this
source tree with a local folder named: `~/src_backup`, then the follow command
will suffice:

``` bash
$ rsync -avz --exclude "obj/" --exclude "tags" --exclude "build" b@B:~/src/ ~/src_backup 
```

The two exclude option will tell rsync to skip the obj subdirectory as well
as the tags file. The trailing slash in the source (`b@B:~/src/`) will tell
rsync not to create an additional directory level at the destination. Without
this slash, rsync will create a `src` directory under `~/src_backup`, which is not
desirable.

Now that after the first time rsync, the following rsync commands will only
transfer the file changes to local, which is a great save of the bandwidth.
