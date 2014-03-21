---
layout: post
title: "Switch Channel Without Breaking TCP Connection in OpenWrt"
date: 2014-03-21 12:46
comments: true
categories: ['research']
tags: ['openwrt', 'channel', 'wifi', 'hostapd']
---

Recently, I've been working on dynamic channel selection based on channel
utilization. One problem I encountered is: how to switch both AP and devices'
channel without interrupting existing TCP connection.

<!--more-->

## First Intuitive Solution

I have a router ([TP-LINK TL-WDR3500][tplink]) running [OpenWrt][openwrt].
Wireless configurations, e.g., SSID, channel, tx power, are managed in Openwrt's
UCI system. More specifically, all Wifi configurations are stored in file
located in `/etc/config/wireless`. In my case, the file looks like this:

```
config wifi-device 'radio0'
	option type 'mac80211'
	option hwmode '11g'
	option path 'platform/ar934x_wmac'
	option htmode 'HT20'
	list ht_capab 'LDPC'
	list ht_capab 'SHORT-GI-20'
	list ht_capab 'SHORT-GI-40'
	list ht_capab 'TX-STBC'
	list ht_capab 'RX-STBC1'
	list ht_capab 'DSSS_CCK-40'
	option txpower '27'
	option channel '11'

config wifi-iface
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'PocketSniffer'
	option encryption 'psk2'
	option key 'XXXX'
```

OpenWrt provides a command called `wifi`, that can reload these configurations.
So my first solution is to `uci` command to change the configuration and use
`wifi` command to reload them.

```python
def set_channel(channel) :
  args = ['uci', 'set']

  if channel <= 11 :
    args.append('wireless.radio0.channel=' + str(channel))
  else :
    args.append('wireless.radio1.channel=' + str(channel))

  subprocess.call(args)
  subprocess.call(['uci', 'commit'])
  subprocess.call(['wifi'])
```

This will work in the sense that it can change the AP's channel. But the problem
is, the `wifi` command will actually shut down the interface completely and
restart it. So any devices that connected to this AP will be de-associated.

## What's the Problem?

From client's side of view, when the AP switches to another channel, here is
what happend:

 - Receive de-authentication frame from AP (ops, this AP is gone)
 - Do active scan on every channel (probe-wait)
 - Figure out a best AP to associate
 - Send authentication and association request to newly selected AP

This is much like a typical handover process where a device switches between two
geographically co-located APs. Just that in this case, the two APs are actually
the same physical AP with different channel.

[A. Mishra et al][paper] provides a thorough study on the handover process. In
short, the process can take up to a few hundred milliseconds, and any on-going
TCP connections will lost.

This is undesired because the channel switch cost (extra latency and breaking
TCP connection) may neutralize the benefit of switching channel itself.

Ideally, after channel switch, any authentication info at AP side should remain,
so that clients don't have to re-authenticate, and any established TCP
connection should also be kept. These requirements make sense because, after
all, channel is just medium to exchange data. Channel switch should NOT affect
any up layer state.

## The Final Solution

After a bit research, I found that IEEE 802.11 standard (section 10.9.8 in 2012
standard) actually already defined the
mechanism to let AP announce the channel switch event and also let clients
switch channel accordingly - all happened in MAC layer. This feature quite fits
our needs.

And the good new is that this feature has already been implemented in most
recent driver that adopting CFG80211 interface, and is exposed to user space
tools, such as hostapd or wpa_supplicant.

The OpenWrt running on our router use hostapd as user space authenticator. And
it provides a command line tool called `hostapd_cli` to interact with the
hostapd daemon. There is a command in `hostapd_cli` called `chan_swtich` that
does precisely what we wanted.

```python
def set_channel(channel) :

  # do not use the wifi command to switch channel, but still maintain the
  # channel coheraence of the configuration file

  args = ['uci', 'set']

  if channel <= 11 :
    args.append('wireless.radio0.channel=' + str(channel))
  else :
    args.append('wireless.radio1.channel=' + str(channel))

  subprocess.call(args)
  subprocess.call(['uci', 'commit'])

  # this is the command that actually switches channel

  with open(os.devnull, 'wb') as f :
    cmd = 'chan_switch 1 ' + str(channel2freq(channel)) + '\n'
    p = subprocess.Popen('hostapd_cli', stdin=subprocess.PIPE, stdout=f, stderr=f)
    p.stdin.write(cmd)
    time.sleep(3)
    p.kill()

```

Here we still update the configuration file to maintain consistence between it
and the hostapd daemon. But instead of using `wifi` command to reload the
configuration, we use the `chan_swtich` command to change the channel.

`chan_switch` takes a minimum of two arguments. The first is a `cs_count`,
meaning switch channel after how many beacon frames. The second is frequency.
More usage info can be obtained by typing `chan_switch` without any arguments in
`hostapd_cli`.


[tplink]: http://wiki.openwrt.org/toh/tp-link/tl-wdr3500
[openwrt]: https://openwrt.org/
[paper]: http://www.cs.umd.edu/~waa/pubs/handoff-lat-acm.pdf
