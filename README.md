# Create DB out of a Github Org 

A few shell scripts that helps creating an sql database out of a github organization. 

Also includes a few predefined queries, and a script that runs the predefined queries.

## Prerequisites 
- [docker](https://www.docker.com/get-started/)

## .env
Optional:
You can set the `GITHUB_ORG` variable in an .env, then you can call `./create-db-from-github-org.sh` without arguments

```
GITHUB_ORG=<the org you want to gather the repositories of>
GITHUB_TOKEN=<your access token>
```
## Usage 
### a.) `pnpm` based

Start data collecting, creating csv files
```
pnpm collect-data 
```
Create a .db file out of the gathered csv files
```
pnpm db:initialize
```

Open the ui, to inspect the database
```
pnpm db:ui
```

Open the db (terminal based)
```
pnpm db:open
```

### b.) `docker compose` based

Open the UI (`http://localhost:4213/`), and update the db at the same time
```
docker compose up 
```

Open the UI only
```
docker compose up ui
```

Update the database only
```
docker compose up collector db-create
```




