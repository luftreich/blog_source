---
comments: true
date: 2011-11-18 15:30:03
layout: post
title: Center the Caption of Figure or Table
categories: [latex]
tags: [caption, table, figure]
---


In latex, the caption of figure or table is aligned left by default. Sometimes,
it's not that beautiful, especially when your article is two column.

<!-- more -->

To fix this, use the `caption` package with `center` as the option.

```
\usepackage[center]{caption}
```

If you like, you can also substitute `center` with `left` or `right`

Here is a [detailed manual][manual] of `caption` package.

[manual]: http://mirror.math.ku.edu/tex-archive/macros/latex/contrib/caption/caption-eng.pdf
