-- PR Quality Metrics - Using available data from pull_requests table
WITH pr_metrics AS (
    SELECT 
        repo_name,
        COUNT(*) as total_prs,
        COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as merged_prs,
        COUNT(*) FILTER (WHERE (additions + deletions) > 1000) as large_prs_count,
        COUNT(*) FILTER (WHERE requested_reviewer_emails IS NOT NULL AND requested_reviewer_emails != '') as prs_with_reviewers,
        COUNT(*) FILTER (WHERE comments = 0) as prs_with_no_comments,
        COALESCE(AVG(DATEDIFF('day', created_at, merged_at)) FILTER (WHERE merged_at IS NOT NULL), 0) as avg_merge_time_days,
        COALESCE(AVG(additions + deletions) FILTER (WHERE additions IS NOT NULL AND deletions IS NOT NULL), 0) as avg_pr_size,
        COALESCE(AVG(comments), 0) as avg_comments_per_pr
    FROM pull_requests 
    WHERE additions IS NOT NULL AND deletions IS NOT NULL
    GROUP BY repo_name
)
SELECT 
    repo_name,
    
    -- Metric 1: PR Merge Rate (proxy for acceptance quality)
    CASE 
        WHEN total_prs > 0 
        THEN ROUND((merged_prs * 100.0 / total_prs), 1)
        ELSE 0 
    END as pr_merge_rate_percent,
    
    -- Metric 2: PR Cycle Time (velocity indicator)
    ROUND(avg_merge_time_days, 1) as avg_merge_time_days,
    
    -- Metric 3: Reviewer Assignment Rate (process adherence)
    CASE 
        WHEN total_prs > 0 
        THEN ROUND((prs_with_reviewers * 100.0 / total_prs), 1)
        ELSE 0 
    END as reviewer_assignment_rate_percent,
    
    -- Metric 4: Reasonable Size PRs (reviewability)
    CASE 
        WHEN total_prs > 0 
        THEN ROUND(((total_prs - large_prs_count) * 100.0 / total_prs), 1)
        ELSE 0 
    END as reasonable_size_prs_percent,
    
    -- Metric 5: Discussion Engagement (comments per PR)
    ROUND(avg_comments_per_pr, 1) as avg_comments_per_pr,
    
    -- Metric 6: Silent Merge Rate (PRs merged without discussion)
    CASE 
        WHEN merged_prs > 0 
        THEN ROUND((prs_with_no_comments * 100.0 / merged_prs), 1)
        ELSE 0 
    END as silent_merge_rate_percent,
    
    -- Supporting data
    total_prs,
    merged_prs,
    ROUND(avg_pr_size, 0) as avg_pr_size_lines,
    large_prs_count as large_prs_over_1000_lines
    
FROM pr_metrics
WHERE total_prs > 0
ORDER BY 
    pr_merge_rate_percent DESC,
    avg_merge_time_days ASC;