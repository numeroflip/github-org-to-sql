-- PR mergers
SELECT 
    repo_name,
    u.email as merged_by,
    COUNT(*) as merged_count,
    AVG(DATEDIFF('day', created_at, merged_at)) as avg_days_to_merge,
FROM pull_requests pr
left join users u on pr.merged_by_email = u.email
WHERE merged_by_email IS NOT NULL AND merged_at IS NOT NULL
GROUP BY repo_name, email 
ORDER BY repo_name, merged_count DESC; 