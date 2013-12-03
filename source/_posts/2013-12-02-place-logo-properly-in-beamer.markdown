---
layout: post
title: "Place Logo Properly in Beamer"
date: 2013-12-02 21:17
comments: true
categories: ["latex"]
tags: ["logo", "beamer", "pgf"]
---

It's stylish to place an low-profile yet charming logo in some corner of your
slides. Here we use the `pgf` package to accomplish this.

<!--more-->

```latex
\usepackage{pgf}  
\logo{\pgfputat{\pgfxy(9.45,1.5)}{\pgfbox[center,base]{\includegraphics[width=1.7cm]{logo.png}}}}  
```

You probably need to tweak the coordinates a little bit to fit the logo to your
slides.

Also, to hide logo and also page number on title page, you'll need to this.

```latex
\begin{document}
{
% no page #, no logo on title page
\setbeamertemplate{footline}{}
\setbeamertemplate{logo}{}
\begin{frame}
  \titlepage
\end{frame}
}

% other frames
\end{document}
```

Here is how they look like.

{% img /images/title_page.png %}
{% img /images/first_page.png %}
