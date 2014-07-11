---
layout: post
title: "Stop Android Logcat from Truncating Log Line"
date: 2014-06-30 18:17:29 -0400
comments: true
categories: ['android']
tags: ['logcat', 'truncate']
---

When analyzing the logcat data from Android devices, I found that sometimes the
log line get truncated, especially when it's quite long. This causes trouble
because the logged information are in JSON format, which gets broken after (even
one character) truncated. In this post, I'll explain how did the truncation
happen, and how to fix it.

<!--more-->

### Android Logging 

[This page][log] gives an detailed explanation of Android logging system. In
short, three parts are working together to make Android logcat work.

 - `logger` device driver in kernel (`kernel/drivers/stagging/android`). Which serves read/write request from user
   space and also buffer the log content.
 - `android.util.Log` class (`framework/base/core/java/android/util/Log.java`), a Java wrapper to write to `logger` device.
 - `logcat` (`system/core/log`), a native tool to read logs from `logger` device.


### Truncating

Let's follow the flow when `Log.v` is called with a log message, and find out
who truncated the log message (if it's too long).

In `framework/base/core/java/android/util/Log.java`, when `Log.v` is called, it
just call the native method called `println_native` with to extra arguments,
`LOG_ID_MAIN` and `VERBOSE`. The first specify the log device to write to, and
the second tells the log level.

In `println_native`, defined in `framework/base/core/jni/android_util_Log.cpp`,
it just calls the function named `__android_log_buf_write`. So far, nobody
changed the log message yet.

`__android_log_buf_write` is defined in `system/core/liblog/logd_write.c`, it
first detect a few special tags to redirect them to `radio` log device, and then
it packs the log message in to `struct iovec` data structures and passes them on
to `write_to_log`, which is initialized as `_write_to_log_kernel`. Eventually,
these `iovec` go to `writev` in `system/core/liblog/uio.c`, which call syscall
`write` on the log device.

Thus, log line content is still sane before entering kernel space.

Next, the write request will be directed to `logger_aio_write` function defined
in `kernel/drivers/staging/android/logger.c`. One line (462) raised my
attention:

```c
header.len = min_t(size_t, iocb->ki_left, LOGGER_ENTRY_MAX_PAYLOAD);
```

This is where the truncating happens! 

### How to Fix

`LOGGER_ENTRY_MAX_PAYLOAD` is defined in
`kernel/drivers/stagging/android/logger.h` as `4076`, which I guess is
(4096-20), where 20 is the log header structure size.

We can not actually eliminate truncating completely, the buffer size is limited
after all. But we can enlarge the payload limit a bit to prevent some
unnecessary truncating. I changed it to 65516 (65536-20), which should be large
enough.

Also, `logger` device maintains a ring buffer for each log device, which are
defined in `kernel/drivers/stagging/android/logger.c`. The default buffer size
is 256K. I changed the buffer size for `main` device to 4MB, while leave
others unchanged. (I also tried 32MB, yet apparently it's far too large and the
kernel refused to boot up.)

## UPDATE

To make Android logcat tool working properly, we'll also need to modify
`system/core/include/log/logger.h` in AOSP source tree, which is a mirror to the
`logger.h` in kernel. `LOGGER_ENTRY_MAX_PAYLOAD` needs to be the same with the
one in kernel, and `LOGGER_ENTRY_MAX_LEN` needs to be a bit larger than
`LOGGER_ENTRY_MAX_PAYLOAD`. In my case, I set the former to 65516 and latter to
`(64*1024)`.


[log]: http://elinux.org/Android_Logging_System
