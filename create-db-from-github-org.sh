#!/bin/bash
set -e

if [ -f .env ]; then
    source ./.env
fi

# Use command line argument first, then fall back to environment variable
ORG_NAME_FROM_ENV="${GITHUB_ORG:-${ORG_NAME_ENV}}"
ORG_NAME="${1:-$ORG_NAME_FROM_ENV}"

if [ -z "$ORG_NAME" ]; then
    echo "Usage: $0 ORGANIZATION_NAME"
    echo "Or set GITHUB_ORG in .env file"
    exit 1
fi

./collect-data.sh "$ORG_NAME"

if [ $? -ne 0 ]; then
    echo "Error: Data collection failed. Exiting."
    exit 1
fi

echo "Creating a database..."

[ -f "$ORG_NAME.db" ] && rm "$ORG_NAME.db"
duckdb $ORG_NAME.db < create_tables.sql

echo "Database created successfully: $ORG_NAME.db"

echo "Cleaning up..."

rm -rf data

echo "Done!. Open the db by running: duckdb $ORG_NAME.db"