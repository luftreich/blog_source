---
comments: true
date: 2013-02-26 07:24:45
layout: post
title: Eclim E218 When Open a File in New Tab
categories: [errors]
tags: [eclim, vim]
---

In the directory sub window, when I use `T` to open a file in new tab, the
following error message will occur:

<!-- more -->

```
No matching autocommands
Error detected while processing function eclim#project#tree#ProjectTree..eclim#project#tree#ProjectTreeOpen..eclim#display#window#VerticalToolWindowOpen:
line 78:
E218: autocommand nesting too deep
Error detected while processing function 53_OpenFile..eclim#tree#ExecuteAction:
line 12:
E171: Missing :endif
Error detected while processing function 53_OpenFile:
line 8:
E171: Missing :endif
```

To fix this, apply the following patch to `$HOME/.vim/eclim/plugin/project.vim`
described in [here][patch]

[patch]: https://github.com/ervandew/eclim/commit/597aeb31fa4ea1e2c102547871935dbb89cf9202
