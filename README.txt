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
lala = :odbc.param_query(db_pid,'SELECT * FROM alert;',[])
lala
:odbc.commit(db_pid, :rollback)
:odbc.disconnect(db_pid)
:odbc.stop()

:odbc.start()
odbcstring = 'Driver=MySQL UNICODE;Server=mysql;Trusted_Connection=False;Database=mysql;UID=root;PWD=mysql;'
{:ok,db_pid} = :odbc.connect(odbcstring,[auto_commit: :off])
{:selected, columns, rows} = :odbc.param_query(db_pid,'select * from db;',[])
rows
:odbc.commit(db_pid, :rollback)
:odbc.disconnect(db_pid)
:odbc.stop()

rows |> Enum.map(fn tuple -> tuple |> Tuple.to_list() |> Enum.map(&IO.inspect/1) end)

# mysql docker container
docker run --rm --network=alerts_default --name mysql -e MYSQL_ROOT_PASSWORD=mysql -p 3306:3306 mysql:latest
docker exec -it mysql bash -c "mysql -pmysql mysql"

CREATE USER 'root'@'%' IDENTIFIED BY 'mysql';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;


query = "select id,nsame from Alert;"

{_, transaction_results} = (fn ->
  with {:error, results} = Alerts.Repo |> Ecto.Adapters.SQL.query(query, [], timeout: 1_000) do
   Alerts.Repo.rollback({:error, results})
  end
end) |> Alerts.Repo.transaction

{:ok,
  %Postgrex.Result{
    columns: ["id", "name"],
    command: :select,
    connection_id: 80,
    messages: [],
    num_rows: 3,
    rows: [[38, "akak"], [1, "test1"], [5, "test2dd"]]
  }}

query = 'select \'kk\' as KK;'


:odbc.start()
odbcstring = 'Driver={PostgreSQL Unicode};Server=alerts_db;Database=alerts_dev;Trusted_Connection=False;UID=postgres;PWD=postgres;'
{:ok,db_pid} = :odbc.connect(odbcstring,[auto_commit: :off])
{:selected, columns, rows} = :odbc.sql_query(db_pid,query)
:odbc.commit(db_pid, :rollback)
:odbc.disconnect(db_pid)
:odbc.stop()


{:ok, %{
  columns: columns |> Enum.map(&(:erlang.list_to_binary(&1))),
  command: :select,
  connection_id: db_pid,
  messages: [],
  num_rows: Enum.count(rows),
  rows: rows |> Enum.map(&(&1 |> Tuple.to_list() |> Enum.map(fn item -> item |> :erlang.list_to_binary end))
  rows |> Enum.map(&(&1 |> Tuple.to_list() |> Enum.map(fn item do :erlang.list_to_binary(item) end)))
}}



{:ok,
 %{
   columns: columns |> Enum.map(&:erlang.list_to_binary(&1)),
   command: :select,
   connection_id: 1234,
   messages: [],
   num_rows: Enum.count(rows),
   rows:
     rows
     |> Enum.map(
       &(&1
         |> Tuple.to_list()
         |> Enum.map(fn
           item
           when is_list(item) ->
             :erlang.list_to_binary(item)

           other ->
             other
         end))
     )
 }}
