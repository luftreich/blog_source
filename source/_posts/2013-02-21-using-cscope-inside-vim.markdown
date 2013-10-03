---
comments: true
date: 2013-02-21 04:35:58
layout: post
title: Using Cscope INSIDE Vim
categories: [vim]
tags: [cscope]
---

The goal we want to accomplish here is, jumping to a function definition (maybe
in another file,) finding out where a symbol is defined, finding out what
function(s) call current function and what functions are called from this
function, ALL WITHOUT LEAVING VIM.

<!-- more -->

First, make sure you have `cscope` installed by issuing the following command:

``` bash
$ cscope --version
```

If bash complains "command not find", then install `cscope`. In Ubuntu, the
command is:

``` bash
$ sudo apt-get install cscope
```

Then, we need to generate `cscope` database. If you're dealing with C files,
then in the root directory of the source tree, using this command:

```
$ cscope -RUbq
```

If you're dealing with Java files, before generating the database, we need to
tell `cscope` tracing which files:

``` bash
$ find . -name *.java > cscope.files
$ cscope -RUbq
```

The explanations are:

```
-R: Recurse subdirectories during search for source files.
-U: Check file time stamps. This option will update the time stamp on the database even if no files have changed.
-b: Build the cross-reference only. We don't want the interactive mode.
-q: Enable fast symbol lookup via an inverted index
```

For more details, consult the `cscope` manual:

```
$ man cscope
```

After this step, several `cscope` database files will be generated. If you're
using git or hg to manage your code, you may want to ignore them in the git/hg
repository. Do that by adding these lines into your .gitignore/.hgignore

```
cscope.*
```

Then we need to tell Vim how to interact with `cscope`. Add the following lines
into your `.vimrc`:

```
if has("cscope")
    set csprg=/usr/bin/cscope
    set csto=0
    set cst
    set csverb
    " C symbol
    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    " definition
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    " functions that called by this function
    nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
    " funtions that calling this function
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    " test string
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    " egrep pattern
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    " file
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    " files #including this file
    nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>

    " Automatically make cscope connections
    function! LoadCscope()
        let db = findfile("cscope.out", ".;")
        if (!empty(db))
            let path = strpart(db, 0, match(db, "/cscope.out$"))
            set nocscopeverbose " suppress 'duplicate connection' error
            exe "cs add " . db . " " . path
            set cscopeverbose
        endif
    endfunction
    au BufEnter /* call LoadCscope()

endif
```

We're done! Now using Vim to edit a source code file. Put the cursor on a
symbol (variable, function, etc.), First press `Ctrl+\`, then press:

```
s: find all appearance of this symbol
g: go to the definition of this symbol
d: functions that called by this function
c: functions that calling this function
```

For more details about `cscope`, inside Vim, press `:h cs` to see the help
message of `cscope`.
