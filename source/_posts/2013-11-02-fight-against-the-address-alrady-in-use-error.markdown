---
layout: post
title: "Fight Against the 'Address alrady in use' Error"
date: 2013-11-02 22:36
comments: true
categories: ["C"]
tags: ["bind", "SO_REUSEADDR", "socket"]
---

You have probably seen this error quite often. The detailed reason why this
error occurs is explained in detail [here][article]. 

<!--more -->

In short, if a TCP socket is
not closed properly when the program exits, the OS will put that socket in a `TIME_WAIT`
state for a period of time ([`2MSL`][2msl], usually a couple of minutes). During that time, if
you want to bind to the same port, you'll get the "Address already in use"
error, even though technically no body is actually using that port.

In practice, especially when you're debugging, it's very annoying to wait (even
a few minutes) before you can re-run your program if it crashes previously. And
you often very sure you're the only one that will use that certain port
number. 

The solution is, you can use the `SO_REUSEADDR` option to avoid that binding error.


```c
/* reuse server port, since the OS will prevent us to bind to this port
 * immediately after we close the sock */
int optval = 1;
if (setsockopt(server_sock, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) != 0) {
    perror("setsockopt");
    return -1;
}
```

Now you can happily bind to that port again, again, and again...

### Resources

Here is a few stackoverflow threads that discussing [what happend to the old open
socket][so1], and [the difference between SO_REUSEADDR and
SO_REUSEPORT][so2].


[article]: http://www.serverframework.com/asynchronousevents/2011/01/time-wait-and-its-design-implications-for-protocols-and-scalable-servers.html
[2msl]: http://www.borella.net/content/MITP432/TCP/text26.html
[so1]: http://stackoverflow.com/questions/775638/using-so-reuseaddr-what-happens-to-previously-open-socket
[so2]: http://stackoverflow.com/questions/14388706/socket-options-so-reuseaddr-and-so-reuseport-how-do-they-differ-do-they-mean-t
