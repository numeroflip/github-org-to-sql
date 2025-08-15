-- Repository activity summary with commit and PR metrics
SELECT 
    r.name as repository,
    r.language,
    COUNT(DISTINCT u.email) as unique_contributors,
    COUNT(c.sha) as total_commits,
    COUNT(pr.number) as total_pull_requests,
    ROUND(COALESCE(AVG(pr.comments), 0), 2) as avg_pr_comments,
    r.stargazers_count,
    r.forks_count
FROM repos r
LEFT JOIN commits c ON r.name = c.repo_name
LEFT JOIN users u ON c.author_email = u.email
LEFT JOIN pull_requests pr ON r.name = pr.repo_name
GROUP BY r.name, r.language, r.stargazers_count, r.forks_count
ORDER BY total_commits DESC;