---
comments: true
date: 2011-11-17 21:26:21
layout: post
title: Figure Over Two Columns in Latex
categories: [latex]
tags: [figure]
---

You may often find a table or figure is too big to fit into one column when
your article has two columns. Use this to insert a figure (same with table) and
it will save you:

<!-- more -->

```latex
\begin{figure*}
% figure here
\end{figure*}
```

Note the star (`*`) appended after figure? That's the trick.

