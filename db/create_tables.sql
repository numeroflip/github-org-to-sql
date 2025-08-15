-- GitHub Organization DuckDB Database Creation Script
-- Run with: duckdb github_org.db < create_tables.sql


-- -------------------------------------------------
-- ------------ CREATE TABLES ----------------------
-- -------------------------------------------------

-- repositories
CREATE TABLE IF NOT EXISTS repos (
    name VARCHAR NOT NULL,
    full_name VARCHAR NOT NULL PRIMARY KEY,
    description VARCHAR,
    language VARCHAR,
    stargazers_count INTEGER,
    forks_count INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    url VARCHAR
);

-- users
CREATE TABLE IF NOT EXISTS users (
    email VARCHAR PRIMARY KEY,
    primary_name VARCHAR NOT NULL,
    github_login VARCHAR UNIQUE,
    all_names VARCHAR
);

-- commits
CREATE TABLE IF NOT EXISTS commits (
    repo_name VARCHAR NOT NULL,
    sha VARCHAR NOT NULL,
    author_email VARCHAR,
    committer_email VARCHAR,
    message TEXT,
    date TIMESTAMP,
    PRIMARY KEY (repo_name, sha),
    FOREIGN KEY (author_email) REFERENCES users(email),
    FOREIGN KEY (committer_email) REFERENCES users(email)
);

-- pull requests
CREATE TABLE IF NOT EXISTS pull_requests (
    repo_name VARCHAR NOT NULL,
    number INTEGER NOT NULL,
    title VARCHAR,
    state VARCHAR,
    author_email VARCHAR,
    created_at TIMESTAMP,
    merged_at TIMESTAMP,
    merged_by_email VARCHAR,
    assignee_emails VARCHAR,
    requested_reviewer_emails VARCHAR, 
    comments INTEGER,
    additions INTEGER,
    deletions INTEGER,
    comment_author_emails VARCHAR,
    PRIMARY KEY (repo_name, number),
    FOREIGN KEY (author_email) REFERENCES users(email),
    FOREIGN KEY (merged_by_email) REFERENCES users(email)
);

-- reviews 
CREATE TABLE IF NOT EXISTS reviews (
    repo_name VARCHAR NOT NULL,
    pr_number INTEGER NOT NULL,
    reviewer VARCHAR NOT NULL,
    state VARCHAR NOT NULL, -- APPROVED, CHANGES_REQUESTED, COMMENTED, DISMISSED
    submitted_at TIMESTAMP,
    PRIMARY KEY (repo_name, pr_number, reviewer, submitted_at),
    FOREIGN KEY (repo_name, pr_number) REFERENCES pull_requests(repo_name, number)
);


-- -------------------------------------------------
-- ------------INDEXES -----------------------------
-- -------------------------------------------------

-- commits
CREATE INDEX IF NOT EXISTS idx_commits_repo_name ON commits(repo_name);
CREATE INDEX IF NOT EXISTS idx_commits_author_email ON commits(author_email);
CREATE INDEX IF NOT EXISTS idx_commits_committer_email ON commits(committer_email);
CREATE INDEX IF NOT EXISTS idx_commits_date ON commits(date);

-- pull requests
CREATE INDEX IF NOT EXISTS idx_pull_requests_repo_name ON pull_requests(repo_name);
CREATE INDEX IF NOT EXISTS idx_pull_requests_author_email ON pull_requests(author_email);
CREATE INDEX IF NOT EXISTS idx_pull_requests_merged_by_email ON pull_requests(merged_by_email);
CREATE INDEX IF NOT EXISTS idx_pull_requests_created_at ON pull_requests(created_at);

-- reviews
CREATE INDEX IF NOT EXISTS idx_reviews_repo_pr ON reviews(repo_name, pr_number);
CREATE INDEX IF NOT EXISTS idx_reviews_state ON reviews(state);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON reviews(reviewer);

-- users
CREATE INDEX IF NOT EXISTS idx_users_github_login ON users(github_login);

-- -------------------------------------------------
-- ------------LOAD DATA --------------------------
-- -------------------------------------------------
.mode csv

DELETE FROM repos;
COPY repos FROM 'data/repos.csv' (HEADER);

DELETE FROM users;
COPY users FROM 'data/users.csv' (HEADER);

DELETE FROM commits;
COPY commits FROM 'data/commits.csv' (HEADER);

DELETE FROM pull_requests;
COPY pull_requests FROM 'data/pull_requests.csv' (HEADER);

DELETE FROM reviews;
COPY reviews FROM 'data/reviews.csv' (HEADER);



-- -------------------------------------------------
-- ------------SUMMARY -----------------------------
-- -------------------------------------------------
.headers off
.mode list

.print ""
.print "================================================="
.print "[INFO] Database Creation Complete!"
.print "================================================="
.print ""

-- Use individual SELECT statements for counts
.print "[SUMMARY] Data loaded:"
SELECT '  Repositories: ' || COUNT(*) FROM repos;
SELECT '  Commits: ' || COUNT(*) FROM commits;  
SELECT '  Pull requests: ' || COUNT(*) FROM pull_requests;
SELECT '  Reviews: ' || COUNT(*) FROM reviews;
SELECT '  Users: ' || COUNT(*) FROM users;

.print ""
.print "----- SAMPLE DATA -----"
.print ""

-- Sample repositories
.print "[REPOS] Sample repositories:"
SELECT '  • ' || name || ' (' || COALESCE(language, 'Unknown') || ') - ' || stargazers_count || ' stars, ' || forks_count || ' forks'
FROM repos 
ORDER BY stargazers_count DESC 
LIMIT 5;

.print ""

-- Sample commits
.print "[COMMITS] Recent commits:"
SELECT '  • [' || repo_name || '] ' || author_email || ': ' || LEFT(message, 40) || '...'
FROM commits 
ORDER BY date DESC 
LIMIT 5;

-- Sample users 
.print ""
.print "[USERS] Sample users:"
SELECT '  • ' || email || ' (' || primary_name || ')'
FROM users 
ORDER BY email 
LIMIT 5;
