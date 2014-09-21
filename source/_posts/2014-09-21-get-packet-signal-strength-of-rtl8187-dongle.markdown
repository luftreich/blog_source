---
layout: post
title: "Get Packet Signal Strength of RTL8187 Dongle"
date: 2014-09-21 15:35:39 -0400
comments: true
categories: ['android']
tags: ['rtl8187', 'rssi', 'pcapcapture', 'kismet']
---

In one of my research projects, I used [Android PCAP Capture][pcap] with
[ALFA RTL8187L][rtl8187] dongles to capture Wi-Fi packets on Android phones. One
problem I encountered was that per packet RSSI is missing. After poking around
the source code for couple of days, I finally figured out how to get this
information. In short, the per packet RSSI information IS indeed reported by the
hardware, yet the current Android PCAP app doesn't collect it.

<!--more-->

### RTL8187 Rx Descriptor

Normally, the Wi-Fi chipset will report certain PHY layer information (RSSI,
AGC, etc.) along with the true 802.11 packet in the form of a vendor "header".
In the case of RTL8187L, it's a bit confusing because the "header" is actually
at the _end_ of the delivered packet. This is the detailed format of RTL8187 Rx
descriptor (p.25 of the [datasheet][datasheet]).

{% img /images/rtl8187_rx_desc.png %}

The most interesting part related to signal strength is AGC and RSSI. They all,
in a way, reflect the signal quality of the received packet. However, as per
the [Linux kernel rtl8187 driver][driver], "none of these quantities show
qualitative agreement with AP signal strength, except for the AGC". We'll worry
about this later. For now, we focus on how to extract these values from the
packet.

### Get the Values

In PCAP capture source code ([RTL8187Card.java][code]), there is a `usbThread`
which keep pulling data from the dongle. When got a packet, the last 16 or 20
bytes are trimmed depending on if it's RTL8187L or RTL8187B. That 16 or 20 bytes
are the Rx descriptor. So instead of truncating them, we'll save them in a
separate array.

```diff
diff --git a/src/net/kismetwireless/android/pcapcapture/Rtl8187Card.java b/src/net/kismetwireless/android/pcapcapture/Rtl8187Card.java
index b8e1a44..7628446 100644
--- a/src/net/kismetwireless/android/pcapcapture/Rtl8187Card.java
+++ b/src/net/kismetwireless/android/pcapcapture/Rtl8187Card.java
@@ -1868,13 +1868,16 @@ public class Rtl8187Card extends UsbSource {
                // int sz = mBulkEndpoint.getMaxPacketSize();
                int sz = 2500;
                        byte[] buffer = new byte[sz];
+            byte[] header;

                        while (!stopped) {
                                int l = mConnection.bulkTransfer(mBulkEndpoint, buffer, sz, 1000);
                                int fcsofft = 0;
+                header = null;

                                if (l > 0) {
                                        if (is_rtl8187b == 0 && l > 16)
+                        header = Arrays.copyOfRange(buffer, l-16, l);
                                                l = l - 16;
                                        else if (l > 20)
                                                l = l - 20;
@@ -1889,6 +1892,11 @@ public class Rtl8187Card extends UsbSource {
                                        if (mPacketHandler != null) {
                                                Packet p = new Packet(Arrays.copyOfRange(buffer, 0, l));
                                                p.setDlt(PcapLogger.DLT_IEEE80211);
+                        if (header != null) {
+                            int noise = header[4];
+                            int rssi = header[5] & 0x7f;
+                            int agc = header[6];
+                        }

                                                /*
                                                if (fcs)
```

Here, we save the RTL8187L header in a separate byte array, and get the relevant
fields from it.

### Meaningful RSSI

Although the Linux kernel driver shed some light on how to get a meaningful RSSI
out of the RTL8187L header, in my experiment, I found that `RSSI-100` is a fair
enough approximation of the real RSSI in `dBm`. For example, if the RSSI field
value is 15, then the actual RSSI is 15-100=-75dBm. Sometimes this approach will
give you some strange RSSI values (e.g., positive), yet most of the time the
calculated values are quite meaningful, and the RSSI of beacon frames calculated
this way are consistent with what you'll get from Android scan results.

[pcap]: https://www.kismetwireless.net/android-pcap/
[code]: http://kismetwireless.net/gitweb/?p=android-pcap.git;a=blob;f=src/net/kismetwireless/android/pcapcapture/Rtl8187Card.java;h=b8e1a44bb3a32376876ae1ff169634d1355ad568;hb=HEAD
[datasheet]: http://www.pc817.cn/File/DataSheet/RTL8187L-101213110313eae9fcbc-018b-4c1c-8b66-2e80392311df.pdf
[rtl8187]: http://www.amazon.com/Alfa-Network-Wireless-802-11g-AWUS036H/dp/B000WXSO76
[driver]: https://github.com/torvalds/linux/blob/master/drivers/net/wireless/rtl818x/rtl8187/dev.c
