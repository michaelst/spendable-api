defmodule Mix.Tasks.Import.Categories do
  use Mix.Task

  @shortdoc "Import categories from Plaid."
  def run(_) do
    Mix.Task.run("app.start")

    Budget.Banks.Category.Utils.import_categories()
  end
end