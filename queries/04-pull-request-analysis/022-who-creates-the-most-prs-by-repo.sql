-- Top PR creators by repository (detailed breakdown)
SELECT 
    repo_name,
    u.primary_name as pr_author_name,
    u.github_login,
    p.author_email,
    COUNT(*) as prs_in_repo,
    COUNT(*) FILTER (WHERE p.state = 'MERGED') as merged_in_repo,
    COUNT(*) FILTER (WHERE p.state = 'OPEN') as open_in_repo,
    ROUND(COUNT(*) FILTER (WHERE p.state = 'MERGED') * 100.0 / COUNT(*), 2) as merge_rate_in_repo_percent,
    AVG(p.comments) as avg_comments_per_pr,
    MIN(p.created_at) as first_pr_in_repo,
    MAX(p.created_at) as latest_pr_in_repo
FROM pull_requests p
LEFT JOIN users u ON p.author_email = u.email
WHERE p.author_email IS NOT NULL
GROUP BY repo_name, p.author_email, u.primary_name, u.github_login
ORDER BY repo_name, prs_in_repo DESC; 