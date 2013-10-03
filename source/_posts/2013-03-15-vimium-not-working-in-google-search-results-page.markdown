---
comments: true
date: 2013-03-15 06:50:16
layout: post
title: Vimium Not Working in Google Search Results Page
categories: [vim]
tags: [chrome, omnibox, vimium]
---

If you're Vim user, then you must try [Vimium][vimium]. It makes your browsing 
much much comfortable!

[vimium]: https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb?hl=en

<!-- more -->

These days, I found that Vimium commands (`j`, `k`, `f`) don't work on Google search
results page. But works just in in any other pages. I tried turning the instant 
search off, logging out my account in Google's homepage, turning of personalized 
search results, etc. None of those work.

Then I found that Vimium only stop working if I use Chrome's Omnibox to search.
That is, if I do the search in Google's home page instead of Chrome's Omnibox,
then everything is fine. I suspect that some extra flags in Omnibox's default
search pattern is the reason why Vimium refused to work.

But Omnibox is so convenience to use (`Alt+D` to focus & search). Opening
Google's homepage every time you need search will certainly be another pain. So
I changed the default behavior of Chrome's Omnibox. Unfortunately, the built-in
Google search pattern is unchangeable, so I added an new search engine entry
and set it as default. Here is the fields of the new entry:

```
Name: Google (or whatever you want) 
Keyword: Google (or whatever you want) 
Search Pattern: http://www.google.com/search?q=%s 
```

Here is a more detailed information about Google's search URL. Add whatever you
need, but keep it minimal, in case you screwed up with Vimium again :-)

<http://www.blueglass.com/blog/google-search-url-parameters-query-string-anatomy/>
