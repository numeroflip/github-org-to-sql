-- GitHub Organization DuckDB Database Creation Script
-- Run with: duckdb github_org.db < create_tables.sql

-- Create repositories table
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

-- Create commits table
CREATE TABLE IF NOT EXISTS commits (
    repo_name VARCHAR NOT NULL,
    sha VARCHAR NOT NULL,
    author_name VARCHAR,
    author_email VARCHAR,
    committer_name VARCHAR,
    committer_email VARCHAR,
    message TEXT,
    date TIMESTAMP,
    PRIMARY KEY (repo_name, sha)
);

-- Create pull requests table
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
    PRIMARY KEY (repo_name, number)
);

-- Load data from CSV files
.mode csv

-- Load repositories
DELETE FROM repos;
COPY repos FROM 'data/repos.csv' (HEADER);

-- Load commits
DELETE FROM commits;
COPY commits FROM 'data/commits.csv' (HEADER);

-- Load pull requests
DELETE FROM pull_requests;
COPY pull_requests FROM 'data/pull_requests.csv' (HEADER);

-- Create useful indexes
CREATE INDEX IF NOT EXISTS idx_commits_repo_name ON commits(repo_name);
CREATE INDEX IF NOT EXISTS idx_commits_author_name ON commits(author_name);
CREATE INDEX IF NOT EXISTS idx_commits_date ON commits(date);

CREATE INDEX IF NOT EXISTS idx_pull_requests_repo_name ON pull_requests(repo_name);
CREATE INDEX IF NOT EXISTS idx_pull_requests_author ON pull_requests(author);
CREATE INDEX IF NOT EXISTS idx_pull_requests_merged_by ON pull_requests(merged_by);
CREATE INDEX IF NOT EXISTS idx_pull_requests_state ON pull_requests(state);
CREATE INDEX IF NOT EXISTS idx_pull_requests_created_at ON pull_requests(created_at);

-- Show summary statistics
SELECT 'Database Creation Complete!' as status;
SELECT 'Repositories loaded: ' || COUNT(*) as summary FROM repos;
SELECT 'Commits loaded: ' || COUNT(*) as summary FROM commits;
SELECT 'Pull requests loaded: ' || COUNT(*) as summary FROM pull_requests;

-- Show sample data
SELECT 'Sample repositories:' as info;
SELECT name, language, stargazers_count, forks_count FROM repos ORDER BY stargazers_count DESC LIMIT 5;

SELECT 'Sample commits:' as info;
SELECT repo_name, author_name, LEFT(message, 50) || '...' as message_preview, date FROM commits ORDER BY date DESC LIMIT 5;

SELECT 'Sample pull requests:' as info;  
SELECT repo_name, number, author, state, merged_by FROM pull_requests ORDER BY created_at DESC LIMIT 5; 