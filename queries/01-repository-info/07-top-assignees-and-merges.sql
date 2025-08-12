-- PR assignees
WITH assignee_list AS (
    SELECT 
        repo_name,
        number,
        author,
        state,
        created_at,
        merged_at,
        merged_by,
        UNNEST(STRING_SPLIT(assignees, ',')) as assignee
    FROM pull_requests 
    WHERE assignees IS NOT NULL AND assignees != ''
),
assignee_stats AS (
    SELECT 
        repo_name,
        assignee,
        COUNT(*) as assigned_pr_count,
        COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as assigned_merged_count,
        COUNT(*) FILTER (WHERE state = 'open') as assigned_open_count,
        ROUND(COUNT(*) FILTER (WHERE merged_at IS NOT NULL) * 100.0 / COUNT(*), 2) as assigned_merge_rate_percent
    FROM assignee_list
    WHERE assignee != ''
    GROUP BY repo_name, assignee
),
merger_stats AS (
    SELECT 
        repo_name,
        merged_by,
        COUNT(*) as total_merged_count
    FROM pull_requests 
    WHERE merged_by IS NOT NULL AND merged_at IS NOT NULL
    GROUP BY repo_name, merged_by
)
SELECT 
    a.repo_name,
    a.assignee,
    a.assigned_pr_count,
    a.assigned_merged_count,
    a.assigned_open_count,
    a.assigned_merge_rate_percent,
    COALESCE(m.total_merged_count, 0) as total_prs_merged_by_them
FROM assignee_stats a
LEFT JOIN merger_stats m ON a.repo_name = m.repo_name AND a.assignee = m.merged_by
WHERE a.assigned_pr_count >= 1
ORDER BY a.repo_name, a.assigned_pr_count DESC; 