-- PRs - Content Analysis
WITH pr_content_metrics AS (
    SELECT 
        repo_name,
        COUNT(*) as total_prs,
        
        -- Size categories
        COUNT(*) FILTER (WHERE (additions + deletions) <= 200) as small_prs,
        COUNT(*) FILTER (WHERE (additions + deletions) > 1000) as huge_prs,
        
        -- Code change characteristics
        COALESCE(AVG(additions + deletions), 0) as avg_total_changes,
        COALESCE(MEDIAN(additions + deletions), 0) as median_total_changes,
        COALESCE(AVG(additions), 0) as avg_lines_added,
        COALESCE(AVG(deletions), 0) as avg_lines_deleted,
        
        -- Change type analysis
        COUNT(*) FILTER (WHERE deletions > 0 AND additions = 0) as deletion_only_prs,
        COUNT(*) FILTER (WHERE additions > 0 AND deletions = 0) as addition_only_prs,
        
        -- Success rate
        COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as merged_prs
        
    FROM pull_requests 
    WHERE additions IS NOT NULL AND deletions IS NOT NULL
    GROUP BY repo_name
)
SELECT 
    repo_name,
    total_prs,
    ROUND(avg_total_changes, 0) as avg_lines_changed,
    ROUND(median_total_changes, 0) as median_lines_changed,
    ROUND((small_prs * 100.0 / total_prs), 1) as small_pr_percent,
    ROUND((huge_prs * 100.0 / total_prs), 1) as huge_pr_percent,
    ROUND((addition_only_prs * 100.0 / total_prs), 1) as new_code_percent,
    ROUND((merged_prs * 100.0 / total_prs), 1) as merge_rate_percent,
    
FROM pr_content_metrics
WHERE total_prs > 5
ORDER BY 
    avg_lines_changed ASC,
    small_pr_percent DESC;