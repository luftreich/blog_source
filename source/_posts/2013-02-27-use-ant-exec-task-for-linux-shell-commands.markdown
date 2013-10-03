---
comments: true
date: 2013-02-27 03:59:02
layout: post
title: Use Ant Exec task for Linux Shell Commands
categories: [Android]
tags: [ant, exec]
---

Suppose we use cscope and/or ctags for indexing source code of our Java project
and we want to update the meta data files (e.g. cscope.out, tags) each time
after we compile. We can use the `--post-comile` target to accomplish this.
Create a `custom_rules.xml` in your project root directory with the following
content. This file will be included to your main build.xml file.

<!-- more -->

```xml
<?xml version="1.0" encoding="UTF-8"?> 
<project>
    <target name="-post-compile"> 
        <exec executable="find" failonerror="true"> 
            <arg line=" . -name *.java"/> 
            <redirector output="cscope.files" /> 
        </exec> 
        <exec executable="cscope" failonerror="true"> 
            <arg line="-RUbq" /> 
        </exec> 
        <exec executable="ctags" failonerror="true"> 
            <arg line="-R ." /> 
        </exec> 
    </target>
</project>
```

Here we create one task, namely `exec` task, to execute our commands. Pay
special attention to our first command, `find`. More specifically, how we
redirect the output here. The normal bash redirect symbol `>` doesn't not work
here.

Reference:

- <http://ant.apache.org/manual/using.html>
- <http://ant.apache.org/manual/Tasks/exec.html>
- <http://ant.apache.org/manual/Types/redirector.html>
