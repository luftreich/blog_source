---
comments: true
date: 2012-02-14 15:34:36
layout: post
title: Quick switch between source and header files in Vim
categories: [vim]
---

There are many ways to do this, as listed in [vim wiki][vim_wiki].

[vim_wiki]: http://vim.wikia.com/wiki/Easily_switch_between_source_and_header_file

<!-- more -->


I tried the script way ([a.vim][a.vim], but not feel comfortable. Because:

1. I'm doing kernel development, so I have a bunch of my own `stdio.h`, `stdlib.h`, 
etc. But `a.vim` will bring you into the system include path, not my own 
2. Even though I jumped to the right space, jump back is not easy

[a.vim]: http://www.vim.org/scripts/script.php?script_id=31

Finally, I found the ctags way very usable. Issue this command in your source
tree root,

``` bash
$ ctags --extra=+f -R .
```

Then in vim, you can just type ` :tag header.h ` to jump to `header.h` and use your 
familiar `ctrl+t ` to jump back, very intuitive. Plus, I found a [` gf ` command of vim][gf]
that can jump to the file under cursor, but with the same drawbacks as `a.vim`, 
thus not adorable.

[gf]: http://vim.wikia.com/wiki/Open_file_under_cursor
