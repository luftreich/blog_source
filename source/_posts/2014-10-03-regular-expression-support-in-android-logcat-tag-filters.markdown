---
layout: post
title: "Regular Expression Support in Android Logcat Tag Filters"
date: 2014-10-03 19:10:15 -0400
comments: true
categories: ['android']
tags: ['logcat', 'python', 'regular expression', 'tag']
---

For a while I've been using `logcat` command line tools to check
Android logs. Usually, the tags of my app consist of a common prefix and the
name of different sub-components (I guess that's also what most apps do). And I
have about a dozen of such tags. `logcat`, however, does not support filtering
tags using regular expressions, which is a pain! After suffering for a long
time, I finally decide to tackle this.

<!--more-->

## Logcat Tag Filters

The basic `logcat` options can be found in the [official document][logcat],
which also contains a brief explanation of [`logcat` filter format][filter].
Basically, you provide a series of `logcat` filters, each with the format
`TAG:LEVEL`, where `TAG` must be the *exact* tags you want to filter, and
`LEVEL` can be one of the characters listed in the document. So if you have a
bunch of similar tags, such as `MyApp-task1`, `MyApp-Task2`, etc., you'll have
to specify them all in full name. Although you can save a few key strokes by setting
the `ANDROID_LOG_TAGS` environment variable, it still only solves part of the
pain.

Note that the order of the filters matters. In short, `logcat` will look at the
filters from left to right, and use the first one that matches the tag of
log line. For example, if you use `MyApp:V *:S`, then only the log lines with
tag `MyApp` will be printed, other log lines will be suppressed by the `*:S`
filter. However, if you use `*:S MyApp:V`, then no log lines will be printed,
because the first filter, `*:S` matches all log line tags thus all log lines are
suppressed by this filter. For details, please refer to the
`android_log_shouldPrintLine` function in [this file][liblog].


## My Logcat Wrapper

We can make `logcat` support regular expression tag filters by two approaches.
One is modifying `logcat` source code in AOSP tree and build a new `logcat`
binary that support RE. Another approach is to filter the tags "offline" in the
host PCs where you run `adb logcat` command, i.e., a `logcat` wrapper.

I adopted the second approach, since the first one has a few drawbacks:

 - You'll have to match RE in cpp, which I assume is not quite enjoyable.
 - You'll have to cross-compile the `logcat` binary, which requires you to setup
   the whole AOSP develop environment.
 - For each device that you want to run `logcat` on, you'll have to replace the
   `logcat` binary.

So here is my wrapper works. It calls `adb logcat` command without any filters,
to get all the log lines. Then it parses the output log lines, and only prints
the lines whose tag matches the regular expression provided. It supports basic
`logcat` options, such as `-b`, `-c`, `-g`, etc. by just piping those options to
the real `logcat`. It processes the log filters in the same order as `logcat`
does to be as close as the original `logcat` semantics.

The idea is that you just run the wrapper in the save way you would as `logcat`,
and it just does the magic RE tag filtering for you. You can find this tool on
[my github repo][github].


## View Logs

You can directly print those log lines to console. I personally prefer to
redirect them to a temporary file and use vim to view it, which give me features
like incremental highlight search, etc. There is a [sweet recipe][vim] which
tells vim to automatically refresh the buffer when it's modified outside. This
is a perfect fit in viewing log files.



[logcat]: http://developer.android.com/tools/help/logcat.html
[filter]: http://developer.android.com/tools/debugging/debugging-log.html#filteringOutput
[liblog]: https://android.googlesource.com/platform/system/core/+/master/liblog/logprint.c
[vim]: http://vim.wikia.com/wiki/Have_Vim_check_automatically_if_the_file_has_changed_externally
[github]: https://github.com/jhshi/tools.logcat
