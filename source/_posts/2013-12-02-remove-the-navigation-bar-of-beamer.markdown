---
layout: post
title: "Remove the Navigation Bar of Beamer"
date: 2013-12-02 21:11
comments: true
categories: ["latex"]
tags: ["beamer", "navigation"]
---

Honestly, I never clicked the navigation bar in beamer slides, and I really
wondered whether anyone has used it or not. I suspect that most people keep it just
to show the pride that he's using beamer...

<!--more-->

Anyways, the navigation bar can be annoying sometimes, especially when you have
some long foot notes that overlap it. Put this line in the preamble to remove
the navigation bar.

```latex
\beamertemplatenavigationsymbolsempty
```
