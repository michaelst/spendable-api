defmodule Spendable.Jobs.Banks.SyncMemberTest do
  use Spendable.DataCase, async: true
  import Tesla.Mock
  import Ecto.Query

  alias Spendable.{
    Repo,
    Jobs.Banks.SyncMemberTest.TestData,
    Banks.Member,
    Banks.Category,
    Banks.Transaction,
    Banks.Account,
    Banks.Providers.Plaid.Adapter
  }

  alias Spendable.Banks.Category.TestData, as: CategoryTestData

  setup do
    mock(fn
      %{method: :post, url: "https://sandbox.plaid.com/categories/get"} ->
        json(CategoryTestData.categories())

      %{method: :post, url: "https://sandbox.plaid.com/item/get"} ->
        json(TestData.item())

      %{
        method: :post,
        url: "https://sandbox.plaid.com/institutions/get_by_id",
        body:
          "{\"institution_id\":\"ins_109511\",\"options\":{\"include_optional_metadata\":true},\"public_key\":\"test\"}"
      } ->
        json(TestData.institution())

      %{method: :post, url: "https://sandbox.plaid.com/accounts/get"} ->
        json(TestData.accounts())

      %{
        method: :post,
        url: "https://sandbox.plaid.com/transactions/get"
      } ->
        json(TestData.account_transactions("zyBMmKBpeZcDVZgqEx3ACKveJjvwmBHomPbyP"))
    end)

    :ok
  end

  test "sync member" do
    {user, _} = Spendable.TestUtils.create_user()
    token = "access-sandbox-97a66034-85df-4510-8eb5-020cc7997134"
    {:ok, %{body: details}} = Plaid.member(token)

    Spendable.Banks.Category.Utils.import_categories()

    member =
      %Member{plaid_token: token}
      |> Member.changeset(Adapter.format(details, user.id, :member))
      |> Repo.insert!()

    Spendable.Jobs.Banks.SyncMember.perform(member.id)

    assert [
             %{
               id: account_id,
               external_id: "zyBMmKBpeZcDVZgqEx3ACKveJjvwmBHomPbyP",
               balance: balance,
               available_balance: available_balance,
               name: "Plaid Gold Standard 0% Interest Checking",
               number: "0000",
               sub_type: "checking",
               sync: false,
               type: "depository"
             } = account,
             %{sync: false},
             %{sync: false},
             %{sync: false},
             %{sync: false},
             %{sync: false},
             %{sync: false},
             %{sync: false}
           ] = from(Account, where: [bank_member_id: ^member.id]) |> Repo.all()

    assert "110" |> Decimal.new() |> Decimal.equal?(balance)
    assert "100" |> Decimal.new() |> Decimal.equal?(available_balance)

    assert 0 == from(Transaction, where: [user_id: ^user.id]) |> Repo.aggregate(:count, :id)

    account
    |> Account.changeset(%{sync: true})
    |> Repo.update!()

    Spendable.Jobs.Banks.SyncMember.perform(member.id)

    assert 7 == from(Transaction, where: [user_id: ^user.id]) |> Repo.aggregate(:count, :id)

    category_id = Repo.get_by!(Category, external_id: "22006001").id

    assert [
             %{
               amount: amount,
               name: "Uber 072515 SF**POOL**",
               date: ~D[2019-10-01],
               category_id: ^category_id,
               bank_transaction: %{
                 external_id: "gjwAb9wKgytqA9dKR4Xmc3rwN8WN5nigoEkrB",
                 category_id: ^category_id,
                 bank_account_id: ^account_id,
                 name: "Uber 072515 SF**POOL**",
                 pending: false
               }
             },
             %{},
             %{},
             %{},
             %{},
             %{},
             %{}
           ] = from(Spendable.Transaction, where: [user_id: ^user.id], preload: [:bank_transaction]) |> Repo.all()

    assert "6.33" |> Decimal.new() |> Decimal.equal?(amount)
  end
end
