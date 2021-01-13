defmodule GfldmWeb.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gfldm_players" do
    field :steamid, :string
    has_one :tag, GfldmWeb.Tags.PlayerTag

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:steamid])
    |> validate_required([:steamid])
    |> unique_constraint(:steamid)
  end
end
