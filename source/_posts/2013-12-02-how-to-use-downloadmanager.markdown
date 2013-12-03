---
layout: post
title: "How to use Android DownloadManager"
date: 2013-12-02 20:42
comments: true
categories: ["Android"]
tags: ["DownloadManager"]
---

`DownloadManager` is a service provided by Android that can conduct long-running
HTTP downloading, typically for large files. So we won't worry about what if we
loss connection, what if the system reboots, etc.

<!--more-->

### Listen for Download Complete Event
Before we start downloading, make sure we already listen for the broadcast of
`Downloadmanager`, so that we won't miss anything.

```java
private String downloadCompleteIntentName = DownloadManager.ACTION_DOWNLOAD_COMPLETE;
private IntentFilter downloadCompleteIntentFilter = new IntentFilter(downloadCompleteIntentName);
private BroadcastReceiver downloadCompleteReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
        // TO BE FILLED
    }
}


// when initialize
context.registerReceiver(downloadCompleteReceiver, downloadCompleteIntentFilter);
```

### Request Download

We an get an instance of `DownloadManager` using this call.

```java
DownloadManager downloadManager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
```

`DownloadManager` has a subclass called `Request`, which we will use to request
for an download action. Here is the code snippet that initiate a download.

```java
String url = "http://example.com/large.zip
DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

// only download via WIFI
request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_WIFI);
request.setTitle("Example");
request.setDescription("Downloading a very large zip");

// we just want to download silently
request.setVisibleInDownloadsUi(false);
request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_HIDDEN);
request.setDestinationInExternalFilesDir(context, null, "large.zip");

// enqueue this request
DownloadManager downloadManager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
downloadID = downloadManager.enqueue(request);
```

Please refer to [the doc][doc] on more configurations of the request object. So
now we have an `downloadID`, which we'll use to query the state of downloading.

### Download Complete Handler

Now we already started downloading, in the above `downloadCompleteReceiver`,
what we need to do?

First, we need to check if it's for our download, since it's an broadcast event.

```java
long id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0L);
if (id != downloadID) {
    Log.v(TAG, "Ingnoring unrelated download " + id);
    return;
}
```

Then we need to query the state of downloading. This is done via the `Query`
subclass of `DownloadManager`.

```java
DownloadManager downloadManager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
DownloadManager.Query query = new DownloadManager.Query();
query.setFilterById(id);
Cursor cursor = downloadManager.query(query);

// it shouldn't be empty, but just in case
if (!cursor.moveToFirst()) {
    Log.e(TAG, "Empty row");
    return;
}
```

Then we can get the state and also the downloaded file information like this.

```java
int statusIndex = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS);
if (DownloadManager.STATUS_SUCCESSFUL != cursor.getInt(statusIndex)) {
    Log.w(TAG, "Download Failed");
    return;
}

int uriIndex = cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI);
String downloadedPackageUriString = cursor.getString(uriIndex);
```

So now we get the downloaded file's URI, we can than either copy it to somewhere
else, or go ahead and process it.

There are more information to query when the download failed, e.g., reason, how
much as been downloaded, etc. Please refer to the [documentation of
DownloadManager][dm] for complete list of column names.

[doc]: http://developer.android.com/reference/android/app/DownloadManager.Request.html
[dm]: http://developer.android.com/reference/android/app/DownloadManager.html
