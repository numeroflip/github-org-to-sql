-- Users who merge the most PRs (across all repositories)
SELECT 
    u.primary_name as merger_name,
    u.github_login,
    p.merged_by_email,
    COUNT(*) as total_merges,
    COUNT(DISTINCT p.repo_name) as repos_merged_in,
    AVG(DATEDIFF('day', p.created_at, p.merged_at)) as avg_days_to_merge,
    MIN(p.merged_at) as first_merge,
    MAX(p.merged_at) as latest_merge
FROM pull_requests p
LEFT JOIN users u ON p.merged_by_email = u.email
WHERE p.merged_by_email IS NOT NULL AND p.merged_at IS NOT NULL
GROUP BY p.merged_by_email, u.primary_name, u.github_login
ORDER BY total_merges DESC
LIMIT 20; 