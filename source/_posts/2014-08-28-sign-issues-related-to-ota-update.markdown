---
layout: post
title: "Sign Issues related to OTA Update"
date: 2014-08-28 15:37:50 -0400
comments: true
categories: ['android']
tags: ['aosp', 'ota', 'sign', 'keys']
---

In my previous posts, I explained 
[how to create a properly signed OTA package][post1] that will pass recovery's
signature check,
and [how to verify the signed OTA package before apply it][post2]. Here, we'll
discuss, _when building an production AOSP platform_, how to sign the platform and
recovery image properly to match those signature checks.

<!--more-->

In following discussions, we assume you have a key pairs: `platform.x509.pem`
and `platform.pk`, which you'll use to sign the OTA package. Suppose the keys
are stored in a directory with path `$KEYS`. I'm using Nexus 5 (hammerhead) as
an example below but the practice should be easy to apply to other devices.

### Platform OTA Certificates

When verify a OTA package's signature using Android's
`RecoverySystem.verifyPackage` utility, that function actually checks against the
certificates stored in `/system/etc/security/otacerts.zip`. So if you want to
push OTA updates later, you'll have to generate the proper certificates when building
the platform.

You can accomplish this by specifying `PRODUCT_OTA_PUBLIC_KEYS` in your device's
Makefile (`device/lge/hammerhead/full_hammerhead.mk` in my case).


```
PRODUCT_OTA_PUBLIC_KEYS := $KEYS
```

Then the building process will store this location in `META/otakeys.txt` in
unsigned zip file. When you sign the target files using `sign_target_files_apks`
tool, it will generate the proper ota certificates based on the otakeys
provided. If `PRODUCT_OTA_PUBLIC_KEYS` is not defined, it will just use the
release key, which is probably not what you used to sign the OTA packages.

### Recovery Signature Verification

When you programmingly apply a OTA package using `RecoverySystem.installPackage`
function, it will boot the device into recovery mode and let the recovery do the
update. The recovery will first check the signature of the OTA package. So when
building the platform, you'll also need to specify the extra recovery keys by
defining `PRODUCT_EXTRA_RECOVERY_KEYS`.

```
PRODUCT_EXTRA_RECOVERY_KEYS := $KEYS
```

After setting `PRODUCT_OTA_PUBLIC_KEYS` and `PRODUCT_EXTRA_RECOVERY_KEYS`, you
should be able to pass all signature verifications and successfully apply the
OTA update.


[post1]: http://jhshi.me/2013/12/02/how-to-create-and-sign-ota-package/
[post2]: http://jhshi.me/2013/12/13/how-to-apply-downloaded-ota-package/
