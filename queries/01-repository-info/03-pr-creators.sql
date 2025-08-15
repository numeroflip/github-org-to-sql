-- PR creators
SELECT 
    repo_name,
    u.email as author_email,
    COUNT(*) as pr_count,
    ROUND(COUNT(*) FILTER (WHERE merged_at IS NOT NULL) * 100.0 / COUNT(*), 2) as merge_rate_percent,
    AVG(DATEDIFF('day', created_at, COALESCE(merged_at, CURRENT_DATE))) as avg_days_open
FROM pull_requests pr
LEFT JOIN users u on pr.author_email = u.email
GROUP BY repo_name, email 
ORDER BY repo_name, pr_count DESC;

-- PR creators by email domain 
SELECT 
    repo_name,
    split_part(u.email, '@', 2) as email_domain,
    COUNT(*) as pr_count,
    ROUND(COUNT(*) FILTER (WHERE merged_at IS NOT NULL) * 100.0 / COUNT(*), 2) as merge_rate_percent,
    AVG(DATEDIFF('day', created_at, COALESCE(merged_at, CURRENT_DATE))) as avg_days_open
FROM pull_requests pr
LEFT JOIN users u on pr.author_email = u.email
GROUP BY repo_name, split_part(u.email, '@', 2)
ORDER BY repo_name, pr_count DESC;