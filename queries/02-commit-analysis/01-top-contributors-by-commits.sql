-- Top contributors by commit count
SELECT 
    u.email,
    u.primary_name as name,
    COUNT(*) as commit_count,
    COUNT(DISTINCT repo_name) as repos_contributed_to,
    MIN(date) as first_commit,
    MAX(date) as last_commit
FROM commits c
LEFT join users u on c.author_email = u.email 
WHERE author_email IS NOT NULL
GROUP BY email, primary_name
ORDER BY commit_count DESC 
LIMIT 20; 

-- Top contributors by commit count -- by email domain
SELECT 
    split_part(u.email, '@', 2) as email_domain,
    COUNT(*) as commit_count,
    COUNT(DISTINCT repo_name) as repos_contributed_to,
    MIN(date) as first_commit,
    MAX(date) as last_commit
FROM commits c
LEFT join users u on c.author_email = u.email 
WHERE author_email IS NOT NULL
GROUP BY split_part(u.email, '@', 2)
ORDER BY commit_count DESC 
LIMIT 20; 