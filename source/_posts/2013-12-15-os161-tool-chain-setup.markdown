---
layout: post
title: "OS161 Tool Chain Setup"
date: 2013-12-15 18:01
comments: true
categories: ["os161"]
tags: ["toolchain", "bmake", "sys161", "texinfo", "binutils", "gcc", "gdb"]
---

This post shows how to install os161 toolchain, including `bmake`, `sys161`,
etc. on your local machine.

<!--more-->

### Why Even Bother?

Some instructors setup the environment on public machines that students can
share; some distribute the whole os161 develop environment in a VM appliance, 
in which the tool chain is already set up for you.  In both cases, students can 
start working on the OS itself immediately, instead of taking down by the
tool chain setting up process and loss confidence even before starting.

However, I think it's still beneficial that we setup the tool chain on our local
machine by ourselves:

 - Virtual Machines typically suffer from performance degradation, especially when your
   machine is not that high-end (4 or 8 cores, 8 or 16 Gig RAM, etc). And most
   people experienced video drive issue after accidentally upgrade the guest VM.
 - The setting up process can help up understand at least how each tools interact.
 - The cross-compiling experience could potentially useful in future
   projects/assignments.

The following instructions are tested under `Ubuntu 13.10 x86_64`, they should
work on other distros, probably with a little tweak.

### Directory Setup

Suppose you want to place the os161 related stuff in `~/projects/courses/os161`,
then you would have to set up the directory structure like this.


```bash
mkdir -p ~/projects/courses/os161
mkdir -p ~/projects/courses/os161/toolbuild
mkdir -p ~/projects/courses/os161/tools/bin
```

Eventually the `os161` directory will be the top level directory for all our os161
stuff. And `toolbuild` will contain all the downloaded and extracted packages,
and `tools` will contain all the os161 environments, like the compiler, debuger, 
sys161, etc.

To simplify further steps, we set up a few environment variables.

```bash
export PREFIX=~/projects/courses/os161/tools
export BUILD=~/projects/courses/os161/toolbuild
export PATH=$PATH:$PREFIX/bin
```

Of course you can install os161 tool chain anywhere you like, just make sure the
directory structure is right.

### Download And Extract the Packages

You can download all the required packages in [this page][dl]. As of writing
this post, the latest packages are:

 - [binutils-2.17+os161-2.0.1.tar.gz][binutils]
 - [gcc-4.1.2+os161-2.0.tar.gz][gcc]
 - [gdb-6.6+os161-2.0.tar.gz][gdb]
 - [bmake-20101215.tar.gz][bmake]
 - [mk-20100612.tar.gz][mk]
 - [sys161-1.99.06.tar.gz][sys161]

Download the above packages and put them in the `toolbuild` directory we just
created.

Extract the packages as follows:

```bash
cd $BUILD
tar xvf binutils-2.17+os161-2.0.1.tar.gz
tar xvf gcc-4.1.2+os161-2.0.tar.gz
tar xvf gdb-6.6+os161-2.0.tar.gz
tar xvf sys161-1.99.0.tar.gz
tar xvf bmake.tar.gz
cd bmake
tar xvf ../mk.tar.gz
cd ..
```
Note that we have to extract the `mk.tar.gz` package _inside_ `bmake` directory.

### Binutils

```bash
cd binutils-2.17+os161-2.0.1
./configure --nfp --disable-werror --target=mips-harvard-os161 --prefix=$PREFIX
find . -name '*.info' | xargs touch
make
make install
cd ..
```

Note how we set the `--prefix` when do configuration. Also, we fool the `make`
system by touching all the `texinfo` files to make the `make` think those files
doesn't need to be rebuilt. Because:

 - They really don't need to be regenerated.
 - We don't want to rebuilt them since it's highly possible that `makeinfo` will
   yell out some annoying errors on those doc files.
 - And we don't really care the docs...

### GCC

```bash
cd gcc-4.1.2+os161-2.0
./configure --nfp --disable-shared --disable-threads --disable-libmudflap --disable-libssp --target=mips-harvard-os161 --prefix=$PREFIX
make -j 8
make install
cd ..
```
Here we use parallel make `-j 8` that will speed up the compiling a little bit.


### GDB

```bash
cd gdb-6.6+os161-2.0
./configure --target=mips-harvard-os161 --disable-werror --prefix=$PREFIX
find . -name '*.info' | xargs touch
make
make install
cd ..
```

Note that we need to `--disable-werror` when configure. Same as `binutils`, we
avoid rebuilding doc files here.

### SYS161

Sys161 is the simulator that our os161 will be running on.

