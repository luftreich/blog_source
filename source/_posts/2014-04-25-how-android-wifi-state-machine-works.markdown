---
layout: post
title: "How Android Wifi State Machine Works"
date: 2014-04-25 10:39
comments: true
categories: ["research"]
tags: ["android", "wifi", "state machine", "wpa_supplicant"]
---

Recently, I studied how Android Wi-Fi subsystem works. I was more specifically
interested to learn the scan behavior. The source code related to this is mainly
in `framework/base/wifi/java/android/net/wifi/` within AOSP source tree.

<!--more-->

### The Big Picture

{% img center /images/android_wifi.png %}

Android uses a customized wpa_supplicant to perform AP authentication and
association, and also communicate with underlying driver. The `WifiNative` class
is used to send various commands to wpa_supplicant ,and the `WifiMonitor` class
is used to monitor wpa_supplicant status change and notify Android framework.

wpa_supplicant communicates with underlying driver using new
[CFG80211/NL80211][cfg80211] interface.

[cfg80211]: http://wireless.kernel.org/en/developers/Documentation/cfg80211

### Basics of Hierarchical State Machine

Android framework uses a Hierarchical State Machine (HSM) to maintain the
different states of Wi-Fi connection. As the name indicates, all states are
organized in a tree, and there is one special initial state. The interface of
each state is as follows:

 - `enter()`: called when entering this state.
 - `exit()`: called when exiting this state.
 - `processMessage()`: called when message arrives.

The most import property of HSM is that when transitioning between states, we
first found the common ancestor state that's closest to current state, the we
exit from current state and all its ancestor state __up to but not include__ the
closest common ancestor, then enter all of the new states below the closet
common ancestor down to the new state. 

Here is a simple example HSM. 

{% img center /images/hsm_example.png %}

`S4` is the initial state. When we first start the HSM, `S0.enter()`,
`S1.enter()` and `S4.enter()` will be called in sequence. Suppose we want to
transit from `S0` to `S7`, since the closet common ancestor is `S0`, `S4.exit()`
`S1.exit()`, `S2.enter()`, `S5.enter()` and `S7.enter()` will be called in
sequence.

More details about HSM can be found in the comments of
`frameworks/base/core/java/com/android/internal/util/StateMachin.java`.

### Wifi State Machine

Here is a subset of the whole Android Wifi HSM, states about P2P connections are
omitted.

{% img center /images/android_wifi_hsm.png %}

So in Initial state's `enter()` function, we check if the driver is loaded, and
transit to Driver Loaded state if yes. Then we start wpa_supplicant and transit


When we receive `SUP_CONNECTED_EVENT`, we switch to Driver Started state. __But
before that, we need to first enter Supplicant Started state first.__ In the
`enter()` function of Supplicant Started state, we set the supplicant scan
interval, which,  by default, is 15 seconds defined in
`frameworks/base/core/res/res/values/config.xml` as
`config_wifi_supplicant_scan_interval`. So the first fact of Android scan
behavior is that __it'll do scan every 15 seconds as long as the wpa_supplicant
is started, no matter what the Wi-Fi condition is.__

Then we come to Driver Started State, if we're not in scan mode, then we switch
to Disconnected Mode state. Scan mode means that Wi-Fi will be kept active, but
the only operation that will be supported is initiation of scans, and the
subsequent reporting of scan results. No attempts will be made to automatically
connect to remembered access points, nor will periodic scans be automatically
performed looking for remembered access points.

In Disconnected Mode state's `enter()` function, if the chipset does not support
background scan, then we enable framework periodic scan. The default interval is
300 seconds (5 mins), defined in `framworks/base/core/res/res/values/config.xml`
as `config_wifi_framework_scan_interval`. So the second behavior of Android scan
is that, __in disconnected mode, it'll issue scan every 5 mins.__

Then if received `NETWORK_CONNECTION_EVENT` event from `WifiMonitor`, we switch
to Obtaining IP state, which will initiate the DHCP process if needed. Then we
go through Veifying Link and Captive Portal Check state, and finally reach
Connected state.

`WifiWatchdogStateMachine` will continuously monitor the link quality and packet
loss event, and will send out `POOR_LINK_DETECTED` or `GOOD_LINK_DETECTED`
event.

### Android Scan Interval

Here is the statistics of scan interval distribution collected on 129 Nexus S phones for
about 5 months.

{% img center /images/scan_interval_stats.png %}

We can see that there are 4 peaks in the distribution. The peak around 15 seconds is
due to wpa_supplicant scan interval, and the peak around 300 is due to
framework periodic scan. The peak around 60 seconds is not much clear yet,
probably due to the scan interval when P2P is connected.

The interesting fact is actually the peak within 2 seconds. It seems most of the
scan results are clustered together in a small time windows (1~2 seconds).
This is because when the driver is scanning, it'll report every time it detects
one AP. So in one scan, multiple scan result event will be triggered. And
every time when there is a low level scan result event, Android will report the
complete updated scan result list.
