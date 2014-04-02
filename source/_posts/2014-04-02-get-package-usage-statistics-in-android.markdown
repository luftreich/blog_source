---
layout: post
title: "Get Package Usage Statistics in Android"
date: 2014-04-02 13:00
comments: true
categories: ["Android"]
tags: ["dumpsys", "usagestats"]
---

In developing PhoneLab Conductor, I need to get various statistics about a
installed package to determine if a app is actively used by participant. For
example, for interactive apps, I'd like to know how many times the user launches
the app, and how long user actively interact with the app. For background apps
(e.g., data collection), I'd like to know how long the background service has
been running.

<!--more-->
There is this [dumpsys][dumpsys] tool in Android which will provide various
information about the status of the system, including package statistics.

Here is the sample output.

```bash
root@android:/ # dumpsys usagestats
Date: 20140402
  com.android.launcher: 2 times, 43748 ms
    com.android.launcher2.Launcher: 2 starts
  com.tencent.mm: 1 times, 167750 ms
    com.tencent.mm.ui.chatting.ChattingUI: 4 starts, 1000-1500ms=2, 4000-5000ms=1
    com.tencent.mm.ui.tools.ImageGalleryUI: 1 starts, 250-500ms=1
    com.tencent.mm.ui.LauncherUI: 4 starts, 2000-3000ms=1
    com.tencent.mm.ui.friend.FMessageConversationUI: 1 starts, 250-500ms=1
  com.android.settings: 2 times, 93065 ms
    com.android.settings.Settings: 2 starts
    com.android.settings.SubSettings: 2 starts, 250-500ms=1, 500-750ms=2
  com.google.android.gm: 1 times, 11396 ms
    com.google.android.gm.ConversationListActivityGmail: 1 starts, 500-750ms=1
```

At first glance, this is a perfect fit for my purpose. But there're two
problems.

 - This command needs to be run in shell. How can I get these information
   programatically using Java code? I definitely don't want to execute this
   shell command and then parse its output.
 - Only interactive apps' statistics are included. What about background apps
   which may don't have an activity?

### IUsageStats Service

After poking around Android Settings app's source code, I found there is one
internal interface called `IUsageStats`. It's defined in
`framework/base/core/java/com/android/internal/app/IUsageStats.aidl`

```java
package com.android.internal.app;

import android.content.ComponentName;
import com.android.internal.os.PkgUsageStats;

interface IUsageStats {
    void noteResumeComponent(in ComponentName componentName);
    void notePauseComponent(in ComponentName componentName);
    void noteLaunchTime(in ComponentName componentName, int millis);
    PkgUsageStats getPkgUsageStats(in ComponentName componentName);
    PkgUsageStats[] getAllPkgUsageStats();
}
```
Where `PkgUsageStats` class is defined in 
`framework/base/core/java/com/android/internal/os/PkgUsageStats.java`. 

```java
public class PkgUsageStats implements Parcelable {
    public String packageName;
    public int launchCount;
    public long usageTime;
    public Map<String, Long> componentResumeTimes;

    // other stuff...
}
 
```
It contains all the information I need about foreground apps!

Now is the problem of how to access the internal class and interface of Android.
There's plenty way to do this. Since I have aosp source tree at hand, I just
copy those two files into my project. For `PkgUsageStats`, I also need to copy
the aidl file
(`framework/base/core/java/com/android/internal/os/PkgUsageStats.aidl`).

Here is the final directory structure of my `src` folder.


```
src/
|-- com
|   `-- android
|       `-- internal
|           |-- app
|           |   `-- IUsageStats.aidl
|           `-- os
|               |-- PkgUsageStats.aidl
|               `-- PkgUsageStats.java
`-- other stuff
```

Here is the code snippet that get the `IUsageStats` service.

```java
private static final String SERVICE_MANAGER_CLASS = "android.os.ServiceManager";

try {
    Class serviceManager = Class.forName(SERVICE_MANAGER_CLASS);
    Method getService = serviceManager.getDeclaredMethod("getService", new Class[]{String.class});
    mUsageStatsService = IUsageStats.Stub.asInterface((IBinder)getService.invoke(null, "usagestats"));
}
catch (Exception e) {
    Log.e(TAG, "Failed to get service manager class: " + e);
    mUsageStatsService = null;
}
```

Here I use Java reflection to get the class of `android.os.ServiceManager`,
which is also internal interface.

### Background Service Running Time

It seems that Settings->Apps->Running Apps are already showing the information
that how long a process or service has been running.

{% img center /images/running.png %}

After inspecting the source code of Settings app, I found that information is
coming from `ActivityManager.RunningServiceInfo`. There is a field named
`activeSince`, which is the time when the service was first made active.


[dumpsys]: http://source.android.com/devices/tech/input/dumpsys.html
