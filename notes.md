Progression of complex sql

            select path, views from launches join pageviews using (path);

            select path, views from launches join (select * from pageviews) using (path);

            select path, views, v.date from launches 
                   join (select * from pageviews) as v 
                   using (path);
 

This failed

     select path, views, v.date, launches.date from launches 
       join (
            select * from pageviews
            where v.date == launches.date
       ) as v 
       using (path);

since we can't reference launches.date inside the join query

This also failed (by mistake used "==")

     select path, views, v.date, launches.date from launches 
       join (
            select * from pageviews
       ) as v 
       using (path)
       where v.date == launches.date
       ;      

so I tried a simpler where clause which worked

     select path, views, v.date, launches.date from launches 
       join (
            select * from pageviews
       ) as v 
       using (path)
       where path = '/articles/multiMobile/'
       ;

At this point I'm not really using the dynamic query to get rid of it

        select path, views, v.date, launches.date from launches 
           join pageviews as v using (path)
           where path = '/articles/multiMobile/'
       ;
       
    select path, views, v.date, l.date 
           from launches as l join pageviews as v using (path)
           where path = '/articles/multiMobile/'
           ;

I now realized the proper expression

    select path, views, v.date, l.date 
           from launches as l join pageviews as v using (path)
           where v.date = l.date
           ;


this got empty output

    select path, views, v.date, l.date 
           from launches as l join pageviews as v using (path)
           where v.date between l.date and date(l.date,' + 7 days')
           ;
       
tried something simpler but still no output

    select path, views, v.date, l.date 
           from launches as l join pageviews as v using (path)
           where v.date = date(l.date,' + 7 days')
           ;

to try to see what was going on I tried

    select path, views, v.date, l.date, date(l.date, '+ 7 days')
           from launches as l join pageviews as v using (path)
           where v.date = '2012-07-01'
           ;

the computed field was blank (null, I assume)       

this worked for display

    select path, views, v.date, l.date, date(l.date, '+7 day')
           from launches as l join pageviews as v using (path)
           where v.date = '2012-07-01'
           ;

notice s/days/day/ and s/+ 7/+7/    also must remove leading space in date function modifer

so now this worked

    select path, views, v.date, l.date, date(l.date, '+7 day')
           from launches as l join pageviews as v using (path)
           where v.date between l.date and date(l.date,'+7 day')        
           ;


   
