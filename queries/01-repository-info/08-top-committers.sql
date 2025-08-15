-- Top committers 
WITH commit_windows AS (
    SELECT
        repo_name,
        c.author_email,
        u.primary_name,
        COUNT(*) AS total_commits
    FROM commits c
    LEFT JOIN users u ON c.author_email = u.email
    WHERE c.author_email IS NOT NULL
    GROUP BY repo_name, c.author_email, u.primary_name, u.github_login
),
ranked_committers AS (
    SELECT
        repo_name,
        author_email,
        primary_name,
        total_commits,
        ROW_NUMBER() OVER (PARTITION BY repo_name ORDER BY total_commits DESC, author_email) AS rank
    FROM commit_windows
    WHERE total_commits > 0
)
SELECT
    repo_name,
    author_email,
    primary_name,
    total_commits
FROM ranked_committers
WHERE rank <= 3
ORDER BY repo_name, total_commits DESC;