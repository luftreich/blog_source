---
layout: page
comments: false
sharing: false
footer: false
---

## Research

#### PhoneLab

[PhoneLab][phonelab] is a large scale smart phone testbed operated at UB. Current we have 288
participants using the phone ([Galaxy Nexus][gn]) we provided as their primary 
phone. PhoneLab is capable of application and system level smart phone research.

I'm currently the maintainer of the [Conductor][conductor] app, which is
responsible for:

 - Monitor platform healthiness
 - Collect logs from device
 - Upload logs to our backend server
 - Perform Platform OTA update
 - And a lot more!

#### Smart Phone Assisted Wifi AP Configuration

IEEE 802.11 WLAN, commonly known as WiFi, only has 
[three non-overlapping channels at 2.4GHz band][wiki]. This causes severe channel collision and
interference problems, especially in environment with dense Access Point (AP)
deployment.

We're trying to let smart phones give feedback to AP about its wireless
environment, so that we can configure the APs with optimal channel and power
allocation.

## Course
#### [CSE589 Modern Network Concepts][network]

This is an core course of CSE graduate program, with several challenging
projects. You can found [several blogs][network_blog] on this project.

 - [P2P File Sharing System][p2p]
 - [Distance Vector Algorithm in Network Layer][dvr]
 - [NS2 Simulation of Random MAC Protocol][ns2]
 - [Notes][notes]

#### [CSE521 Operating System (OS161)][os]

This is probably what this blog is most famous for. I didn't actually take this
course, I just found the projects very interesting. Plus, the instructor offers
online automatic grading system, which is so cool.

You can found [a bunch of blogs][os161_blog] on this project.

#### CSE596 Introduction to the Theory of Computation

I composed an collection of glossaries, theorems, corollaries, etc., at 
[this git repo][cs_theory].

## Other
#### Octopress Plugins
This is blog is powered by [Octopress][octopress]. I wrote a few Octopress
plugins that make my blogging easier.

 - [octopress-post-revision][revision]
   Show blog revision history. See [this blog][revision_blog]
 - [octopress-page-view][pv]
   Display page view count from Google Analytics. See [this blog][pv_blog]
 - [octopress-popular-post][pp]
   Display a list of most popular posts. Here more "popular" means more PV. See
   [this blog][pp_blog]


<hr/>
{% include post/revision.html %}


[phonelab]: http://www.phone-lab.org
[gn]: http://en.wikipedia.org/wiki/Galaxy_Nexus
[conductor]: https://play.google.com/store/apps/details?id=edu.buffalo.cse.phonelab.harness.developer
[wiki]: http://en.wikipedia.org/wiki/List_of_WLAN_channels
[network]: http://www.cse.buffalo.edu/~qiao/cse489
[os]: http://www.ops-class.org
[octopress]: http://www.octopress.org
[revision]: https://github.com/jhshi/octopress-post-revision
[pv]: https://github.com/jhshi/octopress-page-view
[pp]: https://github.com/jhshi/octopress-popular-posts
[p2p]: https://github.com/jhshi/course.network.p2p
[network_blog]: /tag/network/
[os161_blog]: /category/os161/
[pv_blog]: /2013/11/10/page-view-plugin-for-octopress/
[pp_blog]: /2013/11/10/popular-posts-plugin-for-octopress/
[dvr]: https://github.com/jhshi/course.network.dvr
[revision_blog]: /2013/11/17/post-revision-plugin-for-octopress/
[cs_theory]: https://github.com/jhshi/course.cs_theory
[notes]: https://github.com/jhshi/course.network.note
[ns2]: https://github.com/jhshi/course.network.ns2
