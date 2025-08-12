-- Top committers 
WITH commit_windows AS (
    SELECT
        repo_name,
        author_login,
        COUNT(*) AS total_commits,
    FROM commits
    WHERE author_login IS NOT NULL
    GROUP BY repo_name, author_login
),
ranked_committers AS (
    SELECT
        repo_name,
        author_login,
        total_commits,
        ROW_NUMBER() OVER (PARTITION BY repo_name ORDER BY total_commits DESC, author_login) AS rank
    FROM commit_windows
    WHERE total_commits > 0
)
SELECT
    repo_name,
    author_login,
    total_commits
FROM ranked_committers
WHERE rank <= 3
ORDER BY repo_name, total_commits DESC; 