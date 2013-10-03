---
comments: true
date: 2012-06-22 13:34:33
layout: post
title: Specify graphics path in Latex
categories: [latex]
tags: [graphicx, graphicspath]
---

We can use the `graphicx` package together with the `graphicspath` command to
specify the looking up path for pictures. A typical structure may look like
this:

<!-- more -->

{% raw %}
```latex
\usepackage{graphicx}
% Must use this command BEFORE you begin document!
\graphicspath{{pic_path1/}{pic_path2}}
\begin{document}
% some content
\end{document}
```
{% endraw %}

As you can see, the syntax of `graphicspath` command is very simple. You just
enclose your picture path, either relative to current work path, or absolute
path, in a pair of curly braces. Note that you must place this command before
you begin document otherwise it will take no effect.

Please refer to [this page][manual] for more details about `graphicspath` command.

[manual]: http://www.tex.ac.uk/cgi-bin/texfaq2html?label=graphicspath
