---
layout: post
title: "Fix Data Connection for Nexus 5 Hammerhead on Android 4.4.4 Kitkat"
date: 2014-06-27 16:57:15 -0400
comments: true
categories: ['android']
tags: ['aosp', 'hammerhead', 'sprint', 'data', 'apn']
---

Recently, I need to build a working ROM for Nexus 5 from LG (hammerhead,
here-forth). There are variety of tutorials and guide all over the web on the
general steps needed to compile AOSP from scratch, which I do not intend to
repeat here. Instead, I'll mostly focus on how to make the data connection
(3G/LTE) working on Sprint phones.

<!--more-->

I choose the latest AOSP release as of writing this post, `android-4.4.4_r1` as
per the [official Android build numbers page][build], and followed the 
[official build instructions from Android][instr]. Everything went smoothly, except that
after flashing to device, I found there was no data connection (3G/LTE). Of
course Google apps were also missing but it should be easy to fix.

After banging my head for a while, I came across [this post from Jameson][jam],
which shed some light on what's happening. Apparently, the vendor binaries from
[Google's driver page][driver] do not work properly out of the box. Some was
missing, such as `OmaDmclient.apk`, and others were different from those in
factory image. So based on Jameson's vendor binary repos ([lge][lge],
[qcom][qcom]), I updated them with the binaries from [factory image][factory] of
Android 4.4.4 (KTU84P). Yet still no luck.

Finally, one of the comments in that post led me to this [xda thread][xda]
talking about APN fixes for Sprint users, which seems to be just I missed. So I
used the `apns-conf.xml` file from there and va-la, LTE is working! One tiny
glitch though, on first boot, activating data connection took far longer than it
should be, so once you saw the LTE icon, it's safe to hit skip.

I've put the complete vendor binaries as well as gapps and `apns-conf.xml` in
this [git repo][repo].

{% img center /images/data-activate.png %}
{% img center /images/about-phone.png %}


[build]: https://source.android.com/source/build-numbers.html
[instr]: https://source.android.com/source/building.html
[jam]: http://nosemaj.org/howto-build-android-kitkat-nexus-5
[driver]: https://developers.google.com/android/nexus/drivers#hammerheadktu84p
[factory]: https://developers.google.com/android/nexus/images#hammerheadktu84p
[lge]: https://github.com/jamesonwilliams/vendor_lge_hammerhead
[qcom]: https://github.com/jamesonwilliams/vendor_qcom_hammerhead
[xda]: http://forum.xda-developers.com/google-nexus-5/general/fix-sprint-data-to-custom-roms-t2541924
[repo]: https://github.com/jhshi/aosp.hammerhead.4.4.4_r1.vendor
