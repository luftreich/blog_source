---
layout: post
title: "Replicate Gem Installation"
date: 2014-11-08 23:48:11 -0500
comments: true
categories: ['linux']
tags: ['ruby', 'gem', 'cut', 'xargs']
---

I use Octopress to manage my blogs, which rely on correct ruby gem version to
work. Although Octopress use Bundler to manage the gem dependencies, sometimes a
simple `bundle install` does not work out of box. Since everything works fine on
one of my machines, I decided to replicate the exact ruby/gem setup of that
machine.

<!--more-->

## Dump Gem list

First, dump all the gems and version to a text file on the machine that you want
to replicate.

```bash
$ gem list | tail -n+1 | sed 's/(/--version /' | sed 's/)//' > gemlist
```

Here we first dump all the gem files using `gem list`, then we remove the first
line of the output (`***LOCAL GEMS***`), and replace left parenthesis with
`--version` for later convenience, and remove right parenthesis.

Suppose your app use Bundler, then you should use this command instead
of the above one, to make sure the we install exactly the same set of gems for
that app.


```bash
$ bundle | head -n-2 | cut -d' ' -f2,3 | sed 's/ / --version /' > gemlist
```

Here since the output of `bundle` is a bit different with `gem list`, we first
remove the last two lines of the output (see below), then we split each line
using white space and only get the second (gem name) and third (version) parts,
finally we substitute white space with `--version`, similar as above.

```
....
Using stringex 1.4.0
Using bundler 1.7.3
Your bundle is complete!
Use `bundle show [gemname]` to see where a bundled gem is installed.
```

## Install the Gems

Copy the `gemlist` file to the machine that you want to install gems on, and use
this command to install the gems. To make sure we have a clean slate, we first
remove all Gems first.

```bash
$ gem list | cut -d" " -f1 | xargs sudo gem uninstall -aIx
```

Then install all the Gems, here we do not install document for sake of time.

```bash
$ cat gemlist | xargs -L 1 sudo gem install --no-ri --no-rdoc
```

Here we use `-L 1` option to tell `xargs` to treat each line as a separate
command.

Finally, before you do `rake` in your project, remember to delete the
`Gemfile.lock` file, it may contain some obsolete gems and misleading bundler.
