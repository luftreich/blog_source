---
layout: post
title: "Remove the Figure Prefix of Caption in Beamer"
date: 2013-12-02 21:52
comments: true
categories: ["latex"]
tags: ["beamer", "caption"]
---

Sometimes it's annoying to have a "Figure" prefix when you add caption to a
figure in beamer. Here is a way of how to eliminate that.

<!--more-->

```latex
\usepackage{caption}
\captionsetup[figure]{labelformat=empty}
```

Before
{% img /images/caption_before.png %}

After
{% img /images/caption_after.png %}

