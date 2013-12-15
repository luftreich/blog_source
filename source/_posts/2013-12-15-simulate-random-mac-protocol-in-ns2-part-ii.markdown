---
layout: post
title: "Simulate Random MAC Protocol in NS2 (Part II)"
date: 2013-12-15 11:37
comments: true
categories: ["network"]
tags: ["ns2", "tcl", "mac", "c++"]
---

In [previous post][prev], we wrote an NS2 simulation program that fits the
project specification, except that we're using the standard 802.11 MAC protocol.
In this post, we'll discuss how to add our own MAC protocol to NS2.

<!--more-->

### Compile NS2 from Source

To add an new protocol to NS2, we actually need to download the whole NS2 source
tree and add some extra CPP files there, which is embarrassingly inconvenient.
But for now, we have to live with it.

Anyways, download the NS2 all-in-one package from [here][ns2-dl], put the
tarball somewhere in your home, say `~/projects/`, then extract it.

```bash
cd ~/projects
tar xvf ns2-allinone-2.35.tar.gz
cd ns2-allinone-2.35
./install
```

The install script will only generate the binaries in current directory, and
will NOT actually copy them to anywhere. After the compilation is done, you'll
will find the `ns` executable in the `ns-2.35` subdirectory.

Suppose you put your project files (e.g., the TCL file we wrote) in
`~/projects/network/ns2`, then it's convenient to have an symbol link to the
`ns` binary. 

```bash
cd ~/projects/network/ns2
ln -svf ~/projects/ns2-allinone-2.35/ns-2.35/ns myns
```

The you'll have an symbol link called `myns`, which points the actual
executable. Then you can run your simulation this way.


```bash
myns random_mac.tcl
```

In which the `random_mac.tcl` is the TCL file we wrote in last post.


### Add a New Mac Protocol

To add a new MAC protocol, say `RMAC`, we need to do the following. Suppose
you're in the `ns2-allinone-2.35/ns-2.35` directory.

 - Create `rmac.cc` and `rmac.h` file in the `mac` subdirectory, for now, just
   leave them empty.

 - Edit `Makefile`, find the line contains `mac/smac.o` (around line 249), add one line like this
```makefile
    .....
	mac/mac-802_3.o mac/mac-tdma.o mac/smac.o \
	mac/rmac.o\
    .....
```

So now, when you do `make` inside the `ns-2.35` directory, our source
file `rmac.cc` and `rmac.h` will be compiled. Of course, at this point, there is
no content at those two files, which we'll add later.


### Adapt the `SimpleMac` Protocol

The NS2 source contains a simple MAC protocol called `SimpleMac`, which is a
good start point for us to adapt.

Just copy all the contents in `mac/mac-simple.h` to `mac/rmac.h`, and
`mac/mac-simple.cc` to `mac/rmac.cc`. Then change `Mac/Simple` to `Mac/RMAC` 
line 60 of the `rmac.cc` file. You should be able to compile using the `make`
command in `ns-2.35` directory.

If everything is OK, go back to the project directory `~/projects/network/ns2`,
change the MAC protocol to `Mac/RMAC` (previously `Mac/802.11`), you should be
able to run the simulation using `myns`, which points to the `ns` binary we just
compiled.


[ns2-dl]: http://sourceforge.net/projects/nsnam/files/allinone/ns-allinone-2.35/ns-allinone-2.35.tar.gz/download
[prev]: /2013/12/13/simulate-random-mac-protocol-in-ns2-part-i/
