-- PR creators
SELECT 
    repo_name,
    author as pr_author,
    COUNT(*) as pr_count,
    ROUND(COUNT(*) FILTER (WHERE merged_at IS NOT NULL) * 100.0 / COUNT(*), 2) as merge_rate_percent,
    AVG(DATEDIFF('day', created_at, COALESCE(merged_at, CURRENT_DATE))) as avg_days_open
FROM pull_requests 
GROUP BY repo_name, author 
ORDER BY repo_name, pr_count DESC;