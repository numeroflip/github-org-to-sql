-- Authors by repository and how many of their PRs were merged without reviews
SELECT 
    repo_name,
    author,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as total_merged_prs,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL AND (requested_reviewers IS NULL OR requested_reviewers = '')) as merged_without_review,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL AND requested_reviewers IS NOT NULL AND requested_reviewers != '') as merged_with_review,
    ROUND(
        COUNT(*) FILTER (WHERE merged_at IS NOT NULL AND (requested_reviewers IS NULL OR requested_reviewers = '')) * 100.0 / 
        NULLIF(COUNT(*) FILTER (WHERE merged_at IS NOT NULL), 0), 2
    ) as percent_merged_without_review
FROM pull_requests 
WHERE author IS NOT NULL
GROUP BY repo_name, author 
HAVING total_merged_prs > 0
ORDER BY repo_name, merged_without_review DESC, total_merged_prs DESC;