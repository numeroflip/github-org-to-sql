-- Active Contributors - (Last 30 Days)
-- Shows all contributors across commits, PRs, merges, and reviews who were active in the last 30 days
WITH recent_committers AS (
    SELECT 
        author_login as contributor,
        'Committer' as role_type,
        COUNT(*) as activity_count,
        COUNT(DISTINCT repo_name) as repos_count,
        MIN(date) as first_activity,
        MAX(date) as last_activity
    FROM commits 
    WHERE author_login IS NOT NULL 
        AND author_login != ''
        AND date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY author_login
),
recent_pr_creators AS (
    SELECT 
        author as contributor,
        'PR Creator' as role_type,
        COUNT(*) as activity_count,
        COUNT(DISTINCT repo_name) as repos_count,
        MIN(created_at) as first_activity,
        MAX(created_at) as last_activity
    FROM pull_requests 
    WHERE author IS NOT NULL 
        AND author != ''
        AND created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY author
),
recent_pr_mergers AS (
    SELECT 
        merged_by as contributor,
        'PR Merger' as role_type,
        COUNT(*) as activity_count,
        COUNT(DISTINCT repo_name) as repos_count,
        MIN(merged_at) as first_activity,
        MAX(merged_at) as last_activity
    FROM pull_requests 
    WHERE merged_by IS NOT NULL 
        AND merged_by != ''
        AND merged_at IS NOT NULL
        AND merged_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY merged_by
),
recent_reviewers AS (
    SELECT 
        reviewer as contributor,
        'Reviewer' as role_type,
        COUNT(*) as activity_count,
        COUNT(DISTINCT repo_name) as repos_count,
        MIN(submitted_at) as first_activity,
        MAX(submitted_at) as last_activity
    FROM reviews 
    WHERE reviewer IS NOT NULL 
        AND reviewer != ''
        AND submitted_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY reviewer
),
all_recent_activities AS (
    SELECT * FROM recent_committers
    UNION ALL
    SELECT * FROM recent_pr_creators
    UNION ALL
    SELECT * FROM recent_pr_mergers
    UNION ALL
    SELECT * FROM recent_reviewers
),
contributor_summary AS (
    SELECT 
        contributor,
        STRING_AGG(DISTINCT role_type, ', ' ORDER BY role_type) as roles,
        COUNT(DISTINCT role_type) as role_count,
        SUM(activity_count) as total_activity_last_30_days,
        SUM(repos_count) as total_repo_interactions,
        MIN(first_activity) as earliest_activity_last_30_days,
        MAX(last_activity) as latest_activity_last_30_days,
        DATEDIFF('day', MIN(first_activity), MAX(last_activity)) as days_active_span
    FROM all_recent_activities
    GROUP BY contributor
),
detailed_stats AS (
    SELECT 
        cs.*,
        COALESCE(rc.activity_count, 0) as commits_last_30_days,
        COALESCE(rpc.activity_count, 0) as prs_created_last_30_days,
        COALESCE(rpm.activity_count, 0) as prs_merged_last_30_days,
        COALESCE(rr.activity_count, 0) as reviews_last_30_days
    FROM contributor_summary cs
    LEFT JOIN recent_committers rc ON cs.contributor = rc.contributor
    LEFT JOIN recent_pr_creators rpc ON cs.contributor = rpc.contributor
    LEFT JOIN recent_pr_mergers rpm ON cs.contributor = rpm.contributor
    LEFT JOIN recent_reviewers rr ON cs.contributor = rr.contributor
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY total_activity_last_30_days DESC, latest_activity_last_30_days DESC) as idx,
    contributor,
    roles,
    role_count,
    -- commits_last_30_days,
    -- prs_created_last_30_days,
    -- prs_merged_last_30_days,
    -- reviews_last_30_days,
    -- total_activity_last_30_days,
    -- total_repo_interactions,
    earliest_activity_last_30_days,
    latest_activity_last_30_days,
    -- days_active_span,
    CASE 
        WHEN latest_activity_last_30_days >= CURRENT_DATE - INTERVAL '7 days' THEN '🟢 Very Active (Last Week)'
        WHEN latest_activity_last_30_days >= CURRENT_DATE - INTERVAL '14 days' THEN '🟡 Active (Last 2 Weeks)'
        ELSE '🟠 Active (Last 30 Days)'
    END as activity_level
FROM detailed_stats
WHERE total_activity_last_30_days > 0
ORDER BY total_activity_last_30_days DESC, latest_activity_last_30_days DESC;