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
echo "repo_name,sha,author_name,author_email,author_login,committer_name,committer_email,committer_login,message,date" > commits.csv
echo "repo_name,number,title,state,author,created_at,merged_at,merged_by,assignees,requested_reviewers,comments,additions,deletions,comment_authors" > pull_requests.csv
echo "repo_name,pr_number,comment_id,author,body,created_at,updated_at" > pr_comments.csv
echo "repo_name,pr_number,reviewer,state,submitted_at" > reviews.csv

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
    
    # Extract owner and repo name
    REPO_OWNER=$(echo "$REPO_FULL_NAME" | cut -d'/' -f1)
    REPO_NAME_ONLY=$(echo "$REPO_FULL_NAME" | cut -d'/' -f2)
    

    
    # Get commits for this repository
    IS_EMPTY=$(gh api graphql \
      --field owner="$REPO_OWNER" \
      --field name="$REPO_NAME_ONLY" \
      --field query='query($owner:String!, $name:String!) { repository(owner:$owner, name:$name) { isEmpty } }' \
      --jq '.data.repository.isEmpty' 2>/dev/null || echo "false")

    if [ "$IS_EMPTY" = "true" ]; then
        echo "  ⚠️  Repository $REPO_NAME has no commits (empty)"
    else
        if ! gh api "repos/$REPO_FULL_NAME/commits?per_page=100" \
            --paginate \
            --template '{{range .}}{{printf "%q" "'$REPO_NAME'"}},{{printf "%q" .sha}},{{printf "%q" .commit.author.name}},{{printf "%q" .commit.author.email}},{{if .author}}{{printf "%q" .author.login}}{{else}}{{printf "%q" ""}}{{end}},{{printf "%q" .commit.committer.name}},{{printf "%q" .commit.committer.email}},{{if .committer}}{{printf "%q" .committer.login}}{{else}}{{printf "%q" ""}}{{end}},{{printf "%q" .commit.message}},{{printf "%q" .commit.author.date}}{{"\n"}}{{end}}' >> commits.csv 2>/dev/null; then
            echo "  ⚠️  Could not fetch commits for $REPO_NAME (permissions/rate limit?)"
        fi
    fi


   # GraphQL query for pull requests using a single request, then map to two CSVs
TMP_JSON="$(mktemp)"
if gh api graphql \
  --paginate \
  --field owner="$REPO_OWNER" \
  --field name="$REPO_NAME_ONLY" \
  --field query="$(cat ../pull_requests.graphql)" > "$TMP_JSON" 2>/dev/null; then
  # Pull Requests
  jq -r --arg repo "$REPO_NAME" -s '[.[] | .data.repository.pullRequests.nodes[]] | .[] | [ $repo, .number, .title, .state, (.author.login // ""), .createdAt, (.mergedAt // ""), ((.mergedBy.login) // ""), (((.assignees.nodes // []) | map(.login)) | join(",")), (((.reviewRequests.nodes // []) | map(.requestedReviewer.login) | map(select(. != null))) | join(",")), (.comments.totalCount // 0), (.additions // 0), (.deletions // 0), (((.comments.nodes // []) | map(.author.login) | map(select(. != null))) | join(";")) ] | @csv' "$TMP_JSON" >> pull_requests.csv
  # Reviews
  jq -r --arg repo "$REPO_NAME" -s '[.[] | .data.repository.pullRequests.nodes[]] | .[] as $pr | ($pr.reviews.nodes // [])[] | select(.author != null) | [ $repo, ($pr.number), .author.login, .state, .submittedAt ] | @csv' "$TMP_JSON" >> reviews.csv
else
  echo "  ⚠️  GraphQL request failed for $REPO_NAME"
fi
rm -f "$TMP_JSON"

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
echo "Reviews: $(tail -n +2 reviews.csv | wc -l)"

echo ""
echo "📁 Generated files:"
echo "  - repos.csv"
echo "  - commits.csv" 
echo "  - pull_requests.csv"
echo "  - reviews.csv"
echo ""
