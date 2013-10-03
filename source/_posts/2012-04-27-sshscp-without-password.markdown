---
comments: true
date: 2012-04-27 16:45:41
layout: post
title: ssh/scp without password
categories: [linux]
tags: [ssh, scp]
---

Suppose you have two machines: A and B. A is your work machine, you do most of
your work on it. But B is a little special (e.g., connected to some specific
hardware) that you need to ssh on it or copy some file from A to B from time to
time. Here is the way that you can get rid of entering passwords every time you
do ssh/scp.

<!-- more -->

First, on machine A, generate a DSA key pair:

``` bash
$ ssh-keygen -t rsa 
Generating public/private rsa key pair. 
Enter file in which to save the key (YOUR_HOME/.ssh/id_rsa):
# press ENTER here to accept the default filename 
Enter passphrase (empty for no passphrase): 
# press ENTER here to use no passphrase, otherwise, you still need
# to enter this passphrase when ssh 
Enter same passphrase again: 
# press ENTER here 
Your identification has been saved in $HOME/.ssh/id_rsa. 
Your public key has been saved in $HOME/.ssh/id_rsa.pub. 
The key fingerprint is: ..... (omited)
```

Then, change the access mode of .ssh directory

``` bash
$ chmod 775 ~/.ssh 
```

Then append the content of your just generated `id_rsa.pub` to the
`$HOME/.ssh/authorized_keys` file on machine B:

``` bash
# copy the id_rsa.pub file to host B 
$ scp ~/.ssh/id_rsa.pub b@B:. 
# login to B 
$ ssh b@B 
# append the content to authorized_keys 
$ cat id_rsa.pub >> .ssh/authorized_keys 
```

Finally, ssh on to B and change the access mode of the file `authorized_keys`.
This is optional, maybe you don't need to do this if you can already ssh
without entering password.

``` bash
$ ssh b@B 
$ chmod 700 .ssh 
$ chmod 640 ~/.ssh/authorized_keys
```

Depend on your version of ssh, you may also need to do the following:

``` bash
$ ssh b@B $ cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys2
```

That it! Enjoy!

**Reference**

- <http://www.cyberciti.biz/faq/ssh-password-less-login-with-dsa-publickey-authentication/>

- <http://www.linuxproblem.org/art_9.html>
