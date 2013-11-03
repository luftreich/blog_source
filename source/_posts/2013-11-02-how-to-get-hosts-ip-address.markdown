---
layout: post
title: "How to Get Local Host's Real IP Address"
date: 2013-11-02 20:20
comments: true
categories: ["C"]
tags: ["network", "ip", "getsockname", "gethostbyname", "getifaddrs"]
---

I encounter this problem while doing an [network course project][project]. Easy
as it sounds, it's actually not a trivial task.

<!-- more -->

### Old-fashioned -- `gethostbyname`

I did some network programing in old days, so I was tempted to use the
straightforward way using [`gethostbyname`][gethostbyname].

```c
#include <unistd.h>
#include <netdb.h>

char hostname[256];
if (gethostname(hostname, sizeof(hostname)) < 0) {
    perror("gethostname");
    return -1;
}

struct hostent* host = gethostbyname(hostname);
if (host == NULL) {
    perror("gethostbyname");
    return -1;
}

struct in_addr ip = *(struct in_addr*)host->h_addr_list[0];
printf("My IP is %s\n", inet_ntoa(ip));
```

Yet when I run the program, this code snippet will always print out `127.0.0.1`,
which is not useful since I want to get the _real_ (or _external_) IP address.

Apparently, this is because some nasty settings in the `/etc/hosts` file, there
is an entry looks like this

```
127.0.0.1   timberlake.cse.buffalo.edu timberlake localhost.localdomain localhost
```

Since `gethostbyname` is actually a DNS looking up process, that DNS request, 
unfortunately, is served by the `/etc/hosts` file, instead of a real decent DNS
server.

### More Advanced `getifaddrs`

I searched the web and found [this stackoverflow threads][stackoverflow] talking 
about using [`getifaddrs`][getifaddrs] to get NIC's IP address. I tried and it seems to work.
Since the machine I worked on uses "eth0" as external NIC, so when looping the
result, I just match the results that has the name "eth0".

Although it works well, the solution is a little bit ad-hoc. Since the network
interface's name is not necessarily "eth0", for example, in some laptop or
netbook, the primary interface may be "wlan0" instead of "eth0".

### Most Elegant Way

Finally, I adopted the solution that mentioned later on that thread. Basically,
I connected to a well-known server (e.g., Google's DNS server) and then get my 
local socket's information (more specifically, IP) using [`getsockname`][getsockname]. 
Here is the final code snippet.

```
/* get my hostname */
char hostname[256];
if (gethostname(hostname, sizeof(hostname)) < 0) {
    perror("gethostname");
    return -1;
}

// Google's DNS server IP
char* target_name = "8.8.8.8";
// DNS port
char* target_port = "53";

/* get peer server */
struct addrinfo hints;
memset(&hints, 0, sizeof(hints));
hints.ai_family = AF_INET;
hints.ai_socktype = SOCK_STREAM;

struct addrinfo* info;
int ret = 0;
if ((ret = getaddrinfo(target_name, target_port, &hints, &info)) != 0) {
    printf("[ERROR]: getaddrinfo error: %s\n", gai_strerror(ret));
    return -1;
}

if (info->ai_family == AF_INET6) {
    printf("[ERROR]: do not support IPv6 yet.\n");
    return -1;
}

/* create socket */
int sock = socket(info->ai_family, info->ai_socktype, info->ai_protocol);
if (sock <= 0) {
    perror("socket");
    return -1;
}

/* connect to server */
if (connect(sock, info->ai_addr, info->ai_addrlen) < 0) {
    perror("connect");
    close(sock);
    return -1;
}

/* get local socket info */
struct sockaddr_in local_addr;
socklen_t addr_len = sizeof(local_addr);
if (getsockname(sock, (struct sockaddr*)&local_addr, &addr_len) < 0) {
    perror("getsockname");
    close(sock);
    return -1;
}

/* get peer ip addr */
char myip[INET_ADDRSTRLEN];
if (inet_ntop(local_addr.sin_family, &(local_addr.sin_addr), myip, sizeof(myip)) == NULL) {
    perror("inet_ntop");
    return -1;
}
```

[project]: https://github.com/jhshi/course.network.p2p
[gethostbyname]: http://linux.die.net/man/3/gethostbyname
[getsockname]: http://man7.org/linux/man-pages/man2/getsockname.2.html
[stackoverflow]: http://stackoverflow.com/questions/212528/get-the-ip-address-of-the-machine
[getifaddrs]: http://man7.org/linux/man-pages/man3/getifaddrs.3.html
