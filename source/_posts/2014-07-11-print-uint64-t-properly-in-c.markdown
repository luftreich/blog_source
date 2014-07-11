---
layout: post
title: "Print uint64_t Properly In C"
date: 2014-07-11 18:02:37 -0400
comments: true
categories: ['linux']
tags: ['printf', 'format', 'c']
---

`stdint.h` provides various machine-independent integer types that are very
handy to use, especially the `uint64_t` family. You would assume it's something
like `long long unsigned int` and tempted to use `%llu` in `printf`, which, however, will be
reported as a warning by any decent compiler.

```
warning: format '%llu' expects argument of type 'long long unsigned int', but argument 4 has type 'uint64_t' [-Wformat]
```

<!--more-->

### The Right Way

The right way to print `uint64_t` in `printf`/`snprintf` family
functions is this ([source][so]):

```c
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

uint64_t i;
printf("%"PRIu64"\n", i);
```

`PRIU64` is a macro introduced in C99, and are supposed to mitigate platform
differences and "just print the thing". More macros for `printf` family can be
found [here][int].

### The Story

In my case, I mistakenly use `%lu` to print a `uint64_t` integer. Of course, the
compiler gave warning on this. But...you know, it's "just warnings", should be no big deal.
Well, 80% of the time it is fine. Yet this time, it's not.
Since `uint64_t` takes 8 bytes but `%lu` will only eat 4 bytes, so my next print
argument, `%s` comes in and happily print who knows what...

__Never ignore warnings, NEVER.__

[so]: http://stackoverflow.com/questions/8132399/how-to-printf-uint64-t
[int]: http://en.cppreference.com/w/c/types/integer
