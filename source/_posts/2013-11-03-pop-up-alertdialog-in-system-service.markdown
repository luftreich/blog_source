---
layout: post
title: "Pop Up AlertDialog in System Service"
date: 2013-11-03 23:28
comments: true
categories: ["Android"]
tags: ["AlertDialog", "service"]
---

I've been working on OTA support for [PhoneLab testbed][phonelab]. And one
problem I encountered is that, when I tried to pop out an
[AlertDialog][alertdialog] to let user confirm update, I get this error that
saied something like this:

```
android.view.WindowManager$BadTokenException: Unable to add window -- token null
is not for an application
```

<!-- more -->

Apparently, the `context` I used to create the dialog, which is the service
context,  is not valid in the sense
that it has not windows attached. Yet create an `Activity` just to pop out a
alert dialog is a bit of overdone, since my app is basically a background
service.

Here is how I solved this problem.

 - Add `android.permission.SYSTEM_ALERT_WINDOW` permission to `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

 - After creating the dialog, before show it, set its window type to system
   alert.

```java
// builder set up code here
// ...

AlertDialog dialog = builder.build();
dialog.getWindow().setType(WindowManager.LayoutParams.TYPE_SYSTEM_ALERT);
dialog.show();
```

Ref: [stackoverflow thread][so], [another similar post][post]

[phonelab]: www.phone-lab.org
[alertdialog]: http://developer.android.com/reference/android/app/AlertDialog.html
[so]: http://stackoverflow.com/questions/4344523/popup-window-in-any-app
[post]: http://tofu0913.blogspot.com/2013/07/popup-alertdialog-in-android-service.html

