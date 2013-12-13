---
layout: post
title: "How to Apply Downloaded OTA Package"
date: 2013-12-13 12:24
comments: true
categories: ["Android"]
tags: ["DownloadManager", "RecoverySystem", "FileChannel"]
---

Suppose you've 
[downloaded the OTA package using Android's `DownloadManager`][post], this post
discusses how to verify it, and how to apply it at client's side.

<!--more-->

### Copy the Package to Internal Storage

By default, `DownloadManager` will save the downloaded file in external storage,
say, `/sdcard`. To make sure that this package is still accessible after the
phone reboots into recovery, we need to copy the package into internal storage.
In this case, we will use the `/cache` partition.

```java
File packageFile = new File(Environment.getDownloadCacheDirectory() + "/update.zip");
if (packageFile.exists()) {
    packageFile.delete();
}

FileChannel source = null;
FileChannel dest = null;

try {
    source = (new FileInputStream(downloadedFile)).getChannel();
    dest = (new FileOutputStream(packageFile)).getChannel();

    long count = 0;
    long size = source.size();

    do {
        count += dest.transferFrom(source, count, size-count);
    } while (count < size);
}
catch (Exception e) {
    Log.e(TAG, "Failed to copy update file into internal storage: " + e);
    return false;
}
finally {
    try {
        source.close();
        dest.close();
    }
    catch (Exception e) {
        Log.e(TAG, "Failed to close file channels: " + e);
    }
}
```

Here we use `FileChannel` from `java.nio` instead of the native
`FileOutputStream`, for some performance boost. You can find more discussions
about `java.nio` vs. `java.io` in this [stackoverflow thread][so].


### Verify the Signature

For security concern, we need to verify that the downloaded OTA package was
signed properly with the platform key. You can refer to [this post][sign] on how
to sign the OTA package.

We can use the `verifyPackage` call provided by [`RecoverySystem` class][recovery].

```java
try {
    File packageFile = new File(new URI(otaPackageUriString));
    RecoverySystem.verifyPackage(packageFile, null, null);
    // Log.v(TAG, "Successfuly verified ota package.");
    return true;
}
catch (Exception e) {
    Log.e(TAG, "Corrupted package: " + e);
    return false;
}
```

This will verify the package against the platform key stored in
`/system/etc/security/otacerts.zip`. You can also provide your own certs file,
of course. But in this case, the default platform key will do.

### Reboot into Recovery and Apply the Package

OK, now we're pretty confident that the downloaded package is in sanity. Let's
reboot the phone into recovery and apply it. This is done by the
`installPackage` call.

```java
try {
    File packageFile = new File(new URI(otaPackageUriString));
    RecoverySystem.installPackage(context, packageFile);
}
catch (Exception e) {
    Log.e(TAG, "Error while install OTA package: " + e);
    Log.e(TAG, "Will retry download");
    startDownload();
}
```

If everything is OK, the `installPackage` call won't return, and the phone will
be rebooted into recovery.

[so]: http://stackoverflow.com/questions/1605332/java-nio-filechannel-versus-fileoutputstream-performance-usefulness
[post]: /2013/12/02/how-to-use-downloadmanager/
[sign]: /2013/12/02/how-to-create-and-sign-ota-package/
[recovery]: http://developer.android.com/reference/android/os/RecoverySystem.html
