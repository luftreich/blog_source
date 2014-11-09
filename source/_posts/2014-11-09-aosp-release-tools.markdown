---
layout: post
title: "AOSP Release Tools"
date: 2014-11-09 14:42:39 -0500
comments: true
categories: ['Android']
tags: ['incremental', 'ota', 'aosp', 'release']
---

AOSP ships with a bunch of tools that are very useful for platform release. I'll
cover their usage and explain what they do in this post.

<!--more-->

## Generate Target Files

Usually when you develop locally, you would use plain `make` with no particular
target to compile AOSP. When you prepare for release, however, you need to do
this instead:

```bash
$ make -j16 dist
```

It will first compile the whole source tree, as a plain `make` does. Then it
will generate several zip files in `out/dist` that will be used in later stage
of release. Here are the files for Nexus 5 (hammerhead) of platform version 1.2,
the names may be slightly different in your case.

 - `aosp_hammerhead-target-files-1.2.zip` contains all the target files (apk,
     binaries, libraries, etc.) that will go into the final release package. This
     is the most important file and will be used extensively later on.
 - `aosp_hammerhead-apps-1.2.zip` contains all the apks.
 - `aosp_hammerhead-emulator-1.2.zip` contains images that suitable for boot on
     a emulator.
 - `aosp_hammerhead-img-1.2.zip` contains image files for `system`, `boot`, and
     `recovery`. Suitable for `fastboot update`.
 - `aosp_hammerhead-ota-1.2.zip` is an OTA package that can be installed
     through recovery.
 - `aosp_hammerhead-symbols-1.2.zip` contains all files in
     `out/target/product/hammerhead/symbols`.


## Sign Target Files

Each APK in the final release has to be properly signed. In each Java project that
will finally generate an APK, developers can specify which key should be used to
sign this apk by defining `LOCAL_CERTIFICATE`. For example, in `Android.mk` file
of `packages/apps/Settings`, there is this line:

```makefile
LOCAL_CERTIFICATE := platform
```

Which indicates that `Settings.apk` should be signed using platform key. You can
also set `LOCAL_CERTIFICATE` to be `PRESIGNED`, which tells the signing script
(see below) that this APKs are already signed and should not be signed again.
This is usually the case when those APKs are provided as vendor blobs.

There are four type of keys in AOSP, and the default keys are shipped in
`build/target/product/security`. As you'll find in the `README` file, they are:

 - testkey -- a generic key for packages that do not otherwise specify a key.
 - platform -- a test key for packages that are part of the core platform.
 - shared -- a test key for things that are shared in the home/contacts process.
 - media -- a test key for packages that are part of the media/download system.

Actually, after first step (`make dist`) the target APK files are signed with
this keys, which we should substitute to our own keys in this step. AOSP
provides a python script, `build/tools/releasetools/sign_target_file_apks`, for
this purpose.

You can take a look at the python doc at the head of that file for complete
usage. A typical usage will look like this:


```bash
$ ./build/tools/releasetools/sign_target_file_apks -o -d $KEY_DIR out/dist/aosp_hammerhead-target_files-1.2.zip /tmp/signed.zip
```

In which:

 - `-o` tells the script to replace ota keys. This will make
     `system/etc/security/otacerts.zip` in the final image contain your platform keys instead of
     the default one.
 - `-d` indicates that you're using default key mapping.
 - `$KEY_DIR` should be the directory that contains your private keys.

This script will first unpack the input target files, then sign each APKs using
proper keys, and repack them in to a new signed target files zip.

## Generate Release File

This step depends on what kind of release file you want to generate. You can
either generate a full image file that suitable for `fastboot update`, or you
can generate an OTA file that can be updated via recovery.

### Full System Image

```bash
$ ./build/tools/releasetoosl/img_from_target_files /tmp/signed.zip /tmp/final-release.img
```

This script will pack the signed target files into one image file that can be
flashed via `fastboot update`. This is useful when you do your first release.


### OTA Package

For OTA, you can choose from a full OTA or an incremental OTA. In
each case, you can reboot the device into recovery mode, and use `adb sideload`
to flash the update for testing.

To generate a full OTA package:

```bash
$ ./build/tools/releasetoosl/ota_from_target_files -k $KEY_DIR/platform /tmp/signed.zip /tmp/final-full-ota.zip
```

In which `-k` option specify the key to sign the OTA package. The package
contains all the files needed by `system`, `boot` and `recovery` partition.

### Incremental OTA

The OTA package generated in last step is quite large (~380MB for KitKat). If the changes
since last release are not that many, then you may want to generate an
incremental OTA package, which only contains the different part.

To do this, you need the signed target files from last time when you do a
release. Therefore, I strongly suggest you to check in the signed target files of each release
in your VCS, just in case in the future you want to do an incremental OTA.

```bash
$ ./build/tools/releasetoosl/ota_from_target_files -k $KEY_DIR/platform -i /tmp/last-signed.zip /tmp/signed.zip /tmp/final-full-ota.zip
```

The difference is that we specify the base target files, `/tmp/last-signed.zip`.
The script will compare current target files with the one from last release, and
will generate binary diff if they're different.

You may also check my previous post about
[how apply the OTA package programmingly][link].


[link]: /2013/12/13/how-to-apply-downloaded-ota-package/
