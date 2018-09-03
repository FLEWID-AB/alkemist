defmodule AlkemistTest.Router do
  use Phoenix.Router
  use Alkemist.Router

  scope "/", AlkemistTest do
    alkemist_resources("/posts", PostController)
  end
end
