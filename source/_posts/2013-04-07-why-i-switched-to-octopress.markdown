---
layout: post
title: "Why I Switched to Octopress"
date: 2013-04-07 16:01
comments: true
categories: octopress
tags: [wordpress, migration]
---

I used to blog on [wordpress.com][wordpress]. After a year or so, I finally
decided to abandoned it and switched to [Octopress][octopress] + 
[Github Pages][githubpages]. 
Here are the reasons and how I migrated to Octopress. Maybe because I was using 
_wordpress.com_, and those who use a self-hosted wordpress have something 
different to say, the way I see it, wordpress, at lease _wordpress.com_, sucks.

[wordpress]: http://jhshi.wordpress.com
[octopress]: http://octopress.org
[githubpages]: http://pages.github.com

<!-- more -->

### Use your favorite editor? No-no

I am an Vim addict and I almost use Vim for everything (except for watching
videos perhaps). It's extremely uncomfortable using the dumb text input frame
embedded in web page. Besides, I often need to insert inlining code or code block 
in blogs. For inline code, I have to use plain text mode and wrap them using the
html `<code>` tag manually. And for code blocks, I have to use the stupid,
**unportable** `[sourcecode]` tag.

When I realized that awful experience even cool down my passion for blogging, I 
know it's time to change.

With Octopress, I can use Vim to compose blogs locally. For formating, 
[Markdown][markdown] did a decent enough job. I'm more than happy with these.

[markdown]: http://daringfireball.net/projects/markdown/

### Page loading speed

In Wordpress, everything is stored in database, and the page is generated
dynamically when you request it. Despite those [caching plugins][cache], why
bother dynamic anyway when static pages are just good enough?


Using [Google's PageSpeed Insights][pagespeed] for measurement, my old blog site
hosted in _wordpress.com_ got 78 out of 100 score, while this blog got 91 out of 100. 
Hooray!

[cache]: http://codex.wordpress.org/WordPress_Optimization/Caching#Caching_Plugins
[pagespeed]: https://developers.google.com/speed/pagespeed/insights

### Migration

Jekyll offers several ways to [migrate your previous blogs][migrate]. Octopress
is based on Jekyll, so all these ways also apply. I found the [Exitwp][exitwp]
tool extremely usefully for migrating wordpress blogs. One drawback of Exitwp is it can
not handle non-ascii characters so a few of my previous blogs written in Chinese
can not be migrated using it.

[migrate]: https://github.com/mojombo/jekyll/wiki/blog-migrations
[exitwp]: https://github.com/thomasf/exitwp
