---
layout: post
title: "Build Kernel In Tree with AOSP for Nexus 5 Hammerhead"
date: 2014-06-30 17:22:29 -0400
comments: true
categories: ['android']
tags: ['kernel', 'hammerhead', 'aosp']
---

Google has a fair document for [building kernel for Android][google]. Yet it
didn't cover how to integrate the kernel with AOSP source tree so that kernel
gets built along with whole platform, which I'll explain in this post. Here I'll
mainly focus on `android-4.4.4_r1` (Kitkat) for Nexus 5 (`hammerhead`).
The instructions should be easy to adapt to other models or AOSP releases.

<!--more-->


### Determine Kernel Version

The best and safest way to determine the right kernel version you need is to
examine the pre-included kernel image. For hammerhead, it's in
`device/lge/hammerhead-kernel/`.


```bash
$ bzgrep -a 'Linux version' device/lge/hammerhead-kernel/vmlinux.bz2
Linux version 3.4.0-gd59db4e (android-build@vpbs1.mtv.corp.google.com) (gcc version 4.7 (GCC) ) #1 SMP PREEMPT Mon Mar 17 15:16:36 PDT 2014
```

As per [this stackoverflow thread][so], the commit hash you want is `d59db4e`
part from the version name, without leading `g`.

### Download the Sources

For hammerhead, the kernel sources lie in `msm` tree. After cloning it into
`kernel` directory, checkout the commit hash you found in above step.

```bash
$ git clone https://android.googlesource.com/kernel/msm.git kernel
$ cd kernel
$ git checkout d59db4e
```

### Adapt kernel/AndroidKernel.mk

Two changes need to be made for kernel to be successfully built in-tree.

 - Use `zImage-dtb` instead of `zImage` as target. 

 First, change `TARGET_PREBUILT_INT_KERNEL` (~line 8).
```diff
-TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/arm/boot/zImage
+TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/arm/boot/zImage-dtb
```
   Then change corresponding make rule (~line 47).
```diff
$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi-
+       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- zImage-dtb
```
 - Do not build modules (~line 48-51).
```diff
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- modules
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) INSTALL_MOD_STRIP=1 ARCH=arm CROSS_COMPILE=arm-eabi- modules_install
-       $(mv-modules)
-       $(clean-module-folder)
```

### Adapt device/lge/hammerhead Project

Next we need to tell the device to build kernel, instead of copying the
pre-built one. [This patch][patch] should do the trick. Basically, a new
`AndroidBoard.mk` file is added to include the rules to build and copy kernel.
And some lines in `device.mk` related to kernel are removed, since it's already
taken care of in `AndroidBoard.mk`.


### Build It!

After all above changes, __do a `make clobber` to make sure we have a clean
slate__, otherwise, some strange errors may strike you.  Then just build AOSP in
normal way and kernel should get built on the fly.

Here is a snapshot of the kernel version I built. The version name is no longer
`d59db4e` because I made some changes.

{% img center /images/kernel.png 540 960 %}


### Credits

Thanks to [this blog from Jameson][jam] for describing most of it.

## UPDATE

The above setup works fine as long as you didn't
[specify a separate output directory][out], since we assume the kernel output
directory is `../$(KERNEL_OUT)` in `make` options. Apparently, it will fail if the
`out` directory is not the default one.

The kernel [Makefile][makefile] support two ways of specify output directory
(see comments starting from line 79). One is to use `O=` command line option,
another is to set the `KBUILD_OUTPUT` environment variable.

Since we use `-C` option to first switch working directory, `O=` options is a
bit tricky to use, so we leverage the `KBUILD_OUT` variable.

We first figure out the absolute path of the `KERNEL_OUT`

```makefile
FULL_KERNEL_OUT := $(shell readlink -e $(KERNEL_OUT))
```

Then we set `KBUILD_OUT` before calling `make`:

```makefile
$(KERNEL_CONFIG): $(KERNEL_OUT)
    env KBUILD_OUTPUT=$(FULL_KERNEL_OUT) \
    $(MAKE) -C kernel ARCH=arm CROSS_COMPILE=arm-eabi- $(KERNEL_DEFCONFIG)
```

This way will work no matter where the actual AOSP output directory is.


[google]: https://source.android.com/source/building-kernels.html
[so]: http://stackoverflow.com/questions/21574066/unable-to-checkout-msm-source-code-for-android-hammerhead-kernel
[patch]: https://github.com/jamesonwilliams/device_lge_hammerhead/commit/fe714801e33b38af4a81ddc3f40c3fdc53583f66
[jam]: http://nosemaj.org/howto-build-android-kitkat-nexus-5
[out]: https://source.android.com/source/initializing.html#using-a-separate-output-directory
[makefile]: https://android.googlesource.com/kernel/msm/+/android-msm-hammerhead-3.4-kitkat-mr1/Makefile
