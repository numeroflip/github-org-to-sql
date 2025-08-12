# Create DB out of a Github Org 

A few shell scripts that helps creating an sql database out of a github organization. 

Also includes a few predefined queries, and a script that runs the predefined queries.

## Prerequisites 

- [github cli](https://cli.github.com/) 
  - You need to be authenticated, and having access to the org 
- [duckdb](https://duckdb.org/docs/installation/?version=stable&environment=cli&platform=macos&download_method=direct)
- [jq](https://jqlang.org/download/)


## .env
Optional:
You can set the `GITHUB_ORG` variable in an .env, then you can call `./create-db-from-github-org.sh` without arguments

## 1. Create the database 
```
./create-db-from-github-org.sh <your-org>
```

<your-org> is optional


## 2. Query your data

### a.) Run the predefined queries
```
./run-queries.sh
```

### b.) Pass a query directly to duckdb

```
duckdb <your-org>.db -c "SELECT merged_by, COUNT(*) FROM pull_requests WHERE merged_by IS NOT NULL GROUP BY merged_by ORDER BY COUNT(*) DESC;" 
```


## Modify, or add queries

The predefined queries are stored in `/queries`
They have a structure of `/queries/[scope]/[query-name].sql`

Feel free to delete, modify, or add sql queries there, they will appear automatically in `run-queries.sh`