ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Spendable.Repo, :manual)
Absinthe.Test.prime(Spendable.Web.Schema)
{:ok, _} = Application.ensure_all_started(:ex_machina)
