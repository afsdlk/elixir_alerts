# Just once

# Create new app without docker file
docker build -t alerts:latest -<<EOF
FROM elixir:1.10
EOF

# Just once: Create your new phoenix project
docker container run  --rm -v /Users/juanse/experiments/Alerts:/app -w /app -it alerts:latest bash -c " mix local.hex --force; mix local.rebar --force; mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phx_new.ez; mix phx.new alerts"

exec.sh "iex --erl '-kernel shell_history enabled' -S mix"
exec.sh "MIX_ENV=test mix test --trace"
exec.sh "mix deps.compile file_system"
exec.sh "mix format mix.exs 'lib/**/*.{ex,exs}' 'test/**/*.{ex,exs}'"

:odbc.start()
odbcstring = 'Driver={PostgreSQL Unicode};Server=alerts_db;Database=alerts_dev;Trusted_Connection=False;UID=postgres;PWD=postgres;'
{:ok,db_pid} = :odbc.connect(odbcstring,[auto_commit: :off])
lala = :odbc.param_query(db_pid,'SELECT * FROM alert;',[])
lala
:odbc.commit(db_pid, :rollback)
:odbc.disconnect(db_pid)
:odbc.stop()

:odbc.start()
odbcstring = 'Driver=MySQL ANSI;Server=mysql;Trusted_Connection=False;Database=lala;UID=root;PWD=mysql;'
{:ok,db_pid} = :odbc.connect(odbcstring,[auto_commit: :off])
{:selected, columns, rows} = :odbc.param_query(db_pid,'select * from tutorials_tbl;',[])
rows
:odbc.commit(db_pid, :rollback)
:odbc.disconnect(db_pid)
:odbc.stop()

# test database in mysql
docker-compose up test_mysql
docker exec -it test_mysql bash -c 'export MYSQL_PWD=mysql; echo "select * from book" |  mysql -P 3306  test'
docker exec -it test_mysql bash -c 'export MYSQL_PWD=mysql;  mysql -P 3306  test'
docker exec -it test_mysql bash
