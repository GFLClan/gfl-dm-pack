defmodule GfldmWebWeb.PageController do
  use GfldmWebWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
