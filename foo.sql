select path, sum(views) from pageviews 
  where month = 1 
  group by path
  order by sum(views) desc
  limit 10;
  ;