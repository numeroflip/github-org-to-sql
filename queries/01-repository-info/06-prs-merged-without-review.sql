-- PRs merged without review
SELECT 
    repo_name,
    COUNT(*) as prs_total,
    ROUND(
        COUNT(*) FILTER (WHERE state = 'MERGED' AND (requested_reviewers IS NULL OR requested_reviewers = '')) * 100.0 / 
        NULLIF(COUNT(*) FILTER (WHERE merged_at IS NOT NULL), 0), 2
    ) as percent_merged_without_reviewers,
    COUNT(*) FILTER (WHERE state = 'MERGED' AND (requested_reviewers IS NULL OR requested_reviewers = '')) as prs_merged_without_reviewers,
FROM pull_requests 
GROUP BY repo_name 
ORDER BY percent_merged_without_reviewers DESC; 