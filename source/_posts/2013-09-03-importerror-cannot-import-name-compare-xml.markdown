---
layout: post
title: "ImportError: cannot import name compare_xml"
date: 2013-09-03 11:23
comments: true
categories: [errors, django, python]
---

When I tried to fire up Django server using `manage.py`, I kept getting this
error,which is cause by `from django.test.utils import compare_xml`. It turns 
out that I'm using the wrong Django version (1.4), and I should
upgrade to 1.5.

<!-- more -->

The easiest way to upgrade is using `easy_install`

```bash
# install easy_install if you haven't done so
sudo apt-get install python-setuptools
# now upgrade
sudo easy_install --upgrade django
```

And the python file that actually contains the `compare_xml` method is located
in (in my case):
`/use/local/lib/python2.7/dist-packages/Django-1.5.2-py2.7.egg/django/test/utils.py`

But in the process of figuring out this issue, I learned several thins.

- When importing django modules, e.g., you have to define the
  `DJANGO_SETTINGS_MODULES` environment variable. Just set it to your project's
  `settings.py` will be OK.

- To find out what methods are provided in a module and various other
  information, say `django.test.utils`,  you can use this command in shell:
  ```
  $ DJANGO_SETTINGS_MODULES=settings python -c "import
  django.test.utils;help(django.test.utils);"
  ```
