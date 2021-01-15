defmodule GfldmWeb.Tags.PlayerTag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gfldm_player_tags" do
    field :tag_color, :string
    field :name_color, :string
    field :chat_color, :string
    field :custom_tag, :string
    belongs_to :player, GfldmWeb.Players.Player
    belongs_to :tag, GfldmWeb.Tags.Tag
    belongs_to :tag_pattern, GfldmWeb.Tags.TagPattern
    belongs_to :name_pattern, GfldmWeb.Tags.TagPattern
    belongs_to :chat_pattern, GfldmWeb.Tags.TagPattern

    timestamps()
  end

  @doc false
  def changeset(player_tag, attrs) do
    player_tag
    |> cast(attrs, [:tag_color, :name_color, :chat_color, :player_id, :tag_id, :tag_pattern_id, :name_pattern_id, :chat_pattern_id, :custom_tag])
    |> validate_required([:player_id])
  end
end
