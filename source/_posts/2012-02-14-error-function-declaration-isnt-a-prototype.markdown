---
comments: true
date: 2012-02-14 14:51:44
layout: post
title: "error: function declaration isn't a prototype"
categories: [errors]
tags: [c, function, prototype]
---

This error occurs when you try to declare a function with no arguments, and
compile with `-Werror=strict-prototypes`, as follows:

<!-- more -->

``` c
int foo();
```

Fix it by declare it as

``` c
int foo(void);
```

This is because in c, `foo(void)` takes no arguments while `foo()` takes a infinite
number of arguments.

Thanks to this [stackoverflow post][post]

[post]: http://stackoverflow.com/questions/42125/function-declaration-isnt-a-prototype
