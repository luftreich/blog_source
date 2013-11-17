---
layout: post
title: "Post Revision Plugin For Octopress"
date: 2013-11-17 16:39
comments: true
categories: ["octopress"]
tags: ["plugin", "revision", "git", "ruby", "jekyll", "Liquid"]
---

Writing blogs is not a one-time thing. Maybe sometime after you posted a blog,
you find a typo, or you get some feedback from your readers and want to further
elaborate on some paragraph in your blog, and so on. So keep a revision history
for each post is a good idea, not only for you, but also for your readers, to
let them know that you're keep polishing your blogs.

<!--more-->

However, doing this manually is kind of tedious, especially when you made
multiple changes you want to show. Fortunately, you use static site generator
(like [Jekyll][jekyll] or [Octopress][octopress]) and use `git` to manage your
content. (What? You don't? The I feel sad for you :-) So why don't just show the
`git` revision history for that blog? This is the [octopress-post-revision][pv]
comes for.

If you feel interested, please refer to the [README page][pv] on how to
install this plugin and how to configure it. This post will give a detailed
description on how this plugin works.

The idea is simple, yet implementing it is not trivial. It's more difficult for
me since this is my first time trying to write some code in ruby... But let's
break down the task into pieces ant tackle them one by one.

### Get Post's Path On You Local File System

We need these information since we need to do a `git log` on those files. Jekyll
provides the `Generator` interface which allows us to generate extra
information, which is exactly what we want.

We need three piece of information:

 - Post file's full/absolute path
 - Post file name
 - Post file's dir name

The last two information are used to generate the `View on Github` link.

This is what the `PostFullPath` looks like.

```ruby
class PostFullPath < Generator
    safe :true
    priority :high

    # Generate file info for each post and page
    #  +site+ is the site
    def generate(site)
      site.posts.each do |post|
        base = post.instance_variable_get(:@base)
        name = post.instance_variable_get(:@name)
        post.data.merge!({
          'dir_name' => '_posts',
          'file_name' => name, 
          'full_path' => File.join(base, name),
        })
      end
      site.pages.each do |page|
        base = page.instance_variable_get(:@base)
        dir = page.instance_variable_get(:@dir)
        name = page.instance_variable_get(:@name)
        page.data.merge!({
          'dir_name' => dir,
          'file_name' => name, 
          'full_path' => File.join(base, dir, name)})
      end
    end
end
```
The `Post` class has several instance variables (e.g., `@base, @name`) that has
the file information, yet how to get them outside the class got me. After Google
a bit, [this thread][so] gives me the solution, i.e., the
`instance_variable_get` method.

Another thing to note is the `dir_name`, since Jekyll assumes post files are put
in the `_post` directory, so we can hard code `post['dir_name']` as `_posts`.
Yet for pages, we need the real dir name.

### The `revision` Liquid Tag

Once we got the file information, we can use `git` to get the change history of
that file. We also need to format the logs for display purpose.

Here is the code that fetch logs from `git`:

```ruby
cmd = 'git log --date=local --pretty="%cd|%s" --max-count=' + @limit.to_s + ' ' + full_path
logs = `#{cmd}`
```

We specify the date format as `local`, and the log message as customized format.
`%cd` means commit date, and `%s` is the subject. We also limit the number of
logs, in case you get to many commit on on post.

### The `View on Github` Link

Since we only display the latest `@limit` number of commit, we provide the `View
on Github` link which links to the Github's commit history page. The format of
the URL is

```
https://github.com/<user>/<repo>/commits/<branch>/<file_path>
```

Here is the code that get branch information.

```ruby
cmd = 'git rev-parse --abbrev-ref HEAD'
# chop last '\n' of branch name
branch = `#{cmd}`.chop
```

Now we have all the information we need, and here is how we compose the final
URL.

```ruby
link = File.join('https://github.com', site['github_user'], site['github_repo'],
                 'commits', branch, site['source'], post['dir_name'], post['file_name'])
```


[jekyll]: http://jekyllrb.com/
[octopress]: http://octopress.org/
[pv]: https://github.com/jhshi/octopress-post-revision
[so]: http://stackoverflow.com/questions/12122736/access-instance-variable-from-outside-the-class
