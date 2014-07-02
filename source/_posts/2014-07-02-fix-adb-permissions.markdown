---
layout: post
title: "Fix ADB Permissions"
date: 2014-07-02 14:17:47 -0400
comments: true
categories: ['android']
tags: ['adb', 'permission', 'udev']
---

I've been bothered by this message for a while when the device is in recovery
mode.

```bash
$ adb devices
List of devices attached
????????????    no permissions
```

<!--more-->

The thing is, I've set up my udev rules according to 
[official AOSP building guide][guide], and it works fine in normal mode. Yet the
above message shows up when the device is put in recovery mode. There are some
solutions online saying that restarting ADB as root, which I don't think is a
very good idea.

Then I figured if it has to do with my udev rules, maybe it didn't contain the
device I used (Nexus 5 from LG). A `lsusb` with device in recovery mode gives me this:

```bash
$ lsusb
Bus 002 Device 010: ID 18d1:d001 Google Inc.
```

The first part of the ID (18d1) is supposed to be the vendor ID, and second part
(d001) is product ID. However, from [Google's vendor list][vendor], LG's vendor
ID should be 1004, where as Google's vendor ID is 18d1.


What the hell, just add them to the udev rules:

```
# adb protocol on recovery for Nexus 5
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="d001", MODE="0600", OWNER="<YOUR_USER_NAME>"
```
After that, unplug the device and plug it in again. It should be
recognized, like so:

```base
$ adb devices
List of devices attached
060fb526f0eca244        recovery
```

And this approach can be extended to any cases where either adb or fastboot has
permission issues. Just do a `lsusb` and find out the actual vendor and product
ID, and add them to your udev rules.

[guide]: https://source.android.com/source/initializing.html#configuring-usb-access
[vendor]: http://developer.android.com/tools/device.html#VendorIds
