defmodule GfldmWeb.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gfldm_players" do
    field :steamid, :string
    belongs_to :server, GfldmWeb.Servers.Server
    has_one :tag, GfldmWeb.Tags.PlayerTag
    has_many :tag_overrides, GfldmWeb.Tags.TagOverride

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:steamid, :server_id])
    |> validate_required([:steamid, :server_id])
    |> unique_constraint(:steamid)
  end
end
