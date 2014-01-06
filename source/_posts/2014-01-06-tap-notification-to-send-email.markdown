---
layout: post
title: "Tap Notification To Send Email"
date: 2014-01-06 13:14
comments: true
categories: ["Android"]
tags: ["notification", "email", "intent"]
---

In developing [PhoneLab Conductor][conductor] app, I need to provide user a way
to give us feedback after applying OTA update. Although this feature was
disabled in release, I thought it's worthwhile to record how to implement that
functionality anyway.

<!--more-->

### The Scenario

After the phone received and OTA update and rebooted to apply it, the conductor
app will pop up an notification, saying something like "You've updated your
platform, if there's any question, please tap to email for help.". So when user
tap the notification, a selection alert should pop up to let user select which
email client to use. Then open that email client with proper recipient, subject,
and email body (e.g., some extra debug information).


### The Overall Flow

When we post an notification using [Notification.Builder][nb], we can optionally
set an [PendingIntent][pi] about what action to take when user tap that
notification. This is done via the `setContentIntent` function. 

```java
builder.setContentIntent(reportProblemPendingIntent);
notificationManager.notify(PLATFORM_UPDATE_NOTIFICATION_ID, builder.build());
```

And that
`PendingIntent` will broadcast an custom intent so our `BoradcastReceiver` will
be called and handle that tap event.

```java
private String reportProblemIntentName = this.getClass().getName() + ".ReportProblem";
private IntentFilter reportProblemIntentFilter = new IntentFilter(reportProblemIntentName);
private PendingIntent reportProblemPendingIntent;
private BroadcastReceiver reportProblemReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
        // to be filled
    }
};

// in initilization function
reportProblemPendingIntent = PendingIntent.getBroadcast(context, 0, 
    new Intent(reportProblemIntentName), PendingIntent.FLAG_UPDATE_CURRENT);
context.registerReceiver(reportProblemReceiver, reportProblemIntentFilter);
```

### Launch Email App

Now when user tap the notification, the `onReceive` handler will be called.

First, we need to cancel the notification.

```java
NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
notificationManager.cancel(PLATFORM_UPDATE_NOTIFICATION_ID);
```

Then we prepare the intent for launch email app.

```java
Intent emailIntent = new Intent(Intent.ACTION_SENDTO);
emailIntent.setType("text/plain");
String messageBody =
    "========================\n" +
    "  Optional debug info   \n" +
    "========================\n" +
    "Please describe your problems here.\n\n";
String uriText = "mailto:" + Uri.encode(PHONELAB_HELP_EMAIL) + "?subject="
    + Uri.encode("OTA Update Problem") + "&body=" + Uri.encode(messageBody);
emailIntent.setData(Uri.parse(uriText));
```

Note that in order to actually launch the email chooser, we need another intent.

```java
Intent actualIntent = Intent.createChooser(emailIntent, "Send email to PhoneLab");
actualIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
context.startActivity(actualIntent);
```

[conductor]: https://play.google.com/store/apps/details?id=edu.buffalo.cse.phonelab.harness.participant&hl=en
[nb]: http://developer.android.com/reference/android/app/Notification.Builder.html
[pi]: http://developer.android.com/reference/android/app/PendingIntent.html
