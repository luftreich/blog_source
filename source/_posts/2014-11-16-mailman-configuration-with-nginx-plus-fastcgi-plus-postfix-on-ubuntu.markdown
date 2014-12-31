---
layout: post
title: "Mailman Configuration with Nginx+FastCGI+Postfix on Ubuntu"
date: 2014-11-16 13:02:25 -0500
comments: true
categories: ['Linux']
tags: ['mailman', 'nginx', 'fastcgi', 'postfix', 'maillist']
---

Here are the steps and caveats to setup a proper mail list on Ubuntu server. The
instructions are are for Ubuntu 14.04 LTS, and should be easy to adapt for other
platforms.

<!--more-->

## Assumptions

Here we assume the following:

 - You have an domain, `example.com`.
 - You want to mail list running at machine with host name `lists.example.com`.
 - The mail list address should look like `somelist@example.com`.
 - You have setup the [DNS MX record][mx_wiki] for `example.com` to point to
     `lists.example.com`. Please use [MX Toolbox][mx_toolbox] to double check.
 - You already have a Nginx server up and running at `lists.exmaple.com`.

## Background

Before we dive in the setup, here is the role of each tool:

 - Nginx: HTTP server, provide Mailman web interface.
 - FastCGI: CGI tool, dynamically generate Mailman HTML pages.
 - Postfix: Mail Transfer Agent, we use it to actually send and receive emails.
 - Mailman: Mail list tool, member management.

Suppose you send a email to `somelist@example.com`. Here are what will happen:

 - You email provider, say Gmail, queries the MX record of `example.com`, figure
     out is actually the IP address of `lists.example.com`.
 - Gmail send the email to `lists.example.com`.
 - Postfix receives the email, and route this to Mailman.
 - Mailman figure out who are in this list, then tell Postfix to forward the
     email to them.
 - List members receive this email sent by Postfix.


## Package Installation

#### FastCGI

```bash
$ sudo apt-get install fcgiwrap
```
Open `/etc/init.d/fcgiwrap`, make sure `FCGI_USER` and `FCGI_GROUP` are both
`www-data`.


#### Mailman

```bash
$ sudo apt-get install mailman
```
During installation, choose language support, say `en`. The instructions will
also tell you to create a `mailman` list. __Do NOT do this yet__, we will create the
list later, after we configured mailman properly.


#### Postfix

```bash
$ sudo apt-get install postfix
# or this if you have installed postfix
$ sudo dpkg-reconfigure postfix
```

Make sure you choose the following:

 - General type of mail configuration: __Internet Site__
 - System mail name: __example.com__ (without `lists`)
 - Root and postmaster mail recipient: you Linux user name on `lists.example.com`
 - Other destinations to accept mail for: make sure `example.com` is there.
 - Force synchronous updates on mail queue: No.
 - Local networks: make sure `example.com` is there.
 - Mailbox size limit: 0.
 - Local address extension character: `+` (the plus sign).
 - Internet protocols to use: all.


## Nginx Configuration

In `/etc/nginx/fastcgi_params`, comment out this line:

```
fastcgi_param SCRIPT_FILENAME $request_filename;
```

Suppose your web server is configured in `/etc/nginx/sites-available/www`, add
these lines to you server configuration:

```
location /mailman {                                                            
  root  /usr/lib/cgi-bin;                                                      
  fastcgi_split_path_info (^/mailman/[^/]+)(/.*)$;                             
  fastcgi_pass  unix:///var/run/fcgiwrap.socket;                               
  include /etc/nginx/fastcgi_params;                                           
  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;            
  fastcgi_param PATH_INFO       $fastcgi_path_info;                            
}                                                                              
location /images/mailman {                                                     
  alias /usr/share/images/mailman;                                           
}                                                                              
location /pipermail {                                                          
  alias /var/lib/mailman/archives/public;                                    
  autoindex on;                                                              
}                               
```

Restart Nginx server, you should be able to see the web page at http://lists.example.com/mailman/listinfo

```bash
$ sudo service nginx restart
```

## Mailman Configuration

Open `/etc/mailman/mm_cfg.py`, modify these lines:

 - `DEFAULT_URL_PATTERN`: should be `http://%s/mailman`.
 - `DEFAULT_EMAIL_HOST`: should be `example.com`.
 - `DEFAULT_URL_HOST`: should be `lists.example.com`.

## Postfix Configuration

Open `/etc/postfix/main.cf`, make sure these lines are correct:

```
mydomain = example.com
myhostname = lists.$mydomain
myorigin = /etc/mailname
mydestination = $mydomain localhost.$mydomain $myhostname localhost
mynetworks = $mydomain 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128

alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
local_recipient_maps = proxy:unix:passwd.byname $alias_maps
```

`local_recipient_maps` tells Postfix how to route the emails.

If you use Sendgrid for outgoing emails, also add these lines:

```
smtp_sasl_auth_enable = yes 
smtp_sasl_password_maps = static:yourSendGridUsername:yourSendGridPassword 
smtp_sasl_security_options = noanonymous 
smtp_tls_security_level = encrypt
header_size_limit = 4096000
relayhost = [smtp.sendgrid.net]:587
```

## Create the First Mail List

Ok, now we pretty much configured everything. Let's create the first email list
called `mailman`, which will be used for Mailman logistics (like email
reminders).

```bash
$ sudo newlist mailman
# Enter you email address and password
```

It will tell you to paste this lines to `/etc/aliases`.

```
## mailman mailing list                                                          
mailman:              "|/var/lib/mailman/mail/mailman post mailman"              
mailman-admin:        "|/var/lib/mailman/mail/mailman admin mailman"             
mailman-bounces:      "|/var/lib/mailman/mail/mailman bounces mailman"           
mailman-confirm:      "|/var/lib/mailman/mail/mailman confirm mailman"           
mailman-join:         "|/var/lib/mailman/mail/mailman join mailman"              
mailman-leave:        "|/var/lib/mailman/mail/mailman leave mailman"             
mailman-owner:        "|/var/lib/mailman/mail/mailman owner mailman"             
mailman-request:      "|/var/lib/mailman/mail/mailman request mailman"           
mailman-subscribe:    "|/var/lib/mailman/mail/mailman subscribe mailman"         
mailman-unsubscribe:  "|/var/lib/mailman/mail/mailman unsubscribe mailman"    
```

Then update the `/etc/aliases.db` database:

```bash
$ sudo newaliases
```

Then restart Mailman and Postfix:

```bash
$ sudo service postfix restart
$ sudo service mailman restart
```

Now if you go to `http://lists.example.com/mailman/listinfo`, you should see the
newly created `Mailman` list.

You can continue by adding other lists, and send test emails to these lists.

## About Aliases

The `/etc/aliases` file tells Postfix how to route the emails. In above
`mailman` example, when receiving emails to `mailman@example.com`, Postfix will
know to call the command `/var/lib/mailman/mail/mailman post mailman`.

You can also tell Postfix to forward certain emails to another email address.
For example:

```
help:  example.help@gmail.com
```

Then if you send a email to `help@example.com`, Postfix will forward it to
`example.help@gmail.com`.





[mx_wiki]: http://en.wikipedia.org/wiki/MX_record
[mx_toolbox]: http://mxtoolbox.com/SuperTool.aspx
