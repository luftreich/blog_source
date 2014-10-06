---
layout: post
title: "Install Acrobat Reader on Ubuntu 14.04"
date: 2014-10-06 18:43:45 -0400
comments: true
categories: ['linux']
tags: ['acroread', 'ubuntu', 'adobe', 'acrobat']
---

Recently I need to install Adobe Acrobat Reader on couple of my Ubuntu boxes.
The process is full of black magic that sometimes you can't find the documents
anywhere. Hopefully this post will make the process less a pain.

<!--more-->


### Install Dependencies

This is probably a *superset* of all the dependencies. I used trial and error
in the process and I'm not quite sure which packages are really necessary...

With these packages, if I run `acroread` from command line:

 - There is no GTK warnings or whatsoever.
 - Can open PDF with forms (like the ones for Canada VISA application).
 - The icons and menus looks "normal".

Note that since the Acrobat Reader is 32-bit application, so if you're on
64-bit system, remember to append a `:i386` on whatever extra packages you want
to install besides the ones in this list.

```bash
sudo apt-get install libgtk2.0-0:i386 libnss3-1d:i386 libnspr4-0d:i386 lib32nss-mdns libxml2:i386 libxslt1.1:i386 libstdc++6:i386 libcanberra-dev:i386 libcanberra-gtk-dev:i386 libcanberra-gtk-module:i386 libgkt2.0-dev:i386 gtk2-engines:i386 gtk2-engines-*:i386 gnome-themes-standard:i386 unity-gtk2-module:i386 libpangoxft-1.0.0:i386 libpangox-1.0.0:i386 libidn11:i386 dconf-gsettings-backend:i386
```

### Download the Deb Package

```bash
cd ~/Downloads && wget -c http://ardownload.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu/AdbeRdr9.5.5-1_i386linux_enu.deb
```
If the above link fails, try this one instead:

```bash
cd ~/Downloads && wget -c ftp://ftp.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu/AdbeRdr9.5.5-1_i386linux_enu.deb
```

### Installation

```bash
sudo dpkg -i ~/Downloads/AdbeRdr9.5.5-1_i386linux_enu.deb
```

This should complete without any problems if you installed all the packages in the
dependencies. But in case `dpkg` still complains, run this command after `dpkt -i`:

```bash
sudo apt-get -f install
```

This should fix any further missing dependencies.

### Configuration

If you want to use Acrobat Reader to open PDF files by default. Run this command and choose Acrobat Reader from the list:

```bash
mimeopen -d *.pdf
Please choose a default application for files of type application/pdf

    1) Document Viewer  (evince)
    2) Print Preview  (evince-previewer)
    3) GIMP Image Editor  (gimp)
    4) Adobe Reader 9  (AdobeReader)
    5) Other...

use application # 4
```
