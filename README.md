# ELIXIR QUANTUM ODBC DB ALERT APP WITH CONTROL VERSION

Includes two test db containers and a git browser http server

## How to RUN it:

IMPORTANT, ALL DOCKER COMMANDS ARE PLACED UNDER ./bin, so makes sense to use them from the app root folder

```
export PATH=$PATH:./bin
```

To run the whole thing use the following command

```
compose.sh -d
```

(takes a lot because the images are not prebuilt in docker hub, and it does a big deal of stuff, like unix odbc instalation)

## Rebuilding only the elixir container 
```
docker.sh
```


## Diagnose, are all your containers running?
```
CONTAINER ID        IMAGE                   COMMAND                  CREATED              STATUS              PORTS                               NAMES
528e090d1658        mysql:latest            "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:3306->3306/tcp, 33060/tcp   test_mysql
99c06be88e84        postgres:latest         "docker-entrypoint.s…"   About a minute ago   Up About a minute   5432/tcp, 0.0.0.0:5433->5433/tcp    test_postgres
4bca27f7c956        davibe/gitlist-docker   "/bin/sh -c 'service…"   3 minutes ago        Up About a minute   0.0.0.0:8080->80/tcp                alerts_gitlist
47370478a43e        alerts_web              "/app/bin/boot.sh ./…"   54 minutes ago       Up About a minute   0.0.0.0:4000->4000/tcp              alerts_phoenix
e18f6a021555        postgres                "docker-entrypoint.s…"   2 weeks ago          Up About a minute   0.0.0.0:5432->5432/tcp              alerts_db
```

The app will be accessible under http://localhost:4000
The git browser will show up under http://localhost:8080

## The data sources have to be configured in your elixir app,
for instance, in your alerts/config/config.exs

```
config :alerts,
  data_sources: ...
```

## Elixir console
```
exec.sh "iex --erl '-kernel shell_history enabled' -S mix"
```

## Running the tests
```
exec.sh "MIX_ENV=test mix test --trace"
```

## Some TODOs
- Support oracle
- Better tests
- Perform a git mv upon alert renaming or context change
- Provide data delivery
- Git list to include git log -p file?
- Better sample databases (books.csv)
- Quantum cron seems to freeze in my laptop when I hibernate
- Seed with sample alerts
- Rename test db containers alerts_test_mysql...
- Provide a docker compose file without db test containers

## More commands

### Test mysql container
```
docker-compose rm -fsv test_mysql && docker-compose up --build test_mysql
exec.sh -uroot test_mysql 'export MYSQL_PWD=mysql; mysql -P 3306  test'
exec.sh -uroot test_mysql 'export MYSQL_PWD=mysql; echo "select * from book" | mysql -P 3306  test'
enter.sh -uroot test_mysql
```

### Test database postgres
```
docker-compose rm -fsv test_postgres && docker-compose up --build test_postgres
exec.sh test_postgres 'echo "select * from book" | psql -U postgres test'
exec.sh test_postgres 'psql -U postgres test'
enter.sh -uroot test_postgres
```

### Enter in alerts_gitserver, build specific containers, etc
```
enter.sh -uroot alerts_gitlist
docker-compose up --build gitlist
```