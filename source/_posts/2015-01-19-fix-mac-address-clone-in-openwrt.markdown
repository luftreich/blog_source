---
layout: post
title: "Fix MAC Address Clone in OpenWRT"
date: 2015-01-19 17:09:44 -0500
comments: true
categories: ['linux']
tags: ['macaddr', 'openwrt', 'hwaddr', 'clone', 'overriding']
---

I used to be able to change the MAC address of WAN interface by specifying
`macaddr` option in `/etc/config/network`. However, due to [unknown reason][ticket],
this no longer works in snapshot builds. Here is how to achieve the same effect
using init scripts.

<!--more-->

In my router (TP-LINK WDR3500), `eth1` is the WAN interface. Adjust this
according to you case.

First, verify that you can change WAN interface's MAC address using `ifconfig`.

```bash
root@OpenWrt:~# ifconfig eth1 down
root@OpenWrt:~# ifconfig eth1 hw ether XX:XX:XX:XX:XX:XX
root@OpenWrt:~# ifconfig eth1 up
root@OpenWrt:~# ifconfig eth1
```

Substitute `XX:XX:XX:XX:XX:XX` with the MAC address you want to clone, and check
the output of the last command to make sure the new MAC address is used.

Next we want to automatically override the MAC address when system boots up. We
can use the init scripts. Edit `/etc/init.d/clonemac` and put the following content in it.


```bash
#!/bin/sh /etc/rc.common
# Copyright (C) 2014 OpenWrt.org

START=94
STOP=15

start() {
	ifconfig eth1 down
	ifconfig eth1 hw ether XX:XX:XX:XX:XX:XX
	ifconfig eth1 up
}

stop() {
	echo "Stop."
}
```

For details of OpenWrt init script, please check the [document][doc].

Make the script executable, then we can change the MAC address simply by this:

```bash
root@OpenWrt:~# /etc/init.d/clonemac start
```

To execute the script automatically on system boot, we need to enable it:

```bash
root@OpenWrt:~# /etc/init.d/clonemac enable
```

This will create a symbolic link to the `clonemac` script in `/etc/rc.d`.

Reboot the router and you will find the new MAC address be automatically used.



[ticket]: https://dev.openwrt.org/ticket/18488
[doc]: http://wiki.openwrt.org/doc/techref/initscripts
