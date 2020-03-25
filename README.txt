# Just once

# Create new app without docker file
docker build -t alerts:latest -<<EOF
FROM elixir:1.6.1
EOF

# Just once: Create your new phoenix project
docker container run  --rm -v /Users/juanse/experiments/Alerts:/app -w /app -it alerts:latest bash -c " mix local.hex --force; mix local.rebar --force; mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phx_new.ez; mix phx.new alerts"

exec.sh "iex --erl '-kernel shell_history enabled' -S mix"
exec.sh "mix test"
exec.sh "mix deps.compile file_system"
exec.sh "mix format mix.exs 'lib/**/*.{ex,exs}' 'test/**/*.{ex,exs}'"

:odbc.start()
odbcstring = 'Driver={PostgreSQL Unicode};Server=alerts_db;Database=alerts_dev;Trusted_Connection=False;UID=postgres;PWD=postgres;'
{:ok,db_pid} = :odbc.connect(odbcstring,[auto_commit: :off])
lala = :odbc.param_query(db_pid,'DELETE FROM alert;',[])
lala
:odbc.commit(db_pid, :rollback)
:odbc.disconnect(db_pid)
:odbc.stop()
