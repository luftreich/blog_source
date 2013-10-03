---
comments: true
date: 2012-07-11 16:53:52
layout: post
title: Use rsync and cron to do regular backup (Part II)
categories: [linux]
tags: [cron, rsync, backup]
---

Now that we can [take advantage of rsync to minimize the data to transfer when
backup][post]. But it's still a little uncomfortable if we need to do this manually
everyday, right? Well, cron is here to solve the pain.

<!-- more -->

[Cron][cron] is kind of a system service that
automatically do some job as you specified. Backup, for example, is a perfect
kind of job that we can count on cron.

[post]: /2012/07/11/use-rsync-and-cron-to-do-regular-backup-part-i
[cron]: http://en.wikipedia.org/wiki/Cron

First, we need to specify a job that we want cron to do. In my case, I want
cron to automatically sync my source tree folder on remote data center and my
local backup folder. A simple rsync command seems meet my need. But actually,
there are more to consider:

- I don't want to copy the obj files, since they are normally large in size
and change frequently, but can be easily re-generated. But I also don't want to
skip the entire build folder when do rsync since there are some configure files
in there.

- The backup process should be totally automated. More specifically, no
password is needed when do rysnc.

Towards the first need, I can use ssh to send remote command to
do necessary clean up work before rysnc. And the second need can
be meted according to my previous post about [ssh/scp without password][ssh].

[ssh]: /2012/04/27/sshscp-without-password

So my final backup script looks like this:

``` bash
#!/bin/sh 
# ~/backup.sh

LOG_FILE=~/backup.log 
SOURCE_DIR=b@B:~/src/ 
TARGET_DIR=~/src_backup

date >> $LOG_FILE 
echo "Synchronization start..." >> $LOG_FILE 
ssh b@B 'cd ~/src/build; make clean; rm -rf obj/" >> $LOG_FILE 
rsync -avz --exclude "tags" $SOURCE_DIR $TARGET_DIR >> $LOG_FILE 
echo "Synchronization done" >> $LOG_FILE
```

Once we figure out what to do, we need to tell cron about our job. The
configure file of cron is `/etc/crontab`. A job description is like follows:

```
# Example of job definition: 
# .----------------minute (0 - 59) 
# | .------------- hour (0 - 23) 
# | | .---------- day of month (1 - 31) 
# | | | .------- month (1 - 12) OR jan,feb,mar,apr ... 
# | | | | .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat 
# | | | | | 
# * * * * * user-name command to be executed 0 0 * * * jack ~/backup.sh
```

I want to do backup every day on midnight so I set the minute and hour both to
0. The asterisk (`*`) symbol in day/month means any valid values.

Now we are done. The back up process is completely automated and scheduled.

**Reference**:

<http://myhowtosandprojects.blogspot.hk/2008/07/sincronize-folders-with-rsync-using-ssh.html>
