---
layout: post
title: "Simulate Random MAC Protocol in NS2 (Part III)"
date: 2013-12-15 12:11
comments: true
categories: ["network"]
tags: ["mac", "ns2"] 
---

Now we have the [simulation script][post1], and also [added our protocol to the
NS2 simulator][post2], which is still a placeholder. Now we're going the
actually implement our own random MAC protocol.

<!--more-->

### Protocol Description
According to the project specification, when sending out an packet, our protocol
is supposed to send out `X` copies of the packet at random time before sending
out next packet. As long as the receiver receive at least one of the `X`
duplicates, we say this packet was successfully delivered.

### Protocol Parameters

From the protocol description, it's obvious that we need to know:

 - How many copies to send for one packet? I.e., the `X`
 - The interval of sending packet from up layer, so that we can schedule
   resending before up layer pass down the next packet.

So we add two class variables in `mac/rmac.h`

```cpp
int repeatTx_;
double interval_;
```

And in the constructor function of `RMAC` class, we need to bind the variables
through TCL so that we can pass values in TCL script.

```cpp
bind("repeatTx_", &repeatTx_);
bind("interval_", &interval_);
```

### TCL Object Binding

We also need to let TCL runtime to _know_ our protocol. That is, when we
write this in TCL script.

```tcl
set val(mac) Mac/RMAC
```

TCL runtime would have to know the corresponding class of the `Mac/RMAC`.

Since we copied code from `mac-simple.cc` and also made the changes, this part
has been done, but let's just review the code snippet that does the binding.


```cpp
static class RMACClass : public TclClass {
    public :
        RMACClass() : TclClass("Mac/RMAC") {}
        TclObject* create(int, const char* const*) {
            return (new RMAC());
        }
} class_rmac;
```

Here the `Mac/RMAC` string will be our protocol name.


### Interaction with Adjacent Layer

The most important function in any NS2 MAC protocol is the `recv` function. It's
the interface to upper (Network Layer) and also lower (Physical Layer) layers.

The `recv` of our MAC protocol will look like this.

```cpp
void
RMAC::recv(Packet *p, Handler *h) {

	struct hdr_cmn *hdr = HDR_CMN(p);
	/* let RMAC::send handle the outgoing packets */
	if (hdr->direction() == hdr_cmn::DOWN) {
		sendDown(p,h);
	}
    else {
        sendUp(p,h);
    }
}
```

Here we first get the header of the packet, and check it's directory.
`hdr_cmn::DOWN` means this packet is from upper layer, and we need to send it
out. `hdr_cmn::UP` means this packet is from lower layer (received packet), we 
need to deliver it to upper layer.

### Repeat Sending

The key part of our MAC protocol is to repeated send multiple copies when
sending out a packet. So we need to mainly modify the `sendDown` function.

```cpp
double max_delay = 0;

// generate repeatTx_ number of random delays
double* delays = new double[repeatTx_];
for (int i = 0; i < repeatTx_; i++) {
    delays[i] = (rand() % 100) / 100.0 * interval_;
    if (delays[i] > max_delay) {
        max_delay = delays[i];
    }
}

// use dummy tx handler for first repeatTx_-1 packets
for (int i = 0; i < repeatTx_; i++) {
    if (delays[i] != max_delay) {
        Scheduler::instance().schedule(&resendHandler_, (Event*)p->copy(), delays[i]);
    }
}
delete delays;

waitTimer->restart(max_delay);
if (rx_state_ == MAC_IDLE ) {
    // we're idle, so start sending now
    sendTimer->restart(max_delay + ch->txtime());
} else {
    // we're currently receiving, so schedule it after
    // we finish receiving
    sendTimer->restart(max_delay + ch->txtime()
            + HDR_CMN(pktRx_)->txtime());
}
```

We first generate `repeatTx_` number of delays before next interval. Except for
the `max_delay`, which will be the last copy to send, we use the `Scheduler` to
resend the duplicated packets, and for last packet, we just use the timer
scheme of `SimpleMac`.

Here is the `resendHander_` looks like.


```cpp
void
RMACResendHandler::handle(Event* p) {
    mac_->resend((Packet*) p);
}

void
RMAC::resend(Packet* p) {
    downtarget_->recv(p, NULL);
}
```

You can find the complete code for `rmac.cc` and `rmac.h` [here][repo].



[post1]: /2013/12/13/simulate-random-mac-protocol-in-ns2-part-i/
[post2]: /2013/12/13/simulate-random-mac-protocol-in-ns2-part-ii/
[repo]: https://github.com/jhshi/course.network.ns2
