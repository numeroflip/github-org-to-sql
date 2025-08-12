-- PR reviewers
WITH review_requests AS (
    SELECT 
        repo_name,
        TRIM(reviewer) as reviewer,
        COUNT(*) as review_requests_count
    FROM (
        SELECT 
            repo_name,
            UNNEST(string_split(requested_reviewers, ',')) as reviewer
        FROM pull_requests 
        WHERE requested_reviewers IS NOT NULL
    )
    WHERE TRIM(reviewer) != ''
    GROUP BY repo_name, TRIM(reviewer)
),
review_stats AS (
    SELECT 
        repo_name,
        reviewer,
        COUNT(CASE WHEN state = 'APPROVED' THEN 1 END) as approvals_count,
        COUNT(CASE WHEN state = 'CHANGES_REQUESTED' THEN 1 END) as changes_requested_count,
        COUNT(CASE WHEN state = 'COMMENTED' THEN 1 END) as comments_count,
        COUNT(CASE WHEN state = 'DISMISSED' THEN 1 END) as dismissed_count,
        COUNT(*) as total_reviews_count
    FROM reviews
    WHERE reviewer IS NOT NULL
    GROUP BY repo_name, reviewer
)
SELECT 
    COALESCE(rr.repo_name, rs.repo_name) as repo_name,
    COALESCE(rr.reviewer, rs.reviewer) as reviewer,
    COALESCE(rr.review_requests_count, 0) as review_requests_count,
    COALESCE(rs.approvals_count, 0) as ✅_approvals,
    COALESCE(rs.changes_requested_count, 0) as ❌_changes_requested,
    COALESCE(rs.comments_count, 0) as 💬_comments,
    COALESCE(rs.dismissed_count, 0) as 🚫_dismissed,
    COALESCE(rs.total_reviews_count, 0) as total_reviews_count
FROM review_requests rr
FULL OUTER JOIN review_stats rs 
    ON rr.repo_name = rs.repo_name AND rr.reviewer = rs.reviewer
ORDER BY repo_name, total_reviews_count DESC, ✅_approvals DESC;