-- GitHub Organization Analysis Queries
-- Run these with: duckdb github_org.db -c "QUERY_HERE"

-- ===========================================
-- REPOSITORY OVERVIEW
-- ===========================================

-- Top repositories by stars
SELECT 
    name,
    language,
    stargazers_count,
    forks_count,
    created_at
FROM repos 
ORDER BY stargazers_count DESC 
LIMIT 10;

-- Repository activity summary
SELECT 
    r.name,
    r.language,
    r.stargazers_count,
    COUNT(DISTINCT c.sha) as total_commits,
    COUNT(DISTINCT c.author_name) as unique_contributors,
    COUNT(DISTINCT pr.number) as total_prs,
    COUNT(DISTINCT pr.number) FILTER (WHERE pr.state = 'closed' AND pr.merged_at IS NOT NULL) as merged_prs
FROM repos r
LEFT JOIN commits c ON r.name = c.repo_name
LEFT JOIN pull_requests pr ON r.name = pr.repo_name
GROUP BY r.name, r.language, r.stargazers_count
ORDER BY total_commits DESC;

-- ===========================================
-- COMMIT ANALYSIS
-- ===========================================

-- Top contributors by commit count
SELECT 
    author_name,
    COUNT(*) as commit_count,
    COUNT(DISTINCT repo_name) as repos_contributed_to,
    MIN(date) as first_commit,
    MAX(date) as last_commit
FROM commits 
WHERE author_name IS NOT NULL
GROUP BY author_name 
ORDER BY commit_count DESC 
LIMIT 20;

-- Commit activity by month
SELECT 
    DATE_TRUNC('month', date) as month,
    COUNT(*) as commit_count,
    COUNT(DISTINCT author_name) as unique_authors,
    COUNT(DISTINCT repo_name) as active_repos
FROM commits 
WHERE date IS NOT NULL
GROUP BY month 
ORDER BY month DESC 
LIMIT 12;

-- Most active repositories by commits
SELECT 
    repo_name,
    COUNT(*) as commit_count,
    COUNT(DISTINCT author_name) as unique_contributors,
    MIN(date) as first_commit,
    MAX(date) as last_commit
FROM commits 
GROUP BY repo_name 
ORDER BY commit_count DESC 
LIMIT 15;

-- ===========================================
-- PULL REQUEST ANALYSIS
-- ===========================================

-- Who merges the most PRs?
SELECT 
    merged_by,
    COUNT(*) as merged_count,
    COUNT(DISTINCT repo_name) as repos_merged_in,
    AVG(DATEDIFF('day', created_at, merged_at)) as avg_days_to_merge
FROM pull_requests 
WHERE merged_by IS NOT NULL AND merged_at IS NOT NULL
GROUP BY merged_by 
ORDER BY merged_count DESC 
LIMIT 15;

-- PR authors and their success rates
SELECT 
    author,
    COUNT(*) as total_prs,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as merged_prs,
    COUNT(*) FILTER (WHERE state = 'closed' AND merged_at IS NULL) as closed_unmerged,
    COUNT(*) FILTER (WHERE state = 'open') as open_prs,
    ROUND(COUNT(*) FILTER (WHERE merged_at IS NOT NULL) * 100.0 / COUNT(*), 2) as merge_rate_percent
FROM pull_requests 
WHERE author IS NOT NULL
GROUP BY author 
HAVING COUNT(*) >= 5
ORDER BY total_prs DESC 
LIMIT 20;

-- Average time to merge by repository
SELECT 
    repo_name,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as merged_pr_count,
    ROUND(AVG(DATEDIFF('day', created_at, merged_at)), 2) as avg_days_to_merge,
    ROUND(AVG(DATEDIFF('hour', created_at, merged_at)), 2) as avg_hours_to_merge
FROM pull_requests 
WHERE merged_at IS NOT NULL AND created_at IS NOT NULL
GROUP BY repo_name 
HAVING merged_pr_count >= 5
ORDER BY avg_days_to_merge ASC;

-- ===========================================
-- ASSIGNEE AND REVIEWER ANALYSIS
-- ===========================================

-- Most assigned users (who gets assigned PRs the most)
WITH assignee_list AS (
    SELECT 
        repo_name,
        number,
        author,
        state,
        created_at,
        merged_at,
        UNNEST(STRING_SPLIT(assignees, ',')) as assignee
    FROM pull_requests 
    WHERE assignees IS NOT NULL AND assignees != ''
)
SELECT 
    assignee,
    COUNT(*) as assigned_pr_count,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as assigned_merged_count,
    COUNT(DISTINCT repo_name) as repos_assigned_in,
    ROUND(AVG(DATEDIFF('day', created_at, COALESCE(merged_at, NOW()))), 2) as avg_days_to_resolution
