defmodule GfldmWeb.Tags.TagOverride do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tag_overrides" do
    belongs_to :player, GfldmWeb.Players.Player
    belongs_to :tag, GfldmWeb.Tags.Tag

    timestamps()
  end

  @doc false
  def changeset(tag_override, attrs) do
    tag_override
    |> cast(attrs, [:tag_id, :player_id])
    |> validate_required([:tag_id, :player_id])
  end
end
