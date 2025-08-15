-- Comment activity by repository and user
WITH comment_authors AS (
    SELECT 
        repo_name,
        number as pr_number,
        TRIM(UNNEST(STRING_SPLIT(comment_author_emails, ';'))) as commenter_email
    FROM pull_requests 
    WHERE comment_author_emails IS NOT NULL
    AND comment_author_emails != ''
)
SELECT 
    c.repo_name,
    u.primary_name as commenter_name,
    u.github_login,
    c.commenter_email,
    COUNT(*) as total_comments,
    COUNT(DISTINCT c.pr_number) as prs_commented_on,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT c.pr_number), 2) as avg_comments_per_pr
FROM comment_authors c
LEFT JOIN users u ON c.commenter_email = u.email
GROUP BY c.repo_name, c.commenter_email, u.primary_name, u.github_login
ORDER BY c.repo_name, total_comments DESC; 