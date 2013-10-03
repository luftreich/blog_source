---
comments: true
date: 2011-11-10 17:30:33
layout: post
title: "pdflatex: error while loading shared libraries: libpoppler.so.13"
categories: [errors]
tags: [libpopller, pdflatex, linux]
---

This error occurs when I try to use latex after upgrading to fedora 16. After
Google it, I find the reason may be when upgrading, the pregrade just update
the system components, but not user applications, such as `texlive`. And since
current version `texlive` counts on some older libraries, issues occur.

<!-- more -->

I find that the current `libpoppler` in `/usr/lib` is `libpoppler.so.18`, so I
made a symbolic link to it:

``` bash
sudo ln -s /usr/lib/libpoppler.so.18 /usr/lib/libpoppler.so.13
```

This fixes the problem. Thanks to [this post][post]

[post]: https://bugs.launchpad.net/ubuntu/+source/xournal/+bug/778234
