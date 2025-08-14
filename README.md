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

Pull the github data, then open the ui
```
docker compose --profile sync up 
```

Open the UI
```
docker compose --profile ui up
```



## Troubleshoot

### The UI container exits, and is not available
We use host networking on the ui container, so on mac you might need to enable host networking: https://docs.docker.com/engine/network/drivers/host/#docker-desktop




