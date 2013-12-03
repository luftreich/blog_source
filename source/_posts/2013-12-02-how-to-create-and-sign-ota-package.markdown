---
layout: post
title: "How to Create and Sign OTA Package"
date: 2013-12-02 15:07
comments: true
categories: ["Android"]
tags: ["ota", "signapk", "zip"]
---

I'm currently maintaining the [Conductor App][conductor] for [PhoneLab
testbed][phonelab]. One of the core tasks performed by conductor is to perform
system OTA update, so that we can push platform changes to our participants,
either to fix bugs, or to do system level experiments (libc, Dalvik VM, etc.).

So the first step is, how to create an OTA package?

<!--more-->

### Directory Structure

Suppose we have a patched version of `libc` and we want to overwrite the
previous one already in participants' phone, we need first to figure out where
that file is in the file system. In this case, it's `/system/lib/libc.so`. Then
our OTA package's directory structure must looks like this:

```bash
myupdate
|-- META-INF
|   `-- com
|       `-- google
|           `-- android
|               |-- update-binary
|               `-- updater-script
`-- system
    `-- lib
        `-- libc.so
```

The `update-binary` and `updater-script` are used to actually perform the 
update, I'll explain them later.

Note that the structure of the `system` needs to be exactly the same with what's
in Android's setup, so that we can copy that directory directly to target
system, and overwrite the files with the updated version.

### The updater-script

The `update-binary`, as its name indicates, is a binary file that will parse the
`updater-script` we write. It's quite standard and nothing special. You can obtain 
a copy of this file [here][binary].

The `updater-scipts` contains the operations we want to perform. Its written
using [Edify][edify] scripting language, which has quite simple and intuitive
syntax. You can find more details in this [xda thread][xda].

In this case, what we need to do is quite simple: mount the `/system` partition
and copy the files in the OTA package to target file system. So the
`updater-script` may looks like this:

```
mount("ext4", "EMMC", "/dev/block/platform/omap/omap_hsmmc.0/by-name/system", "/system");
package_extract_dir("system", "/system");                                        
unmount("/system");       
```

First, we mount the target file system's `system` partition using the `mount`
command, the arguments are:

 - `FSTYPE`: File system type. In this case, it's "ext4"
 - `TYPE`: Storage type. ["EMMC"][emmc] means internal solid state storage device on MMC
   bus, which is actually NAND flash.
 - `DEV`: The device to mount. 
 - `PATH`: Mount point.

You can find all the mounted devices in Android by `adb shell` then `mount`.
Here is one sample output:

```
shell@android:/ $ mount
rootfs / rootfs ro,relatime 0 0
tmpfs /dev tmpfs rw,nosuid,relatime,mode=755 0 0
devpts /dev/pts devpts rw,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,relatime 0 0
none /acct cgroup rw,relatime,cpuacct 0 0
tmpfs /mnt/secure tmpfs rw,relatime,mode=700 0 0
tmpfs /mnt/asec tmpfs rw,relatime,mode=755,gid=1000 0 0
tmpfs /mnt/obb tmpfs rw,relatime,mode=755,gid=1000 0 0
none /dev/cpuctl cgroup rw,relatime,cpu 0 0
/dev/block/platform/omap/omap_hsmmc.0/by-name/system /system ext4 ro,relatime,barrier=1,data=ordered 0 0
/dev/block/platform/omap/omap_hsmmc.0/by-name/efs /factory ext4 ro,relatime,barrier=1,data=ordered 0 0
/dev/block/platform/omap/omap_hsmmc.0/by-name/cache /cache ext4 rw,nosuid,nodev,noatime,errors=panic,barrier=1,nomblk_io_submit,data=ordered 0 0
/dev/block/platform/omap/omap_hsmmc.0/by-name/userdata /data ext4 rw,nosuid,nodev,noatime,errors=panic,barrier=1,nomblk_io_submit,data=ordered 0 0
/sys/kernel/debug /sys/kernel/debug debugfs rw,relatime 0 0
/dev/fuse /mnt/shell/emulated fuse rw,nosuid,nodev,relatime,user_id=1023,group_id=1023,default_permissions,allow_other 0 0
```

Then we do the actual copy using `package_extract_dir` command. This will copy 
the updated `libc.so` file.

And finally we unmount the `/system` partition.

### Pack It Up

_Inside `myupdate` directory_, use this command to create the zip file.

```bash
zip -r9 ../myupdate.zip *
```

Note that the command is executed _inside_ the `myupdate` directory, and the
zip file is created in parent directory. This is because the `META-INF` and
`system` directory must be in the root directory of the final zip file.

### Sign the OTA Package

Up to this point, the OTA package we just created should be able to applied
successfully on custom recoveries like CWM, in which the signature
verification is turned off by default.

However, to automate the OTA process, we're using the [Android
RecoverySystem][recovery] to reboot the phone and apply the update, in that
case, the signature verification is turned on. So we need to sign the package
with proper keys, which are _platform_ keys.

Suppose you've get the platform keys named `platform.x509.pem` and
`platform.pk8`, we can use the [signapk.jar][signapk] tool.

```bash
java -jar signapk.jar -w platform.x509.pem platform.pk8 myupdate.zip myupdate-signed.zip
```

Note that:

 - We need the `-w` flat to sign the whole zip file.
 - The sequence of the two key files: pem file goes first, then the pk8 file.

This will generate the final OTA package, `myupdate-signed.zip`, which WILL pass
the signature verification of the recovery system.


[conductor]: https://play.google.com/store/apps/details?id=edu.buffalo.cse.phonelab.harness.participant&hl=en
[phonelab]: http://www.phone-lab.org
[binary]: https://github.com/koush/AnyKernel/tree/master/META-INF/com/google/android
[edify]: http://wiki.cyanogenmod.org/w/Doc:_About_Edify
[xda]: http://forum.xda-developers.com/showthread.php?t=1187313
[emmc]: http://www.datalight.com/solutions/technologies/emmc/what-is-emmc
[signapk]: http://www.adbtoolkit.com/kitchen/tools/linux/signapk.jar
[recovery]: http://developer.android.com/reference/android/os/RecoverySystem.html
