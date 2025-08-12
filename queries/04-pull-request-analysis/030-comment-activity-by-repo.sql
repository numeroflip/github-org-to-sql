-- Who comments the most PRs by repository?
WITH comment_authors AS (
    SELECT 
        repo_name,
        number as pr_number,
        TRIM(UNNEST(STRING_SPLIT(comment_authors, ';'))) as commenter
    FROM pull_requests 
    WHERE comment_authors IS NOT NULL 
    AND comment_authors != ''
),
unique_commenters AS (
    SELECT DISTINCT
        repo_name,
        pr_number,
        commenter
    FROM comment_authors
    WHERE commenter != ''
),
repo_pr_counts AS (
    SELECT 
        repo_name,
        COUNT(DISTINCT number) as total_prs_in_repo
    FROM pull_requests
    GROUP BY repo_name
)
SELECT 
    uc.repo_name,
    uc.commenter,
    COUNT(DISTINCT uc.pr_number) as prs_commented_on,
    rpc.total_prs_in_repo,
    ROUND(COUNT(DISTINCT uc.pr_number) * 100.0 / rpc.total_prs_in_repo, 2) as percent_of_prs_commented
FROM unique_commenters uc
JOIN repo_pr_counts rpc ON uc.repo_name = rpc.repo_name
GROUP BY uc.repo_name, uc.commenter, rpc.total_prs_in_repo
ORDER BY uc.repo_name, prs_commented_on DESC; 