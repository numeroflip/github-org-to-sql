-- Commit activity by month
SELECT 
    DATE_TRUNC('month', date) as month,
    COUNT(*) as commit_count,
    COUNT(DISTINCT author_login) as unique_authors,
    COUNT(DISTINCT repo_name) as active_repos
FROM commits 
WHERE date IS NOT NULL
GROUP BY month 
ORDER BY month DESC 
LIMIT 12; 