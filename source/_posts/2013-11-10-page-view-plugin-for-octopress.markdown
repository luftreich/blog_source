---
layout: post
title: "Page View Plugin for Octopress"
date: 2013-11-10 18:21
comments: true
categories: ["octopress"]
tags: ["plugin", "jekyll", "octopress", "ruby"]
---

It's always nice to display some blog stats, such as page view count, to give
readers an sense how _popular_ some site/posts are. Unfortunately, there is (or
should I say 'was'?) no such plugin that does this job nicely for 
[Octopress][octopress], so I decided to write one myself. And here comes the
plugin called [octopress-page-view][pv].

<!-- more -->

I use [Google Analytics][analytics] to track my blog. And there is an Octopress 
plugin called [jekyll-ga][ga], which can sort blog posts by certain metrics of 
Google Analytics. For me, chronological order works just fine. So I just grab
the part that fetch data from Google Analytics.

I haven't done any decent ruby coding before, so bear with me if I wrote some
silly ruby code. But it works.

## How To Use

### Get the plugin
 - Install required gems

```bash
sudo gem install chronic google-api-client
```

 - Clone the repository

```bash
cd /tmp
git clone https://github.com/jhshi/octopress-page-view.git
cd octopress-page-view
```

 The structure of the directory will look like this

```bash
octopress-page-view/
|-- _config.yml
|-- plugins
|   `-- page_view.rb
|-- README.md
`-- source
    `-- _include
        `-- custom
            `-- asides
                `-- pageview.html
```

 - Copy `plugins/page_view.rb` to your `plugins` directory, and copy
   `source/_include/custom/asides/pageview.html` to your custom asides
   directory.

 - In your `_config.yml`, add `pageview.html` to your asides array.

### Setup and Configuration

The README file of the [jekyll-ga][ga] project gives an very detailed
description about [how to set up a service account for Google data API][setup],
which I'm not going to repeat here.

After you've set up the service account, you'll need to add some configurations
to your `_config.yml` file. Here is a sample configuration.

```yaml
# octopress-page-view
page-view:
  service_account_email:    # XXXXXX@developer.gserviceaccount.com
  key_file: privatekey.p12  # service account private key file
  key_secret: notasecret    # service account private key's password
  profileID:                # ga:XXXXXXXX
  start: 3 years ago        # Beginning of report
  end: now                  # End of report
  metric: ga:pageviews      # Metric code
  segment: gaid::-1         # All visits
  filters:                  # optional
```

## How It Works

This plugin provides an Jekyll [Generator][generator], called `GoogleAnalytics`,
to fetech data from Google, and a Jekyll [Liquid Tag][tag] to actually generate
the formated page view count.

### Fetch Analytics Data

This part is adapted from [jekyll-ga][ga]. Basically, we will create an Google
API client, and after proper authorization, making request to Google.

```ruby
pv = site.config['page-view']

# need to provide application_name and application_version, otherwise, APIClient
# will warn ...
client = Google::APIClient.new(
        :application_name => 'octopress-page-view',
        :application_version => '1.0',
        )

# Load our credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(pv['key_file'], pv['key_secret'])
client.authorization = Signet::OAuth2::Client.new(
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => 'https://www.googleapis.com/auth/analytics.readonly',
        :issuer => pv['service_account_email'],
        :signing_key => key)

# Request a token for our service account
client.authorization.fetch_access_token!
analytics = client.discovered_api('analytics','v3')

# prepare parameters
params = {
    'ids' => pv['profileID'],
    'start-date' => Chronic.parse(pv['start']).strftime("%Y-%m-%d"),
    'end-date' => Chronic.parse(pv['end']).strftime("%Y-%m-%d"),
    'dimensions' => "ga:pagePath",
    'metrics' => pv['metric'],
    'max-results' => 100000,
}

if pv['segment']
    params['segment'] = pv['segment']
end
if pv['filters']
    params['filters'] = pv['filters']
end

response = client.execute(:api_method => analytics.data.ga.get, :parameters => params)
results = Hash[response.data.rows]
```
So now we have a hash about query results.

### Calculate Page View

For each blog post, we want to display just the page view of that blog. However,
in blog index pages, we want to display the total page view of this site. So we
process `post` and `page` slightly differently.

Also, we'll set our generator's priority to `high`, in case other plugins also
want to use the `_pv` information.

```ruby
# total page view of this site
tot = 0

# display per post page view
site.posts.each { |post|
    url = (site.config['baseurl'] || '') + post.url + 'index.html'
    hits = (results[url])? results[url].to_i : 0
    post.data.merge!("_pv" => hits)
    tot += hits
}

# calculate total page view
site.pages.each { |page|
    url = (site.config['baseurl'] || '') + page.url
    hits = (results[url])? results[url].to_i : 0
    tot += hits
}

# display total page view in page
site.pages.each { |page|
    page.data.merge!("_pv" => tot)
}
```

So now each `post` or `page` contains one ore field, called `_pv`, which is the
page view count of that `post`, or total PV for `page`.

### Display Page View

This is done using a Liquid Tag called `PageViewTag`. In the `render` method, we
just output an nicely formatted page view count.

```ruby
site = context.environments.first['site']
if !site['page-view']
    return ''
end

post = context.environments.first['post']
if post == nil
    post = context.environments.first['page']
    if post == nil
        return ''
    end
end

pv = post['_pv']
if pv == nil
    return ''
end

html = pv.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse + ' hits'
return html
```


[octopress]: http://octopress.org/
[pv]: https://github.com/jhshi/octopress-page-view
[ga]: https://github.com/developmentseed/jekyll-ga
[analytics]: http://www.google.com/analytics/
[setup]: https://github.com/developmentseed/jekyll-ga#set-up-a-service-account-for-the-google-data-api
[generator]: http://jekyllrb.com/docs/plugins/
[tag]: http://jekyllrb.com/docs/plugins/
