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

-- commits 
CREATE TABLE IF NOT EXISTS commits (
    repo_name VARCHAR NOT NULL,
    sha VARCHAR NOT NULL,
    author_login VARCHAR,
    committer_login VARCHAR,
    message TEXT,
    date TIMESTAMP,
    PRIMARY KEY (repo_name, sha)
);

-- pull requests
CREATE TABLE IF NOT EXISTS pull_requests (
    repo_name VARCHAR NOT NULL,
    number INTEGER NOT NULL,
    title VARCHAR,
    state VARCHAR,
    author VARCHAR,
    created_at TIMESTAMP,
    merged_at TIMESTAMP,
    merged_by VARCHAR,
    assignees VARCHAR,
    requested_reviewers VARCHAR, 
    comments INTEGER,
    additions INTEGER,
    deletions INTEGER,
    comment_authors VARCHAR,
    PRIMARY KEY (repo_name, number)
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
-- ------------LOAD DATA --------------------------
-- -------------------------------------------------
.mode csv

DELETE FROM repos;
COPY repos FROM 'data/repos.csv' (HEADER);

DELETE FROM commits;
COPY commits FROM 'data/commits.csv' (HEADER);

DELETE FROM pull_requests;
COPY pull_requests FROM 'data/pull_requests.csv' (HEADER);

DELETE FROM reviews;
COPY reviews FROM 'data/reviews.csv' (HEADER);



-- -------------------------------------------------
-- ------------CREATE INDEXES ---------------------
-- -------------------------------------------------

-- commits
CREATE INDEX IF NOT EXISTS idx_commits_repo_name ON commits(repo_name);
CREATE INDEX IF NOT EXISTS idx_commits_author_login ON commits(author_login);
CREATE INDEX IF NOT EXISTS idx_commits_committer_login ON commits(committer_login);
CREATE INDEX IF NOT EXISTS idx_commits_date ON commits(date);

-- pull requests
CREATE INDEX IF NOT EXISTS idx_pull_requests_repo_name ON pull_requests(repo_name);
CREATE INDEX IF NOT EXISTS idx_pull_requests_author ON pull_requests(author);
CREATE INDEX IF NOT EXISTS idx_pull_requests_merged_by ON pull_requests(merged_by);
CREATE INDEX IF NOT EXISTS idx_pull_requests_state ON pull_requests(state);
CREATE INDEX IF NOT EXISTS idx_pull_requests_created_at ON pull_requests(created_at);

-- reviews
CREATE INDEX IF NOT EXISTS idx_reviews_repo_pr ON reviews(repo_name, pr_number);
CREATE INDEX IF NOT EXISTS idx_reviews_state ON reviews(state);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON reviews(reviewer);


-- -------------------------------------------------
-- ------------SUMMARY ---------------------------
-- -------------------------------------------------

-- Configure output format
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
SELECT '  • [' || repo_name || '] ' || author_login || ': ' || LEFT(message, 40) || '...'
FROM commits 
ORDER BY date DESC 
LIMIT 5;

.print ""

-- Sample pull requests  
.print "[PULL_REQUESTS] Recent pull requests:"
SELECT '  • [' || repo_name || '] #' || number || ' by ' || author || ' (' || state || ')'
FROM pull_requests 
ORDER BY created_at DESC 
LIMIT 5;

.print ""
.print "================================================="
.print "[INFO] Setup complete! Ready to run queries."
.print "================================================="

-- Reset headers for any subsequent operations
.headers on