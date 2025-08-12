-- Who merges the most PRs?
SELECT 
    merged_by,
    COUNT(*) as merged_count,
    AVG(DATEDIFF('day', created_at, merged_at)) as avg_days_to_merge
FROM pull_requests 
WHERE merged_by IS NOT NULL AND merged_at IS NOT NULL
GROUP BY merged_by 
ORDER BY merged_count DESC 
LIMIT 15; 