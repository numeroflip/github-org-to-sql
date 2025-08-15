-- PRs merged without reviewers by repository
SELECT 
    repo_name,
    COUNT(*) as total_merged_prs,
    COUNT(*) FILTER (WHERE state = 'MERGED' AND (requested_reviewer_emails IS NULL OR requested_reviewer_emails = '')) * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE state = 'MERGED'), 0) as pct_merged_without_reviewers,
    COUNT(*) FILTER (WHERE state = 'MERGED' AND (requested_reviewer_emails IS NULL OR requested_reviewer_emails = '')) as prs_merged_without_reviewers,
    COUNT(*) FILTER (WHERE state = 'MERGED' AND requested_reviewer_emails IS NOT NULL AND requested_reviewer_emails != '') as prs_merged_with_reviewers
FROM pull_requests 
WHERE state = 'MERGED'
GROUP BY repo_name 
ORDER BY pct_merged_without_reviewers DESC; 