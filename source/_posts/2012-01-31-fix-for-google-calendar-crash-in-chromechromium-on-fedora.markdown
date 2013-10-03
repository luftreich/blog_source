---
comments: true
date: 2012-01-31 22:20:26
layout: post
title: Fix for Google Calendar Crash in Chrome/Chromium on Fedora
categories: [errors]
tags: [chrome, google calendar, fedora]
---

This problem is caused by the collision of chrome/chromium sandbox and Fedora's
SELinux, as explained [here][bug]. The same problem occurs when you open
twitter (see [this][twitter2]).

<!-- more -->

[bug]: https://bugzilla.redhat.com/show_bug.cgi?id=710273#c1
[twitter2]: http://jamesmcdonald.id.au/it-tips/chromium-browser-fedora-15-twitter-aw-snap

The solution is

```
restorecon -R ~/.config

# install restorecond
su -c 'yum install policycoreutils-restorecond'
# enable it
su -c 'chkconfig restorecond on'
```
