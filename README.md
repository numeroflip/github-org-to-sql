# Create DB out of a Github Org 

A few shell scripts that helps creating an sql database out of a github organization. 

Also includes a few predefined queries, and a script that runs the predefined queries.

## Prerequisites 
- [duckdb](https://duckdb.org/docs/installation/?version=stable&environment=cli&platform=macos&download_method=direct)



## .env
Optional:
You can set the `GITHUB_ORG` variable in an .env, then you can call `./create-db-from-github-org.sh` without arguments

```
GITHUB_ORG=<the org you want to gather the repositories of>
GITHUB_TOKEN=<your access token>
```

## 1. Create the csv files 
```
pnpm collect-data
```

## 2. Create the database

```
duckdb db/create_tables.sql > github_org.db 
```


## 2. Query your data

### Pass a query directly to duckdb

```
duckdb github_org.db -c "SELECT merged_by, COUNT(*) FROM pull_requests WHERE merged_by IS NOT NULL GROUP BY merged_by ORDER BY COUNT(*) DESC;" 
```

### Open the duckdb ui

```
duckdb github_org.db -ui" 
```

### Acess it through a 3rd party

A lot of database explorer software supports duckdb, where the db file can be imported.