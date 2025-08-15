-- Top PR mergers by repository (detailed breakdown)
SELECT 
    repo_name,
    u.primary_name as merger_name,
    u.github_login,
    p.merged_by_email,
    COUNT(*) as merges_in_repo,
    AVG(DATEDIFF('day', p.created_at, p.merged_at)) as avg_days_to_merge,
    MIN(p.merged_at) as first_merge_in_repo,
    MAX(p.merged_at) as latest_merge_in_repo
FROM pull_requests p
LEFT JOIN users u ON p.merged_by_email = u.email
WHERE p.merged_by_email IS NOT NULL AND p.merged_at IS NOT NULL
GROUP BY repo_name, p.merged_by_email, u.primary_name, u.github_login
ORDER BY repo_name, merges_in_repo DESC; 