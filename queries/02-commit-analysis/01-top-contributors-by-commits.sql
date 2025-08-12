-- Top contributors by commit count
SELECT 
    author_login,
    COUNT(*) as commit_count,
    COUNT(DISTINCT repo_name) as repos_contributed_to,
    MIN(date) as first_commit,
    MAX(date) as last_commit
FROM commits 
WHERE author_login IS NOT NULL
GROUP BY author_login 
ORDER BY commit_count DESC 
LIMIT 20; 