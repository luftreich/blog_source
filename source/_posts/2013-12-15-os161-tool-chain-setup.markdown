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

Some instructors [setup the environment on public machines][canada] that students can
share; some [distribute the whole os161 develop environment in a VM appliance][ops], 
in which the tool chain is already set up for you.  In both cases, students can 
start working on the OS itself immediately, instead of taking down by the
tool chain setting up process and loss confidence even before starting.

However, I think it's still beneficial that we setup the tool chain on our local
machine by ourselves:

 - Virtual Machines typically suffer from performance degradation, especially when your
   machine is not that high-end (4 or 8 cores, 8 or 16 Gig RAM, etc.). And most
   people experienced video driver issues after accidentally upgrade the guest VM.
 - The setting up process can help us understand at least how each tools interact.
 - The cross-compiling experience could potentially useful in future projects/assignments.
 - You can gain some confidence if you can set up the tool chain successfully.
   And confidence is the key to survive later assignments.

The following instructions are tested under `Ubuntu 13.10 x86_64` with gcc
version 4.8.1, they should, however, also work on other distros.

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
and `tools` will contain all the os161 environments, like the compiler, debugger, 
simulator, etc.

To simplify further steps, we set up a few environment variables.

```bash
export PREFIX=~/projects/courses/os161/tools
export BUILD=~/projects/courses/os161/toolbuild
export PATH=$PATH:$PREFIX/bin
```

Of course you can install os161 tool chain anywhere you like, just make sure the
directory structure is right. Note that:

 - In the whole process of doing this, you don't need to touch any file outside
   our `os161` directory (unless explicitly stated). So if you must use `sudo` 
   to copy some stuff, then you probably typed something wrong.
 - If you choose to install the tool chain somewhere else, you need to adjust
   the variables accordingly.
 - The environment variables (e.g., `PREFIX`, `BUILD`) are _only valid in current
   session_, so in case you want to take a break(e.g., play guitar) during the
   process, make sure you still have those variables. You can do that by do
   `echo $PREFIX`, make sure it's `~/projects/courses/os161/tools`. If they
   disappear somehow, just redo the `export` commands.

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
Note that *we have to extract the `mk.tar.gz` package _inside_ `bmake` directory*.

### Binutils

```bash
cd binutils-2.17+os161-2.0.1
./configure --nfp --disable-werror --target=mips-harvard-os161 --prefix=$PREFIX
find . -name '*.info' | xargs touch
make
make install
cd ..
```

Note how we set the `--prefix` when configure. That option is to tell the
Makefile where the generated binary or library files should go.

Also, we fool the `make` command by touching all the `texinfo` files to make 
the `make` think those files doesn't need to be rebuilt. Because:

 - They really don't need to be regenerated.
 - We don't want to rebuilt them since it's highly possible that `makeinfo` will
   yell out some annoying errors on those doc files.
 - And we don't really care the docs...


{%ribbonp warning Checkpoint %}
After this step, you should have some `mips-harvard-os161-*` binary files in the
`tools/bin` directory.
{%endribbonp%}

### GCC

```bash
cd gcc-4.1.2+os161-2.0
./configure --nfp --disable-shared --disable-threads --disable-libmudflap\
        --disable-libssp --target=mips-harvard-os161 --prefix=$PREFIX
make -j 8
make install
cd ..
```
Note that:

 - The backslash in the `configure` command is just to tell our shell that we
   haven't done typing, so do not execute the command just yet. If you type the
   whole command in one line, you don't need backslash.
 - `make -j 8` means use 8 threads when compile. Usually this will speed up the
   compilation process quite a little bit.

{%ribbonp warning Checkpoint %}
After this step, you should see `mips-harvard-os161-gcc` in the `tools/bin`
directory.
{%endribbonp%}


### GDB

```bash
cd gdb-6.6+os161-2.0
./configure --target=mips-harvard-os161 --disable-werror --prefix=$PREFIX
find . -name '*.info' | xargs touch
make
make install
cd ..
```

Note that:

 - We need to `--disable-werror` when configure. Because later version of gcc
   will report warnings that older version of gcc will not.
 - Same as `binutils`, we avoid rebuilding doc files here.

If you see this error when do configure.
```
configure: error: no termcap library found
```

You probably need to install the `libncurses5-dev` package.

```bash
sudo apt-get install libncurses5-dev
```

{%ribbonp warning Checkpoint %}
After this step, you should see `mips-harvard-os161-gdb` in the `tools/bin`
directory.
{%endribbonp%}

### SYS161

Sys161 is the simulator that our os161 will be running in.

```bash
cd sys161-1.99.06
./configure --prefix=$PREFIX mipseb
make
make install
cd ..
```

{%ribbonp warning Checkpoint %}
After this step, you should see `sys161`, `hub161`, `stat161` and `trace161`
symlinks in the `tools/bin` directory. 
{%endribbonp%}


### Bmake

