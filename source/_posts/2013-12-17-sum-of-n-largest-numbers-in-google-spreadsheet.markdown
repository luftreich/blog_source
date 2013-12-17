---
layout: post
title: "Sum of N Largest Numbers in Google Spreadsheet"
date: 2013-12-17 15:52
comments: true
categories: ["tricks"]
tags: ["query", "sort", "spreadsheet"]
---

I encountered this problem when trying to get the final grades for 
[an course][241] I TAed for this semester. There were 10 homework assignments
throughout the semester, and we're supposed to only count the 8 highest grades. 
So, how to accomplish this in Google Spreadsheet?

<!--more-->

### First Try

After poking around Google search results a little bit, I found this solution,
which _seems_ to work.


```
=ceiling(sum(filter(E2:N2,E2:N2>=large(E2:N2, 8)))/8,1)
```

Where `E2:N2` contains the 10 grades. The [`large`][large] function will return
the 8th highest grade of the 10, and then we only sum the grades that larger
than or equal to that grade.

This seems all fine until I accidentally found that some students got more than
100 pts, which is impossible because all our grades are 100 based!

### The Problem

Well, what's wrong with the previous formula? Suppose a student's 10 grades look
like this

```
94  97  92  94  98  100 100 100 100 100
```

Sort them in descending order

```
 1   2   3   4   5   6   7   8   9   10
100 100 100 100 100  98  97  94  94  92
```

So in this case the 8th largest number is 94, yet there are two 94, and we
really just need one of them.


### The Solution

After struggling in [Google Spreadsheet function list][list], I found that we
can actually do [SQL-like queries][query] within the spreadsheet! This leads to
the final solution.


```
=ceiling(sum(query(sort(transpose(E2:N2), 1, FALSE), "select * limit 8"))/8,1)
```

Here we first transpose the row data into column, then sort them in descending
order, then we just take the first 8 grades when calculating the average.



[241]: http://www.cse.buffalo.edu/~bina/cse241/fall2013/index.html
[large]: https://support.google.com/drive/answer/3094008
[list]: https://support.google.com/drive/table/25273?hl=en
[query]: https://developers.google.com/chart/interactive/docs/querylanguage