FROM assignee_list
WHERE assignee != ''
GROUP BY assignee
HAVING assigned_pr_count >= 3
ORDER BY assigned_pr_count DESC 
LIMIT 15;

-- Most requested reviewers
WITH reviewer_list AS (
    SELECT 
        repo_name,
        number,
        author,
        state,
        merged_at,
        UNNEST(STRING_SPLIT(requested_reviewers, ',')) as reviewer
    FROM pull_requests 
    WHERE requested_reviewers IS NOT NULL AND requested_reviewers != ''
)
SELECT 
    reviewer,
    COUNT(*) as review_requests,
    COUNT(DISTINCT repo_name) as repos_reviewed,
    COUNT(*) FILTER (WHERE merged_at IS NOT NULL) as reviewed_and_merged,
    ROUND(COUNT(*) FILTER (WHERE merged_at IS NOT NULL) * 100.0 / COUNT(*), 2) as merge_rate_percent
FROM reviewer_list
WHERE reviewer != ''
GROUP BY reviewer
HAVING review_requests >= 3
ORDER BY review_requests DESC 
LIMIT 15;

-- ===========================================
-- CROSS-REPOSITORY ANALYSIS
-- ===========================================

-- Contributors working across multiple repositories
SELECT 
    author_name,
    COUNT(DISTINCT repo_name) as repos_contributed_to,
    COUNT(*) as total_commits,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT repo_name), 2) as avg_commits_per_repo
FROM commits
WHERE author_name IS NOT NULL
GROUP BY author_name
HAVING repos_contributed_to >= 3
ORDER BY repos_contributed_to DESC, total_commits DESC;

-- Repository collaboration matrix (who works where)
SELECT 
    r.name as repository,
    r.language,
    COUNT(DISTINCT c.author_name) as commit_contributors,
    COUNT(DISTINCT pr.author) as pr_contributors,
    COUNT(DISTINCT c.sha) as total_commits,
    COUNT(DISTINCT pr.number) as total_prs
FROM repos r
LEFT JOIN commits c ON r.name = c.repo_name
LEFT JOIN pull_requests pr ON r.name = pr.repo_name
GROUP BY r.name, r.language
HAVING total_commits > 10
ORDER BY commit_contributors DESC;

-- ===========================================
-- TIME-BASED TRENDS
-- ===========================================

-- Activity comparison: commits vs PRs over time
WITH monthly_activity AS (
    SELECT 
        DATE_TRUNC('month', date) as month,
        COUNT(*) as commits,
        0 as pull_requests
    FROM commits 
    WHERE date IS NOT NULL
    GROUP BY month
    
    UNION ALL
    
    SELECT 
        DATE_TRUNC('month', created_at) as month,
        0 as commits,
        COUNT(*) as pull_requests
    FROM pull_requests 
    WHERE created_at IS NOT NULL
    GROUP BY month
)
SELECT 
    month,
    SUM(commits) as total_commits,
    SUM(pull_requests) as total_prs
FROM monthly_activity
GROUP BY month
ORDER BY month DESC
LIMIT 24;

-- ===========================================
-- PRODUCTIVITY METRICS
-- ===========================================

-- Repository health score
WITH repo_metrics AS (
    SELECT 
        r.name,
        r.stargazers_count,
        r.forks_count,
        COUNT(DISTINCT c.sha) as commit_count,
        COUNT(DISTINCT c.author_name) as contributor_count,
        COUNT(DISTINCT pr.number) as pr_count,
        COUNT(DISTINCT pr.number) FILTER (WHERE pr.merged_at IS NOT NULL) as merged_pr_count,
        COALESCE(AVG(DATEDIFF('day', pr.created_at, pr.merged_at)) FILTER (WHERE pr.merged_at IS NOT NULL), 0) as avg_merge_days
    FROM repos r
    LEFT JOIN commits c ON r.name = c.repo_name
    LEFT JOIN pull_requests pr ON r.name = pr.repo_name
    GROUP BY r.name, r.stargazers_count, r.forks_count
)
SELECT 
    name,
    stargazers_count,
    commit_count,
    contributor_count,
    pr_count,
    merged_pr_count,
    ROUND(avg_merge_days, 2) as avg_merge_days,
    -- Simple health score calculation
    ROUND(
        (LEAST(stargazers_count, 1000) / 10.0) +
        (LEAST(commit_count, 5000) / 50.0) +
        (LEAST(contributor_count, 100) * 2) +
        (CASE WHEN avg_merge_days > 0 AND avg_merge_days <= 7 THEN 20 
              WHEN avg_merge_days > 7 AND avg_merge_days <= 30 THEN 10 
              ELSE 5 END)
    , 2) as health_score
FROM repo_metrics
WHERE commit_count > 0
ORDER BY health_score DESC; 