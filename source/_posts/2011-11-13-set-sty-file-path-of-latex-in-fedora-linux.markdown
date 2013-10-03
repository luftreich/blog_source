---
comments: true
date: 2011-11-13 15:19:33
layout: post
title: Set sty file path of Latex in Linux
categories: [latex]
tags: [sty, path]
---

From time to time, you may want to compose your own sty files to eliminate
long header in your tex file. But it's boring to put you sty file in the same
directory of your tex file every time since you really want your sty file to be
common, i.e., can be accessed everywhere in your system.

<!-- more -->

One way to achieve this is put your sty file in the system latex directory
(e.g. `/usr/share/texlive/texmf-dist/tex/latex`), and then use `texhash` to
refresh the database.

But if you would prefer not touch the system directory and want to put the sty
file somewhere that easy to access and backup, that will not be a very good
practice.

So you can just tell latex where to find its sty files, i.e.,
set the system sty file looking up path. Do this by editing
`/usr/share/texlive/texmf/web2c/texmf.cnf`. Find the variable called
`TEXINPUTS.tex`, add your own sty path there. Don't forget to separate the
directory using ";" and append "//" to the last directory.

When you finish, execute `texhash` in a terminal. Then you can just feel free
to put your sty files in the directory you just specified, latex will now know
where to find them.

BTW, the comments in `texmf.cnf` are very useful if you want to do any other tricks.
