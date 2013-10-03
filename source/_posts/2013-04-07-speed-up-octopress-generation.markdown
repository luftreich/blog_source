---
layout: post
title: "Speed up Octopress Generation"
date: 2013-04-07 17:04
comments: true
categories: [octopress]
tags: [generation, speedup, gsl, isolate]
---

`rake generate` can take quite a while, especially when you have many blog
posts. Here are a few tips on how to speed up the generation process.

<!-- more -->

### Use `rake isolate` and `rake integrate`

It's usually the case when you have many existing posts, while you're modifying
a few of them, it's certainly a overkill to compile all the posts if you just
ant to preview what you're really editing. Octopress provide an `isolate`
command just for this purpose.

The idea is, you can use `rake isolate` to move all no-interested posts in an
separate directory outside `source/_posts` , so when you do `rake generate`,
you'll just compile those posts you care about. When you're done editing and
want to deploy your sites, you can use `rake integrate` to move those posts back
and generate a complete site.

The usage of `rake isolate` is simple, you just provide the keywords, and those
posts whose title contain these keywords are kept, other posts are moved to
`source/_stash`. Say I'm composing a post named
`2013-04-07-hello-world.markdown`, and assume this post is the only one that
contains `hello` in its title. Then the following command will do the job:

``` bash
$ rake isolate[hello]
```

### Use rb-gsl to boost lsi computation

Jekyll has builtin support for related posts, so as Octopress. You just need to
add this line to your `_config.yml`:

```
lsi: true
```

Once you enabled `lsi`, you'll definite want to install `rb-gsl` package to make
the related post generation process faster. When Octopress remind you that:

```
Notice: for 10x faster LSI support, please install http://rb-gsl.rubyforge.org/
```

It's not kidding! 

Note that Octopress doesn't work with the latest gsl versioned `1.15.*`. You'll
need to install gsl `1.14` manually since `apt` or `yum` will probably install
`1.15.*` for you.

``` bash
wget http://ftp.gnu.org/gnu/gsl/gsl-1.14.tar.gz
tar xvf gsl-1.14.tar.gz
cd gsl-1.14
./configure
make
sudo make install
```

Check the installation by the `gsl-config` command:

``` bash
gsl-config --version
1.14
```

Then edit your `Gemfile` in your blog source root. Add the following line in the
`development` group:

```
gem 'gsl'
```

Then use `bundle` to install it.

``` bash
bundle install
```

You're all set. Now when you do `rake generate`, you shouldn't see that `10x
faster` line anymore.
