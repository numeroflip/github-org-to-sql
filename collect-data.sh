#!/bin/bash

# GitHub Organization to CSV Data Collector
# Usage: ./collect-data.sh ORGANIZATION_NAME

set -e

ORG_NAME="$1"

if [ -z "$ORG_NAME" ]; then
    echo "Usage: $0 ORGANIZATION_NAME"
    echo "Example: $0 duckdb"
    exit 1
fi

echo "🚀 Collecting data for organization: $ORG_NAME"

# Check if gh CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first: https://cli.github.com/"
    exit 1
fi

# Test authentication
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI is not authenticated. Please run: gh auth login"
    exit 1
fi

# Create data directory
mkdir -p data
cd data

echo "📂 Collecting repository information..."

# Get repositories and save to CSV
{
    echo "name,full_name,description,language,stargazers_count,forks_count,created_at,updated_at,url"
    gh repo list "${ORG_NAME}" \
        --limit 1000 \
        --json name,nameWithOwner,description,primaryLanguage,stargazerCount,forkCount,createdAt,updatedAt,url \
        --template '{{range .}}{{.name | printf "%q"}},{{.nameWithOwner | printf "%q"}},{{.description | printf "%q"}},{{if .primaryLanguage}}{{.primaryLanguage.name | printf "%q"}}{{else}}""{{end}},{{.stargazerCount}},{{.forkCount}},{{.createdAt | printf "%q"}},{{.updatedAt | printf "%q"}},{{.url | printf "%q"}}{{"\n"}}{{end}}'
} > repos.csv

# Count repositories
REPO_COUNT=$(tail -n +2 repos.csv | wc -l)
echo "✅ Found $REPO_COUNT repositories"

# Initialize CSV files with headers
echo "repo_name,sha,author_name,author_email,committer_name,committer_email,message,date" > commits.csv
echo "repo_name,number,title,state,author,created_at,merged_at,merged_by,assignees,requested_reviewers,comments,additions,deletions" > pull_requests.csv

# Process each repository
CURRENT_REPO=0
while IFS=, read -r name full_name description language stars forks created_at updated_at url; do
    # Skip header row
    if [ "$name" = "name" ]; then
        continue
    fi
    
    CURRENT_REPO=$((CURRENT_REPO + 1))
    
    # Remove quotes from name
    REPO_NAME=$(echo "$name" | tr -d '"')
    REPO_FULL_NAME=$(echo "$full_name" | tr -d '"')
    
    echo "📦 Processing repository $CURRENT_REPO/$REPO_COUNT: $REPO_NAME"
    
    # Get commits for this repository
    if gh api "repos/$REPO_FULL_NAME/commits" --jq '. | length' > /dev/null 2>&1; then
        gh api "repos/$REPO_FULL_NAME/commits" \
            --paginate \
            --template '{{range .}}{{printf "%q" "'$REPO_NAME'"}},{{printf "%q" .sha}},{{printf "%q" .commit.author.name}},{{printf "%q" .commit.author.email}},{{printf "%q" .commit.committer.name}},{{printf "%q" .commit.committer.email}},{{printf "%q" .commit.message}},{{printf "%q" .commit.author.date}}{{"\n"}}{{end}}' \
            >> commits.csv 2>/dev/null
    else
        echo "  ⚠️  Repository $REPO_NAME is empty or could not fetch commits"
    fi
    
    # Extract owner and repo name
    REPO_OWNER=$(echo "$REPO_FULL_NAME" | cut -d'/' -f1)
    REPO_NAME_ONLY=$(echo "$REPO_FULL_NAME" | cut -d'/' -f2)
    
    # GraphQL query using gh's template system
    gh api graphql \
        --field owner="$REPO_OWNER" \
        --field name="$REPO_NAME_ONLY" \
        --field query="$(cat ../pull_requests.graphql)" \
        --template '{{range .data.repository.pullRequests.nodes}}{{printf "%q" "'$REPO_NAME'"}},{{.number}},{{printf "%q" .title}},{{printf "%q" .state}},{{if .author}}{{printf "%q" .author.login}}{{else}}{{printf "%q" ""}}{{end}},{{printf "%q" .createdAt}},{{if .mergedAt}}{{printf "%q" .mergedAt}}{{else}}{{printf "%q" ""}}{{end}},{{if .mergedBy}}{{printf "%q" .mergedBy.login}}{{else}}{{printf "%q" ""}}{{end}},{{if .assignees.nodes}}"{{range $i, $a := .assignees.nodes}}{{if $i}},{{end}}{{$a.login}}{{end}}"{{else}}{{printf "%q" ""}}{{end}},{{if .reviewRequests.nodes}}"{{range $i, $r := .reviewRequests.nodes}}{{if $i}},{{end}}{{if $r.requestedReviewer.login}}{{$r.requestedReviewer.login}}{{end}}{{end}}"{{else}}{{printf "%q" ""}}{{end}},{{.comments.totalCount}},{{.additions}},{{.deletions}}{{"\n"}}{{end}}' \
        >> pull_requests.csv 2>/dev/null || echo "  ⚠️  GraphQL request failed for $REPO_NAME"
    
    # Rate limiting - pause briefly between repositories
    sleep 0.5
    
done < repos.csv

echo ""
echo "✅ Data collection complete!"
echo ""

# Show summary statistics
echo "📊 Data Summary:"
echo "Repositories: $(tail -n +2 repos.csv | wc -l)"
echo "Commits: $(tail -n +2 commits.csv | wc -l)"
echo "Pull Requests: $(tail -n +2 pull_requests.csv | wc -l)"

echo ""
echo "📁 Generated files:"
echo "  - repos.csv"
echo "  - commits.csv" 
echo "  - pull_requests.csv"
echo ""
