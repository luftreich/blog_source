---
layout: post
title: "Monitor Screen Touch Event in Android"
date: 2014-11-09 18:47:24 -0500
comments: true
categories: ['Android']
tag: ['touch']
---

In one of my projects I need to track every screen touch event in background.
That is, my app needs to be "invisible" while capturing every screen touch. Here
is how I achieved this.

<!--more-->

The idea is to define a dummy UI fragment that is really tiny (say, 1x1 pixel),
and place it on one of the corners of the screen, and let it listen on all touch
events outside it. Well, literally, it's not "invisible", in fact it's in
foreground all the time! But since it's so tiny so hopefully users won't feel a
difference.

First, let's create this dummy view:

```java
mWindowManager = (WindowManager) mContext.getSystemService(Context.WINDOW_SERVICE);
mDummyView = new LinearLayout(mContext);

LayoutParams params = new LayoutParams(1, LayoutParams.MATCH_PARENT);
mDummyView.setLayoutParams(params);
mDummyView.setOnTouchListener(this);
```

Here we set the width of the dummy view to be 1 pixel, and the height to be
parent height. And we also set up a touch event listen of this dummy view, which
we'll implement later.

Then let's add this dummy view.

```java
LayoutParams params = new LayoutParams(
        1, /* width */
        1, /* height */
        LayoutParams.TYPE_PHONE,
        LayoutParams.FLAG_NOT_FOCUSABLE | 
        LayoutParams.FLAG_NOT_TOUCH_MODAL |
        LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
        PixelFormat.TRANSPARENT
        );
params.gravity = Gravity.LEFT | Gravity.TOP;
mWindowManager.addView(mDummyView, params);
```

The key here is the `FLAG_WATCH_OUTSIDE_TOUCH` flag, it enables the dummy view
to capture all events on screen, whether or not the event is inside the dummy
view or not.

Finally, let's handle the touch event by implementing `View.OnTouchListener`
listener.

```java
@Override
public boolean onTouch(View v, MotionEvent event) {
    Log.d(TAG, "Touch event: " + event.toString());

    // log it

    return false;
}
```

We need to return `false` since we're not really handling the event, so that the
underlying real UI elements can get those events.


A final note is that, to keep our dummy view always listening touch events, we
need to wrap all these in an `Service`: we create the dummy view in `onCreate`
and add it to screen in `onStartCommand`. And the service should implement
`View.OnTouchListener` to receive the touch events.
