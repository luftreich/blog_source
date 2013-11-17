---
layout: post
title: "Popular Posts Plugin for Octopress"
date: 2013-11-10 20:08
comments: true
categories: ["octopress"]
tags: ["popular posts", "jekyll", "plugin"]
---

This post describes the [octopress-popular-posts][pp] for Octopress. Although
there is [one plugin][pp2] that does the job, it used Google Page Rank to
determine if a post is popular or not. I'd like to, however, use the page view
of the post as metric.

<!-- more -->

## How To Use

In [another post][post], I described how to use the [octopress-page-view][pv] plugin to
show the PV of each post and the whole site. This plugin depend on that to
generate each post's PV count. So you need to first install that plugin.

### Installation

 - Clone the repo from Github

```bash
cd /tmp
git clone https://github.com/jhshi/octopress-popular-posts.git
cd octopress-popular-posts
```

   The structure of the directory will look like this

```
octopress-popular-posts/
|-- _config.yml
|-- plugins
|   `-- popular_posts.rb
|-- README.md
`-- source
    `-- _include
        `-- custom
            `-- asides
                `-- popular_posts.html
```

 - Copy `plugins/popular_posts.rb` to your `plugins` directory. And place 
`source/include/custom/asides/popular_posts.html` in your custom asides directory.

 - Add this asides to your asides list in `_config.yml`

### Configuration
This plugin doesn't need any special configurations, as long as you set 
`octopress-page-view` plugin correctly, it should work out of box.

There is one parameters you can tune, though. You can set how many popular posts
will be shown in `popular_posts.html`

## How It Works

`octopress-page-view` has done all the hard job for us. All we need to do is
just sort the posts by their page view count.

Note that we need to set the `priority` of this plugin as `low`, since we reply
on `octopress-page-view` plugin to run first to generate the PV count.

```ruby
class PopularPosts < Generator
    safe :true
    priority :low

    def generate(site)
      # require octopress-page-view plugin
      if !site.config['page-view']
        return
      end

      popular_posts = site.posts.sort do |px, py|
        # just catch the rare case
        if px.data['_pv'] == nil || py.data['_pv'] == nil then 0
        elsif px.data['_pv'] > py.data['_pv'] then -1
        elsif px.data['_pv'] < py.data['_pv'] then 1
        else 0
        end
      end

      site.config.merge!('popular_posts' => popular_posts)
    end
end
```

One trick I did here is that, `site` object has not `data` field to merge into,
so I merge the `popular_posts` data to `site.config`.

[pp]: https://github.com/jhshi/octopress-popular-posts
[pp2]: https://github.com/octopress-themes/popular-posts
[pv]: https://github.com/jhshi/octopress-page-view
[post]: /2013/11/10/page-view-plugin-for-octopress/
