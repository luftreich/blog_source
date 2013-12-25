---
layout: post
title: "Simulate Random MAC Protocol in NS2 (Part IV)"
date: 2013-12-15 13:01
comments: true
categories: ["network"]
tags: ["ns2", "mac", "trace", "python"]
---

Now we have [designed the simulator][p1], [add a new MAC protocol to NS2][p2],
and [implement the Random Resend MAC protocol][p3], the final part will be
analyze the trace file to measure the performance of our new protocol.

<!--more-->

### Format of the Trance Entry

One line in the trace file may look like this.

```
s 0.010830867 _70_ MAC  --- 27 cbr 148 [0 46000000 8 0] ------- [70:0 0:0 32 0] [0] 0 0
|      |        |   |        |  |   |
|      |        |   |        |  |   +----- Packet Size
|      |        |   |        |  +--------- Traffic Type
|      |        |   |        +------------ Packet UID
|      |        |   +--------------------- Layer
|      |        +------------------------- Node ID
|      +---------------------------------- Time
+----------------------------------------- Event Type
```

You can find more details about the trace format [here][wiki].

### Trace Filtering

In this project, we're only interested the traces that
 
 - From MAC layer, and
 - With CBR traffic type
 - With Event Type in "Send"(s), "Receive"(r) and "Drop"(D)

So we first filter those not-so-interesting traces out.

```python
def filter(trace_file) :
  with open(trace_file, 'r') as f :
    raw_lines = f.read().split('\n')

  print("%s raw traces found." % (len(raw_lines)))

  traces = []
  for line in raw_lines :
    fields = line.split(' ')
    if fields[0] not in ['s', 'r', 'D'] :
      continue
    if not (fields[3] == 'MAC') :
      continue
    if not (fields[7] == 'cbr') :
      continue

    traces.append({'action': fields[0], 'node': fields[2], 'pid': int(fields[6])})


  print("%s filtered traces found." % (len(traces)))
  return traces
```

### Delivery Probability

To calculate the delivery probability, we need to know

 - How many unique packets are sent out by all source nodes?
 - How many unique packets received by the sink node?

These two metrics can be easily obtained as following:

```python
nodes = set(t['node'] for t in traces)
print("%s nodes found." % (len(nodes)))

sent = len(set(t['pid'] for t in traces))
recv = len(set(t['pid'] for t in traces if t['node'] == SINK_NODE and t['action'] == 'r'))

print("sent: %d, recv: %d, P: %.2f%%" % (sent, recv, float(recv)/sent*100))
```

Remember that we use `LossMonitor` as sink? Now is the time to cross-reference
the results here with the ones from the stats file. The total received packets
number should match.

The final delivery probability w.s.t the repeat count `X` is somehow like this
in my case (packet size is 16 bytes).

{% img /images/prob.png %}

Note that somehow this is not the ideal probability distribution. Please refer
to this paper for theoretical analysis and also simulation results.

[QoMOR: A QoS-aware MAC protocol using Optimal Retransmission for Wireless
Intra-Vehicular Sensor Networks][paper]

[wiki]: http://nsnam.isi.edu/nsnam/index.php/NS-2_Trace_Formats
[p1]: /2013/12/13/simulate-random-mac-protocol-in-ns2-part-i/
[p2]: /2013/12/15/simulate-random-mac-protocol-in-ns2-part-ii/
[p3]: /2013/12/15/simulate-random-mac-protocol-in-ns2-part-iii/
[paper]: http://ieeexplore.ieee.org/xpl/login.jsp?tp=&arnumber=4300816&url=http%3A%2F%2Fieeexplore.ieee.org%2Fxpls%2Fabs_all.jsp%3Farnumber%3D4300816