```bash
cd bmake
./boot-strap --prefix=$PREFIX
```
At the end of `boot-strap` command output, you should see instructions on how to
install `bmake` properly. In our case, it look like these:

```bash
mkdir -p /home/jhshi/projects/courses/os161/tools/bin
cp /home/jhshi/projects/courses/os161/toolbuild/bmake/Linux/bmake /home/jhshi/projects/courses/os161/tools/bin/bmake-20101215
rm -f /home/jhshi/projects/courses/os161/tools/bin/bmake
ln -s bmake-20101215 /home/jhshi/projects/courses/os161/tools/bin/bmake
mkdir -p /home/jhshi/projects/courses/os161/tools/share/man/cat1
cp /home/jhshi/projects/courses/os161/toolbuild/bmake/bmake.cat1 /home/jhshi/projects/courses/os161/tools/share/man/cat1/bmake.1
sh /home/jhshi/projects/courses/os161/toolbuild/bmake/mk/install-mk /home/jhshi/projects/courses/os161/tools/share/mk
```

Just do the commands _one by one_ in the order given.

{%ribbonp warning Checkpoint %}
After this step, you should see `bmake` symlink in `tools/bin` directory. And a
bunch of `*.mk` files in `tools/share/mk` directory.
{%endribbonp%}

### Create Symbolic Links

Now if you take a look at `$PREFIX/bin`, you will see a list of executables
named like `mips-harvard-os161-*`, it's convenient to give them shorter name so
that we can save a few keystrokes later.

```bash
cd $PREFIX/bin
sh -c 'for i in mips-*; do ln -s $i os161-`echo $i | cut -d- -f4-`; done'
```

Note that the symbol around `echo $i $ cut -d- -f4-` is the key that under 
{%key Esc %} (the same key with tilde (`~`)).

{%ribbonp warning Checkpoint %}
After this step, you should see a bunch of `os161-*` symlinks in `tools/bin`
directory. 
{%endribbonp%}

### PATH Setup

Now we've set up all required tools to build and run os161. 

In the first step, we change our `PATH` environment variable to include the
`tools/bin` directory. Now is the time to make it permanent so that we won't
need to type `export PATH=$PATH:~/projects/courses/os161/tools/bin` every time we open terminal.
Add this line to your `.bashrc`.

```bash
export PATH=$PATH:~/projects/courses/os161/tools/bin
```

{%ribbonp warning Checkpoint %}
Close current terminal and open an new one. Type this commands, and check if the
output matches.
```bash
which sys161
# should be something like /home/jhshi/projects/courses/os161/tools/bin
which bmake
# should be something like /home/jhshi/projects/courses/os161/tools/bin
```
{%endribbonp%}


### Configure OS161

Now let's get to real business. Obtain a copy of the os161 source tree according
to your course's instruction. In this case, we'll use the one from
[ops-class.org][ops]. 

Suppose you've registered an account on [ops-class.org][ops] and uploaded your 
public key. Then you can clone the source tree and configure as follows.

```bash
cd ~/projects/courses/os161
mkdir root
git clone ssh://src@src.ops-class.org/src/os161 src
```

If you encounter errors like this.

```bash
cloning into 'src'...
Permission denied (publickey).
fatal: Could not read from remote repository.
```

Then you probably didn't set up your key right. Make sure you put the private
key (normally `id_rsa`) inside `~/.ssh/`, and copy the content of `id_rsa.pub`
to [ops-class.org][ops].

Now we have the source tree, let's move on and configure it.

```bash
cd src
./configure --ostree=$HOME/projects/courses/os161/root
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
 - We must use `$HOME/projects/courses/os161/root`, instead of
   `~/projects/courses/os161/root`. Otherwise, `bmake` will complain.
 - We copy the sys161 configuration example to the `root` directory. This
   configuration file is needed by `sys161` - the simulator.

{%ribbonp warning Checkpoint %}
Go to `~/projects/courses/os161/root`, you should see some directories there, e.g.,
`bin`, `hostbin`, `lib`, `man`, etc.
{%endribbonp%}

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
{%ribbonp warning Checkpoint %}
You should see outputs like this:
```bash
sys161: System/161 release 1.99.06, compiled Dec 15 2013 17:42:02

OS/161 base system version 1.99.05
Copyright (c) 2000, 2001, 2002, 2003, 2004, 2005, 2008, 2009
President and Fellows of Harvard College.  All rights reserved.

Put-your-group-name-here's system version 0 (ASST0 #7)

320k physical memory available
Device probe...
lamebus0 (system main bus)
emu0 at lamebus0
ltrace0 at lamebus0
ltimer0 at lamebus0
beep0 at ltimer0
rtclock0 at ltimer0
lrandom0 at lamebus0
random0 at lrandom0
lhd0 at lamebus0
lhd1 at lamebus0
lser0 at lamebus0
con0 at lser0

cpu0: MIPS r3000
OS/161 kernel [? for menu]:
```
{%endribbonp%}


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
