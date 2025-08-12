-- Who creates the most PRs?
SELECT 
    author,
    COUNT(*) as pr_count,
    COUNT(DISTINCT repo_name) as repos_contributed_to,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as merged_prs,
    ROUND(COUNT(*) FILTER (WHERE merged_at IS NOT NULL) * 100.0 / COUNT(*), 2) as merge_rate_percent,
    AVG(DATEDIFF('day', created_at, COALESCE(merged_at, CURRENT_DATE))) as avg_days_open
FROM pull_requests 
WHERE author IS NOT NULL 
GROUP BY author 
ORDER BY pr_count DESC; 