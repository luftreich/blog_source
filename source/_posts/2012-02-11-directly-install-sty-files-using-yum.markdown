---
comments: true
date: 2012-02-11 22:10:06
layout: post
title: Directly install sty files using yum
categories: [latex]
tags: [fedora, yum sty]
---

Use the following command to install sty files, say `multirow.sty`, using yum:

```
$sudo yum -y install 'tex(multirow.sty)'
```
