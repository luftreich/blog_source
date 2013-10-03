---
comments: true
date: 2012-07-11 14:37:38
layout: post
title: 'ssh error: Agent admitted failure to sign using the key'
categories: [errors]
tags: [ssh]
---

If you follow [my previous post about ssh/scp without password][post], but you
got this error when you try to ssh to B on A, then you need to add RSA or DSA
identities to the authentication agent. A ssh-add command on host A will solve
your pain.

[post]: /2012/04/27/sshscp-without-password/

<!-- more -->

``` bash
$ ssh-add
# Sample output
Identity added: /home/jack/.ssh/id_rsa (/home/jack/.ssh/id_rsa)
```

**Reference**

<http://www.cyberciti.biz/faq/unix-appleosx-linux-bsd-agent-admitted-failuretosignusingkey/>
