-- PR metrics
WITH pr_approvals AS (
    SELECT 
        repo_name,
        pr_number,
        COUNT(*) FILTER (WHERE state = 'APPROVED') as approval_count
    FROM reviews
    GROUP BY repo_name, pr_number
),
pr_self_approvals AS (
    SELECT 
        pr.repo_name,
        pr.number as pr_number,
        COUNT(*) FILTER (WHERE r.state = 'APPROVED' AND r.reviewer = pr.author) as self_approval_count
    FROM pull_requests pr
    LEFT JOIN reviews r ON pr.repo_name = r.repo_name AND pr.number = r.pr_number
    GROUP BY pr.repo_name, pr.number, pr.author
),
big_pr_threshold AS (
    SELECT 800 as threshold_lines
),
pr_health_metrics AS (
    SELECT 
        pr.repo_name,
        COUNT(*) as total_prs,
        
        -- Size metrics
        COALESCE(AVG(pr.additions + pr.deletions), 0) as avg_line_changes,
        
        -- Comment metrics
        COALESCE(AVG(pr.comments), 0) as avg_comment_count,
        
        -- Big PR metrics
        COUNT(*) FILTER (
            WHERE (pr.additions + pr.deletions) > (SELECT threshold_lines FROM big_pr_threshold)
        ) as big_prs,
        
        -- Merge metrics
        COUNT(*) FILTER (WHERE pr.merged_at IS NOT NULL) as merged_prs,
        
        -- Approval metrics
        COUNT(*) FILTER (WHERE pa.approval_count > 0) as approved_prs,
        
        -- Self-approval metrics
        COUNT(*) FILTER (WHERE psa.self_approval_count > 0) as self_approved_prs,
        
        -- Merge without approval metrics
        COUNT(*) FILTER (
            WHERE pr.merged_at IS NOT NULL 
            AND (pa.approval_count IS NULL OR pa.approval_count = 0)
        ) as merged_without_approval
        
    FROM pull_requests pr
    LEFT JOIN pr_approvals pa ON pr.repo_name = pa.repo_name AND pr.number = pa.pr_number
    LEFT JOIN pr_self_approvals psa ON pr.repo_name = psa.repo_name AND pr.number = psa.pr_number
    WHERE pr.additions IS NOT NULL AND pr.deletions IS NOT NULL
    GROUP BY pr.repo_name
)
SELECT 
    r.name as repo_name,
    COALESCE(phm.total_prs, 0) as pr_count,
    COALESCE(ROUND(phm.avg_comment_count, 1), 0) as avg_comment_count,
    COALESCE(ROUND(phm.avg_line_changes, 0), 0) as avg_line_changes,
    CASE 
        WHEN phm.total_prs > 0 THEN ROUND((phm.big_prs * 100.0 / phm.total_prs), 1)
        ELSE 0
    END as big_change_pct,
    CASE 
        WHEN phm.total_prs > 0 THEN ROUND((phm.approved_prs * 100.0 / phm.total_prs), 1)
        ELSE 0
    END as approval_rate_pct,

    CASE 
        WHEN phm.total_prs > 0 THEN ROUND((phm.merged_prs * 100.0 / phm.total_prs), 1)
        ELSE 0
    END as merge_rate_pct,
    CASE 
        WHEN phm.merged_prs > 0 THEN ROUND((phm.merged_without_approval * 100.0 / phm.merged_prs), 1)
        ELSE 0
    END as merge_pct_without_approval
FROM repos r
LEFT JOIN pr_health_metrics phm ON r.name = phm.repo_name
ORDER BY 
    pr_count DESC,
    big_change_pct DESC,
    approval_rate_pct DESC,
    merge_rate_pct DESC;