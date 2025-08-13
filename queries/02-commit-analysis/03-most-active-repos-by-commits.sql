-- Most active repositories by commits
SELECT 
    repo_name,
    COUNT(*) as commit_count,
    COUNT(DISTINCT author_login) as unique_contributors,
    MIN(date) as first_commit,
    MAX(date) as last_commit
FROM commits 
GROUP BY repo_name 
ORDER BY commit_count DESC 
LIMIT 15; 