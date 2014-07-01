---
layout: post
title: "Build Busybox with AOSP in Tree"
date: 2014-07-01 15:23:54 -0400
comments: true
categories: ['android']
tags: ['busybox', 'aosp']
---

This is how I integrated [busybox][busybox] source code into AOSP tree and so it gets built
together with whole platform. The steps are based on android-4.4.4_r1 for Nexus
5 (hammerhead).

<!--more-->

First clone the source from CyanogenMod git repo:

```bash
git clone https://github.com/CyanogenMod/android_external_busybox external/busybox
```

Next, you have to decide which version you need. I choose
`origin/stable/cm-10.2` because I found the latest branch `cm-11.0` has some
problems with other libraries (`libselinux` and `libsepol`), which I don't know
how to fix. However, since `cm-10.2` is based on Android 4.3 (JellyBean), we need to
make a tiny modifications to the code to make it work with Android 4.4.

```diff
diff --git a/android/reboot.c b/android/reboot.c
index f8546de..129957d 100644
--- a/android/reboot.c
+++ b/android/reboot.c
@@ -39,9 +39,11 @@ int reboot_main(int argc, char *argv[])
         exit(EXIT_FAILURE);
     }

+#if 0
     if(nosync)
         /* also set NO_REMOUNT_RO as remount ro includes an implicit sync */
         flags = ANDROID_RB_FLAG_NO_SYNC | ANDROID_RB_FLAG_NO_REMOUNT_RO;
+#endif

     if(poweroff)
         ret = android_reboot(ANDROID_RB_POWEROFF, flags, 0);
```

In short, `ANDROID_RB_FLAG_NO_SYNC` is no longer defined, as per this
[github:commit][commit].

Then just go through the usual AOSP build flow:

```bash
. build/envsetup.sh
lunch # your target
make clobber
make -j 16
```

Note that `make clobber` is needed before building.


[busybox]: https://github.com/CyanogenMod/android_external_busybox
[commit]: https://github.com/CyanogenMod/android_external_busybox/commit/25e89dcd9b30e6559c07a9359d85ec531ebe27e7

