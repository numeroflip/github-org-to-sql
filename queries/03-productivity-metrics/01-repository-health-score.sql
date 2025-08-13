-- Repository health score
WITH repo_metrics AS (
    SELECT 
        r.name,
        r.forks_count,
        COUNT(DISTINCT c.sha) as commit_count,
        COUNT(DISTINCT c.author_login) as contributor_count,
        COUNT(DISTINCT pr.number) as pr_count,
        COUNT(DISTINCT pr.number) FILTER (WHERE pr.merged_at IS NOT NULL) as merged_pr_count,
        COALESCE(AVG(DATEDIFF('day', pr.created_at, pr.merged_at)) FILTER (WHERE pr.merged_at IS NOT NULL), 0) as avg_merge_days
    FROM repos r
    LEFT JOIN commits c ON r.name = c.repo_name
    LEFT JOIN pull_requests pr ON r.name = pr.repo_name
    GROUP BY r.name, r.forks_count
)
SELECT 
    name,
    commit_count,
    contributor_count,
    pr_count,
    merged_pr_count,
    ROUND(avg_merge_days, 2) as avg_merge_days,
    -- Simple health score calculation
    ROUND(
        (LEAST(commit_count, 5000) / 50.0) +
        (LEAST(contributor_count, 100) * 2) +
        (CASE WHEN avg_merge_days > 0 AND avg_merge_days <= 7 THEN 20 
              WHEN avg_merge_days > 7 AND avg_merge_days <= 30 THEN 10 
              ELSE 5 END)
    , 2) as health_score
FROM repo_metrics
WHERE commit_count > 0
ORDER BY health_score DESC; 