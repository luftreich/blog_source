---
layout: post
title: "Persist and Synchroize VIM undo History using Dropbox"
date: 2013-10-02 10:59
comments: true
categories: [vim]
tags: [vimrc, dropbox, undodir]
---

It's extremely useful to 
 - Have a _virtually_ unlimited undo history, and
 - Have it persisted even after exiting VIM, and 
 - Better, even have it synchronized across all your working machines using Dropbox.

<!-- more -->

Here is the `.vimrc` snippet I used to do the trick.

```
" Persist undo
set undofile
"maximum number of changes that can be undone
set undolevels=9999 
"maximum number lines to save for undo on a buffer reload
set undoreload=9999 

" If have Dropbox installed, create a undo dir in it
if isdirectory(expand("$HOME/Dropbox/"))
    silent !mkdir -p $HOME/Dropbox/.vimundo >/dev/null 2>&1
    set undodir=$HOME/Dropbox/.vimundo//
else
    " Otherwise, keep them in home
    silent !mkdir -p $HOME/.vimundo >/dev/null 2>&1
    set undodir=$HOME/.vimundo//
end
```

Note the double slash after the `undodir`, it tells VIM to name the undo file
using the full path of the editing file, so no naming collision will occur.
