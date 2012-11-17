These are some scripts that I use to help me monitor my google analytics output. They aren't intended for widespread use, but I have them here so I can share them with a couple of people that are interested in using them. It's all rather crude, but gets me the information I want quicker than clicking around the google analytics webapp.

Overview
========

The code is in two parts. 

- **Loader** is a set of ruby scripts that download analytics data from google and load up a sqlite database
- **webapp** is a simple sintra app that displays various bits of data from the database

My general philosophy is to do all the calculations as part of the loader, since this is all read-only data. As much as possible I use SQL to handle the various slicing and dicing, with ruby scripts to coordinate the loading process and fill in any gaps that the SQL can't handle.

Loader
=======

To get the loader going you'll need to create a folder called `data` in this directory. This folder will be ignored by git and will have your data in it. You will need to start by creating a file called `config.yaml` in the data directory to hold your specific config information for accessing google. This will look like this

    profile_id: 99999999
    auth_email: you@whereever.com
    start_day: 2011-09-01

- *auth_email* is the email or google id you use for logging into google analytics. 
- *profile_id* is the google analytics profile id you want to use. Finding this is a bit awkward, you need to go to your account settings and click through various account pages until you see a profile settings tab. Inside that tab is the profile ID - this is what you'll want to use.
- *start_day* is the day where you want to start downloading the analytics data from. It's good for it to be the first day of the first full month of data you have, so the first month doesn't look odd.

Once you have `config.yaml` in place, the next step is to get an authorization token to access the data from google. To do this use the task `rake auth`. This will use the auth_email, ask you for your google password, and then ask google analytics for an authorization token. It will write that authorization token into the data directory so other tasks can use it later. The token in written in the clear, but the consequences of losing it aren't too serious and you can always generate another one with another invocation of `rake auth`.

Once you have an authorization token you can then use `rake db` to download the google analytics data and load up the database. The scripts take the raw google data and store it all as files within the data directory, so you don't need to download them again. It then creates a sqlite database at `data/data.db` and loads it up with data from the downloaded text files and the results of various calculations. I like to keep the data directory in a (separate) git repo which I link into the analytics folder. I ignore `data.db` as it's large and easily regenerated, but I like to have my own copy of the raw google analytics data.

Webapp
=======

You can run the web app by starting a webserver in this folder. For example `thin start` will do the trick. It will then tell you where to point your browser to. I've added this folder as part of my laptop's apache setup, whatever works for you.

Currently the webapp has the following pages

- *tops:* shows the top 100 paths that have been recently accessed. This is sorted by recent median page views, which is the median of the last few weekdays pageviews for each path. The median column shows the median weekday page views for the prior month. The total column is the total number of page views for the prior month. The sparkline shows the median weekday page views for each month since the start date.

- *launches* shows what has happened to various paths since they were launched. To set this up you need to populate a file `data/launch-list.txt`. Each path goes on its own line like this

    /path/to/something.html           2012-09-21

The date is the date to start tracking from, usually the date you publish the article. The key on the page explains what the columns mean.

- *months:* shows summary data for each month since the site was launched. Median visits and views again refer to the median weekday value. (Since my site varies a good bit between weekday and weekend days, I prefer to focus on weekday activitiy). 

- *d3:* is a page I've been using to explore some d3 graphs. It may or may not work depending on how my explorations are going and whether I have much time to work with them.
