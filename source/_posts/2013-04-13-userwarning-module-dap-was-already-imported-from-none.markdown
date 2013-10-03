---
layout: post
title: "UserWarning: module dap was already imported from None"
date: 2013-04-13 18:52
comments: true
categories: errors
tags: [python, dap, basemap, matplot]
---

I installed `python-matploglib` and `python-mpltoolkits.basemap` using `apt`,
but when I tried to import Basemap using `from mpltoolkits.basemap import
Basemap`, the following warning shows up:

```
usr/lib/pymodules/python2.7/mpl_toolkits/__init__.py:2: UserWarning: Module dap was already imported from None, but /usr/lib/python2.7/dist-packages is being added to sys.path
  __import__('pkg_resources').declare_namespace(__name__)

```

<!-- more -->

To resolve this warning, edit the file
`/usr/lib/python2.7/dist-packages/dap-2.2.6.7.egg-info/namespace_packages.txt`,
add `dap` as the first line.

```
dap
dap.plugins
dap.responses
```

Ref: [Stackoverflow Question][stack]

[stack]: http://stackoverflow.com/questions/13915269/why-do-i-get-userwarning-module-dap-was-already-imported-from-none
