-- Activity summary
SELECT 
    r.name,
    r.language,
    COUNT(DISTINCT c.sha) as total_commits,
    COUNT(DISTINCT c.author_login) as unique_contributors,
    COUNT(DISTINCT pr.number) as total_prs,
    COUNT(DISTINCT pr.number) FILTER (WHERE pr.state = 'MERGED' AND pr.merged_at IS NOT NULL) as merged_prs
FROM repos r
LEFT JOIN commits c ON r.name = c.repo_name
LEFT JOIN pull_requests pr ON r.name = pr.repo_name
GROUP BY r.name, r.language
ORDER BY r.name DESC; 