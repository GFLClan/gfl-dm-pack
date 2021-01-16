defmodule GfldmWeb.Servers.Server do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gfldm_servers" do
    field :api_key, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(server, attrs) do
    server
    |> cast(attrs, [:name, :api_key])
    |> validate_required([:name, :api_key])
  end
end
