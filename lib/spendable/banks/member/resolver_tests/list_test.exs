defmodule Spendable.Banks.Member.Resolver.ListTest do
  use Spendable.Web.ConnCase, async: true
  import Spendable.Factory

  test "list members", %{conn: conn} do
    {user, token} = Spendable.TestUtils.create_user()
    member = insert(:bank_member, user: user)
    account = insert(:bank_account, user: user, bank_member: member)

    query = """
      query {
        bankMembers {
        id
        name
        status
        bankAccounts {
          id
          name
          sync
          balance
        }
      }
    }
    """

    response =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert %{
             "data" => %{
               "bankMembers" => [
                 %{
                   "bankAccounts" => [
                     %{"balance" => "100.00", "id" => "#{account.id}", "name" => "Checking", "sync" => true}
                   ],
                   "id" => "#{member.id}",
                   "name" => "Plaid",
                   "status" => "Connected"
                 }
               ]
             }
           } == response
  end
end
