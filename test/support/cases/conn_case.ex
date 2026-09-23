defmodule Alkemist.ConnCase do
  @moduledoc """
  Test case for request tests through `AlkemistTest.Router`. Combines
  `Phoenix.ConnTest` with the SQL sandbox.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Alkemist.Repo
      import Plug.Conn
      import Phoenix.ConnTest
      import Alkemist.ConnCase

      import Alkemist.DataCase,
        only: [
          insert_category!: 0,
          insert_category!: 1,
          insert_post!: 0,
          insert_post!: 1,
          insert_tag!: 0,
          insert_tag!: 1
        ]

      @endpoint AlkemistTest.Endpoint
    end
  end

  setup tags do
    Alkemist.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
