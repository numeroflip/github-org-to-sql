-- Users who create the most PRs (across all repositories)
SELECT 
    u.primary_name as pr_author_name,
    u.github_login,
    p.author_email,
    COUNT(*) as total_prs,
    COUNT(*) FILTER (WHERE p.state = 'MERGED') as merged_prs,
    COUNT(*) FILTER (WHERE p.state = 'OPEN') as open_prs,
    COUNT(*) FILTER (WHERE p.state = 'CLOSED') as closed_prs,
    ROUND(COUNT(*) FILTER (WHERE p.state = 'MERGED') * 100.0 / COUNT(*), 2) as merge_rate_percent,
    COUNT(DISTINCT p.repo_name) as repos_contributed_to
FROM pull_requests p
LEFT JOIN users u ON p.author_email = u.email
WHERE p.author_email IS NOT NULL
GROUP BY p.author_email, u.primary_name, u.github_login
ORDER BY total_prs DESC
LIMIT 20; 