```bash
cd sys161-1.99.0
./configure --prefix=$PREFIX mipseb
make
make install
cd ..
```

### Bmake

```bash
cd bmake
./boot-strap --prefix=$PREFIX
```
At the end of `boot-strap` command output, you should see instructions on how to
install `bmake` properly. In our case, we can do these.


```bash
cp Linux/bmake $PREFIX/bin/
mkdir -p $PREFIX/share/man/cat1
cp bmake.cat1 $PREFIX/share/man/cat1/
sh mk/install-mk $PREFIX/share/mk
```

### Create Symbolic Links

Now if you take a look at `$PREFIX/bin`, you will see a list of executables
named like `mips-harvard-os161-*`, it's convenient to give them shorter name so
that we can save a few keystrokes later.

```bash
cd $PREFIX/bin
sh -c 'for i in mips-*; do ln -s $i os161-`echo $i | cut -d- -f4-`; done'
```
Now do a `ls` again, you should see a bunch of `os161-*` symlinks.

### PATH Setup

Now we've set up all required tool chains to build and run os161. 

Just one more thing, if you close the terminal and open it again, you will notice that bash
can not find all those tools we just set up (e.g., `sys161`, `bmake`). Don't panic, it's because we didn't
tell bash where to find them. Either we type `export PATH=$PATH:~/projects/courses/os161/tools/bin` every time we open terminal, or
better, we tell bash to add it to system path automatically. Add this line to your `.bashrc`.

```bash
export PATH=$PATH:~/projects/courses/os161/tools/bin
```
Then close and open your terminal, do `echo $PATH`, you should see
`...os161/tools/bin` at the end.

### Configure OS161

You may want to clone the os161 repo and configure it. Suppose you've registered
an account on [ops-class.org][ops] and uploaded your public key. Then you can
clone the source tree and configure as follows.

```bash
cd ~/projects/courses/os161
mkdir root
git clone ssh://src@src.ops-class.org/src/os161 src
cd src
./configure --ostree=~/projects/courses/os161/root
bmake
bmake install
cd ..
cp tools/share/examples/sys161/sys161.conf.sample root/sys161.conf
```

Note that:

 - We create an `root` directory under `os161`, this will be where the
   compiled user space binaries, and also the compiled kernel image will go.
 - When configure the os, we specify the `--ostree` argument, so that the
   binaries will be copied to the `root` directory we just created. The default
   location is `~/root`, which is probably not what you want.
 - We copy the sys161 configuration example to the `root` directory. This
   configuration file is needed by sys161.

Now go to `~/projects/courses/os161/root`, you should see something there, e.g.,
`bin`, `hostbin`, `lib`, `man`, etc.

### Compile and Run the Kernel

```bash
cd ~/projects/courses/os161/src/kern/conf
./config ASST0
cd ../compile/ASST0
bmake depend
bmake && bmake install
```

Now let's fire up the kernel.
```bash
cd ~/projects/courses/os161/root
sys161 kernel
```

### Resources

You can find more instructions on tool chain setup and os161 configuration in these pages.

 - [Installing OS/161 On Your Own Machine][waterloo]
 - [OS/161 Toolchain Setup][harvard]
 - [Building System/161 and the OS/161 Toolchain][hmc]
 - [ASST0: Introduction to OS/161][ops-asst0]


[dl]: http://www.eecs.harvard.edu/~dholland/os161/download/
[binutils]: http://www.eecs.harvard.edu/~dholland/os161/download/binutils-2.17+os161-2.0.1.tar.gz
[gcc]: http://www.eecs.harvard.edu/~dholland/os161/download/gcc-4.1.2+os161-2.0.tar.gz
[gdb]: http://www.eecs.harvard.edu/~dholland/os161/download/gdb-6.6+os161-2.0.tar.gz
[bmake]: http://www.eecs.harvard.edu/~dholland/os161/download/bmake-20101215.tar.gz
[mk]: http://www.eecs.harvard.edu/~dholland/os161/download/mk-20100612.tar.gz
[sys161]: http://www.eecs.harvard.edu/~dholland/os161/download/sys161-1.99.06.tar.gz

[waterloo]: https://www.student.cs.uwaterloo.ca/~cs350/common/Install161NonCS.html
[harvard]: http://www.eecs.harvard.edu/~dholland/os161/resources/setup.html
[hmc]: http://www.cs.hmc.edu/~geoff/classes/hmc.cs134.201209/buildos161.html
[ops]: http://www.ops-class.org
[ops-asst0]: http://www.ops-class.org/asst/0
