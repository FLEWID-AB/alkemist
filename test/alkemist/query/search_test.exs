defmodule Alkemist.Query.SearchTest do
  use ExUnit.Case, async: true
  alias Alkemist.Query.Search

  describe "prepare_params" do
    #test "it adds midnight when gteq and field is naive_datetime" do
    #  params = %{"q" => %{"inserted_at_gteq" => "2018-09-05"}}
    #  assert %{"q" => %{"inserted_at_gteq" => val}} = Search.prepare_params(params, Alkemist.Post)
    #  assert val == "2018-09-05 00:00:00"
    #end

    #test "it adds one second before midnight when lteq and field is naive_datetime" do
    #  params = %{"q" => %{"inserted_at_lteq" => "2018-09-05"}}
    #  assert %{"q" => %{"inserted_at_lteq" => val}} = Search.prepare_params(params, Alkemist.Post)
    #  assert val == "2018-09-05 23:59:59"
    #end
  end
end
