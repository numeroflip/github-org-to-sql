-- Authors by repository and how many of their PRs were merged without reviews
SELECT 
    repo_name,
    u.primary_name as author_name,
    u.github_login,
    p.author_email,
    COUNT(*) as total_prs,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL AND (requested_reviewer_emails IS NULL OR requested_reviewer_emails = '')) as merged_without_review,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL AND requested_reviewer_emails IS NOT NULL AND requested_reviewer_emails != '') as merged_with_review,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as total_merged,
    ROUND(
        COUNT(*) FILTER (WHERE merged_at IS NOT NULL AND (requested_reviewer_emails IS NULL OR requested_reviewer_emails = '')) * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE merged_at IS NOT NULL), 0), 
        2
    ) as pct_merged_without_review
FROM pull_requests p
LEFT JOIN users u ON p.author_email = u.email
WHERE p.author_email IS NOT NULL
GROUP BY repo_name, p.author_email, u.primary_name, u.github_login
ORDER BY repo_name, total_merged DESC;