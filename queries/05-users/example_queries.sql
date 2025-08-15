--users 
select * from users
order by email asc

--users  with github login
select * from users
where github_login is not null
order by email asc

-- Users based on email domain
select 
  split_part(email, '@', 2) as email_domain,
  email,
  primary_name,
from users
group by split_part(email, '@', 2), primary_name, email
order by split_part(email, '@', 2) ASC

-- user count based on domain 
select 
  split_part(email, '@', 2) as email_domain,
  count(email) as count,
from users
group by split_part(email, '@', 2)
order by count(email) DESC 