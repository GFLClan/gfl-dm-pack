defmodule GfldmWeb.Repo do
  use Ecto.Repo,
    otp_app: :gfldm_web,
    adapter: Ecto.Adapters.Postgres
end
