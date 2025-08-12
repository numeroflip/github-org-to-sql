# Create DB out of a Github Org 

## Prerequisites 

- [github cli](https://cli.github.com/) 
  - You need to be authenticated, and having access to the org 
- [duckdb](https://duckdb.org/docs/installation/?version=stable&environment=cli&platform=macos&download_method=direct)


## .env
Optional:
You can set the `GITHUB_ORG` variable in an .env, then you can call `./create-db-from-github-org.sh` without arguments

## Creating a database 
```
./create-db-from-github-org.sh <your-org>
```

<your-org> is optional


## Query your data

```
duckdb <your-org>.db -c "SELECT merged_by, COUNT(*) FROM pull_requests WHERE merged_by IS NOT NULL GROUP BY merged_by ORDER BY COUNT(*) DESC;" 
```

See `example_queries.sql`
